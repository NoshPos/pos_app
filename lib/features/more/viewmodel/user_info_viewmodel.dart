import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_app/core/providers/repository_providers.dart';
import 'package:pos_app/core/repositories/store_repository.dart';
import 'package:pos_app/core/repositories/profile_repository.dart';
import '../model/user_info_model.dart';

part 'user_info_viewmodel.g.dart';

/// State for User Info page
class UserInfoState {
  final String? selectedStoreId;
  final List<StoreModel> stores;
  final UserInfoModel? userInfo;
  final List<UserLogEntry> logs;
  final bool isLoading;
  final String? error;

  const UserInfoState({
    this.selectedStoreId,
    this.stores = const [],
    this.userInfo,
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  UserInfoState copyWith({
    String? selectedStoreId,
    List<StoreModel>? stores,
    UserInfoModel? userInfo,
    List<UserLogEntry>? logs,
    bool? isLoading,
    String? error,
  }) {
    return UserInfoState(
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      stores: stores ?? this.stores,
      userInfo: userInfo ?? this.userInfo,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<String> get availableOutlets => [
    'All Outlets',
    ...stores.map((s) => s.name),
  ];

  String get selectedOutletName {
    if (selectedStoreId == null) return 'All Outlets';
    final store = stores.where((s) => s.id == selectedStoreId).firstOrNull;
    return store?.name ?? 'All Outlets';
  }

  /// Alias for selectedOutletName
  String get selectedOutlet => selectedOutletName;
}

/// ViewModel for User Info page using Riverpod
@riverpod
class UserInfoViewModel extends _$UserInfoViewModel {
  late StoreRepository _storeRepo;
  late ProfileRepository _profileRepo;

  @override
  UserInfoState build() {
    _storeRepo = ref.watch(storeRepositoryProvider);
    _profileRepo = ref.watch(profileRepositoryProvider);

    _loadInitialData();

    return const UserInfoState();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);

    // Load stores
    final storesResult = await _storeRepo.getAccessibleStores();
    storesResult.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (stores) => state = state.copyWith(stores: stores),
    );

    // Load profile
    final profileResult = await _profileRepo.getProfile();
    profileResult.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (profile) {
        // Create UserInfoModel from ProfileModel
        final userInfo = UserInfoModel(
          id: profile.id,
          name: profile.fullName ?? 'Unknown',
          email: profile.email ?? '',
          isEmailVerified: profile.email != null,
          mobileNumbers: profile.phone != null
              ? [
                  MobileNumber(
                    id: '1',
                    countryCode: '+91',
                    number: profile.phone!,
                    isVerified: true,
                  ),
                ]
              : [],
          is2FAEnabled: profile.is2FAEnabled,
          createdAt: profile.createdAt ?? DateTime.now(),
          createdBy: 'System',
        );
        state = state.copyWith(userInfo: userInfo);
      },
    );

    state = state.copyWith(isLoading: false);
  }

  void setSelectedOutlet(String outletName) {
    if (outletName == 'All Outlets') {
      state = state.copyWith(selectedStoreId: null);
    } else {
      final store = state.stores.where((s) => s.name == outletName).firstOrNull;
      state = state.copyWith(selectedStoreId: store?.id);
    }
  }

  bool updateUserInfo({
    required String name,
    required String email,
    required List<MobileNumber> mobileNumbers,
  }) {
    if (state.userInfo == null) return false;
    final updatedUserInfo = state.userInfo!.copyWith(
      name: name,
      email: email,
      mobileNumbers: mobileNumbers,
    );
    state = state.copyWith(userInfo: updatedUserInfo);
    return true;
  }

  void toggle2FA(bool enabled) {
    if (state.userInfo == null) return;
    final updatedUserInfo = state.userInfo!.copyWith(is2FAEnabled: enabled);
    state = state.copyWith(userInfo: updatedUserInfo);
  }

  bool changePassword(String currentPassword, String newPassword) {
    // In real implementation, call API to change password
    return true;
  }

  bool addMobileNumber(String countryCode, String number) {
    if (state.userInfo == null) return false;
    final newNumber = MobileNumber(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      countryCode: countryCode,
      number: number,
      isVerified: false,
    );

    final updatedNumbers = [...state.userInfo!.mobileNumbers, newNumber];
    final updatedUserInfo = state.userInfo!.copyWith(
      mobileNumbers: updatedNumbers,
    );
    state = state.copyWith(userInfo: updatedUserInfo);
    return true;
  }

  bool removeMobileNumber(String numberId) {
    if (state.userInfo == null) return false;
    final updatedNumbers = state.userInfo!.mobileNumbers
        .where((n) => n.id != numberId)
        .toList();
    final updatedUserInfo = state.userInfo!.copyWith(
      mobileNumbers: updatedNumbers,
    );
    state = state.copyWith(userInfo: updatedUserInfo);
    return true;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
