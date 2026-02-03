// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'234c48f4d83559674c59291994bcdcdec26d0d35';

/// Auth repository provider (Supabase - for email, Google auth)
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$firebasePhoneAuthRepositoryHash() =>
    r'a4ffda77f89092a0d571f09bb8458b9ab4216ff1';

/// Firebase Phone Auth repository provider (for phone OTP - free)
///
/// Copied from [firebasePhoneAuthRepository].
@ProviderFor(firebasePhoneAuthRepository)
final firebasePhoneAuthRepositoryProvider =
    AutoDisposeProvider<FirebasePhoneAuthRepository>.internal(
      firebasePhoneAuthRepository,
      name: r'firebasePhoneAuthRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firebasePhoneAuthRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebasePhoneAuthRepositoryRef =
    AutoDisposeProviderRef<FirebasePhoneAuthRepository>;
String _$authViewModelHash() => r'6c0ab0292bf3f8cb49aa1b2597c7bfd7ee796453';

/// Auth ViewModel
///
/// Copied from [AuthViewModel].
@ProviderFor(AuthViewModel)
final authViewModelProvider =
    AutoDisposeNotifierProvider<AuthViewModel, AuthState>.internal(
      AuthViewModel.new,
      name: r'authViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthViewModel = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
