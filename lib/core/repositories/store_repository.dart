import 'dart:developer' as developer;
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_app/core/error/failure.dart';

/// Store model representing a business outlet
class StoreModel {
  final String id;
  final String name;
  final String? slug;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? gstin;
  final String? fssaiNumber;
  final String currency;
  final double taxRate;
  final bool isActive;
  final DateTime createdAt;

  const StoreModel({
    required this.id,
    required this.name,
    this.slug,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.gstin,
    this.fssaiNumber,
    this.currency = 'INR',
    this.taxRate = 18.0,
    this.isActive = true,
    required this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logo_url'] as String?,
      gstin: json['gstin'] as String?,
      fssaiNumber: json['fssai_number'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'gstin': gstin,
      'fssai_number': fssaiNumber,
      'currency': currency,
      'tax_rate': taxRate,
      'is_active': isActive,
    };
  }
}

/// Repository for store/outlet operations
abstract class StoreRepository {
  Future<Either<Failure, List<StoreModel>>> getStores();
  Future<Either<Failure, StoreModel>> getStoreById(String id);
  Future<Either<Failure, List<StoreModel>>> getAccessibleStores();
  Stream<List<StoreModel>> watchStores();
}

/// Supabase implementation of StoreRepository
class StoreRepositoryImpl implements StoreRepository {
  final SupabaseClient _client;

  StoreRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<StoreModel>>> getStores() async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .eq('is_active', true)
          .order('name');

      final stores = (response as List)
          .map((e) => StoreModel.fromJson(e))
          .toList();
      return right(stores);
    } on PostgrestException catch (e) {
      return left(DatabaseFailure(message: e.message, code: e.code));
    } catch (e) {
      return left(Failure(message: 'Failed to fetch stores: $e'));
    }
  }

  @override
  Future<Either<Failure, StoreModel>> getStoreById(String id) async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .eq('id', id)
          .single();

      return right(StoreModel.fromJson(response));
    } on PostgrestException catch (e) {
      return left(DatabaseFailure(message: e.message, code: e.code));
    } catch (e) {
      return left(Failure(message: 'Failed to fetch store: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StoreModel>>> getAccessibleStores() async {
    try {
      // Get current user's profile with accessible stores and role
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        developer.log('StoreRepo: User not authenticated', name: 'StoreRepo');
        return left(const AuthFailure(message: 'User not authenticated'));
      }

      developer.log(
        'StoreRepo: Fetching profile for user $userId',
        name: 'StoreRepo',
      );

      final profileResponse = await _client
          .from('profiles')
          .select('store_id, accessible_store_ids, role')
          .eq('id', userId)
          .single();

      final storeId = profileResponse['store_id'] as String?;
      final accessibleIds =
          (profileResponse['accessible_store_ids'] as List?)?.cast<String>() ??
          [];
      final role = profileResponse['role'] as String?;

      developer.log(
        'StoreRepo: Profile - role=$role, storeId=$storeId, accessibleIds=$accessibleIds',
        name: 'StoreRepo',
      );

      List<StoreModel> stores = [];

      // Priority 1: Check if accessible_store_ids exists and is not empty
      if (accessibleIds.isNotEmpty) {
        developer.log(
          'StoreRepo: Priority 1 - Fetching by accessible_store_ids',
          name: 'StoreRepo',
        );
        final storesResponse = await _client
            .from('stores')
            .select()
            .inFilter('id', accessibleIds)
            .eq('is_active', true)
            .order('name');

        stores = (storesResponse as List)
            .map((e) => StoreModel.fromJson(e))
            .toList();
        developer.log(
          'StoreRepo: Priority 1 found ${stores.length} stores',
          name: 'StoreRepo',
        );
      }

      // Priority 2: If no stores found, check if store_id exists
      if (stores.isEmpty && storeId != null && storeId.isNotEmpty) {
        developer.log(
          'StoreRepo: Priority 2 - Fetching by store_id',
          name: 'StoreRepo',
        );
        final storeResponse = await _client
            .from('stores')
            .select()
            .eq('id', storeId)
            .eq('is_active', true)
            .maybeSingle();

        if (storeResponse != null) {
          stores = [StoreModel.fromJson(storeResponse)];
          developer.log(
            'StoreRepo: Priority 2 found 1 store',
            name: 'StoreRepo',
          );
        }
      }

      // Priority 3: If still no stores and user is owner/admin, fetch all stores (limit 10)
      if (stores.isEmpty &&
          (role?.toLowerCase() == 'owner' || role?.toLowerCase() == 'admin')) {
        developer.log(
          'StoreRepo: Priority 3 - User is owner/admin, fetching all stores',
          name: 'StoreRepo',
        );
        final storesResponse = await _client
            .from('stores')
            .select()
            .eq('is_active', true)
            .order('name')
            .limit(10);

        stores = (storesResponse as List)
            .map((e) => StoreModel.fromJson(e))
            .toList();
        developer.log(
          'StoreRepo: Priority 3 found ${stores.length} stores',
          name: 'StoreRepo',
        );
      }

      developer.log(
        'StoreRepo: Returning ${stores.length} stores: ${stores.map((s) => s.name).toList()}',
        name: 'StoreRepo',
      );

      return right(stores);
    } on PostgrestException catch (e) {
      return left(DatabaseFailure(message: e.message, code: e.code));
    } catch (e) {
      return left(Failure(message: 'Failed to fetch accessible stores: $e'));
    }
  }

  @override
  Stream<List<StoreModel>> watchStores() {
    return _client
        .from('stores')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('name')
        .map((data) => data.map((e) => StoreModel.fromJson(e)).toList());
  }
}
