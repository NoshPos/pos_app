import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_app/core/error/failure.dart';

/// Profile model representing user profile data
class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? storeId;
  final List<String> accessibleStoreIds;
  final bool is2FAEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.storeId,
    this.accessibleStoreIds = const [],
    this.is2FAEnabled = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      storeId: json['store_id'] as String?,
      accessibleStoreIds:
          (json['accessible_store_ids'] as List?)?.cast<String>() ?? [],
      is2FAEnabled: json['is_2fa_enabled'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'store_id': storeId,
      'accessible_store_ids': accessibleStoreIds,
      'is_2fa_enabled': is2FAEnabled,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? storeId,
    List<String>? accessibleStoreIds,
    bool? is2FAEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      accessibleStoreIds: accessibleStoreIds ?? this.accessibleStoreIds,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is owner or admin
  bool get isOwnerOrAdmin =>
      role?.toLowerCase() == 'owner' || role?.toLowerCase() == 'admin';

  /// Check if user has accessible store IDs
  bool get hasAccessibleStoreIds => accessibleStoreIds.isNotEmpty;

  /// Check if user has a primary store ID
  bool get hasStoreId => storeId != null && storeId!.isNotEmpty;
}

/// Repository for profile operations
abstract class ProfileRepository {
  /// Get current user's profile
  Future<Either<Failure, ProfileModel>> getProfile();

  /// Update profile data
  Future<Either<Failure, void>> updateProfile({
    String? fullName,
    String? phone,
    bool? is2FAEnabled,
  });
}

/// Supabase implementation of ProfileRepository
class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client;

  ProfileRepositoryImpl(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Either<Failure, ProfileModel>> getProfile() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return left(const AuthFailure(message: 'User not authenticated'));
      }

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // Profile doesn't exist, create one
        final newProfile = {
          'id': userId,
          'email': _client.auth.currentUser?.email,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _client.from('profiles').insert(newProfile);

        return right(
          ProfileModel(
            id: userId,
            email: _client.auth.currentUser?.email,
            createdAt: DateTime.now(),
          ),
        );
      }

      return right(ProfileModel.fromJson(response));
    } on PostgrestException catch (e) {
      return left(
        DatabaseFailure(
          message: 'Failed to get profile: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return left(Failure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? fullName,
    String? phone,
    bool? is2FAEnabled,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return left(const AuthFailure(message: 'User not authenticated'));
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (is2FAEnabled != null) updates['is_2fa_enabled'] = is2FAEnabled;

      await _client.from('profiles').update(updates).eq('id', userId);

      return right(null);
    } on PostgrestException catch (e) {
      return left(
        DatabaseFailure(
          message: 'Failed to update profile: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return left(Failure(message: 'Unexpected error: $e'));
    }
  }
}
