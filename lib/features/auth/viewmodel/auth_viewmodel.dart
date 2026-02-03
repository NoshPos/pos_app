import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_app/core/providers/supabase_provider.dart';
import 'package:pos_app/core/providers/repository_providers.dart';
import 'package:pos_app/core/repositories/profile_repository.dart';
import 'package:pos_app/features/auth/repository/auth_repository.dart';
import 'package:pos_app/features/auth/repository/firebase_phone_auth_repository.dart';

part 'auth_viewmodel.g.dart';

/// Auth state
class AuthState {
  final User? user;
  final ProfileModel? profile;
  final bool isLoading;
  final String? error;
  final bool otpSent;
  final String? pendingEmail;
  final String? pendingPhone;
  final bool isPhoneAuthenticatedViaFirebase;
  final bool isRoleValid;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
    this.otpSent = false,
    this.pendingEmail,
    this.pendingPhone,
    this.isPhoneAuthenticatedViaFirebase = false,
    this.isRoleValid = false,
  });

  AuthState copyWith({
    User? user,
    ProfileModel? profile,
    bool? isLoading,
    String? error,
    bool? otpSent,
    String? pendingEmail,
    String? pendingPhone,
    bool? isPhoneAuthenticatedViaFirebase,
    bool? isRoleValid,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      isPhoneAuthenticatedViaFirebase:
          isPhoneAuthenticatedViaFirebase ??
          this.isPhoneAuthenticatedViaFirebase,
      isRoleValid: isRoleValid ?? this.isRoleValid,
    );
  }
}

/// Auth repository provider (Supabase - for email, Google auth)
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
}

/// Firebase Phone Auth repository provider (for phone OTP - free)
@riverpod
FirebasePhoneAuthRepository firebasePhoneAuthRepository(
  FirebasePhoneAuthRepositoryRef ref,
) {
  return FirebasePhoneAuthRepository();
}

/// Auth ViewModel
@riverpod
class AuthViewModel extends _$AuthViewModel {
  late final AuthRepository _repo;
  late final FirebasePhoneAuthRepository _firebasePhoneRepo;
  late final ProfileRepository _profileRepo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    _firebasePhoneRepo = ref.read(firebasePhoneAuthRepositoryProvider);
    _profileRepo = ref.read(profileRepositoryProvider);
    final currentUser = _repo.currentUser;
    return AuthState(user: currentUser);
  }

  /// Validate that user has owner/admin role for app access
  Future<bool> validateAppRole() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _profileRepo.getProfile();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load profile: ${failure.message}',
          isRoleValid: false,
        );
        return false;
      },
      (profile) {
        if (!profile.isOwnerOrAdmin) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Access Denied: This app is only for store owners and administrators. Cashiers and other staff should use the web POS.',
            isRoleValid: false,
            profile: profile,
          );
          // Sign out the user since they don't have access
          signOut();
          return false;
        }
        state = state.copyWith(
          isLoading: false,
          isRoleValid: true,
          profile: profile,
        );
        return true;
      },
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.signInWithEmail(
      email: email,
      password: password,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(isLoading: false, user: user);
        return true;
      },
    );
  }

  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.signOut();

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = const AuthState();
        return true;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.signInWithGoogle();

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) async {
        state = state.copyWith(isLoading: false, user: user);
        // Validate role after successful Google sign-in
        final isValid = await validateAppRole();
        return isValid;
      },
    );
  }

  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.resetPassword(email: email);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  /// Send OTP to email for passwordless sign-in
  Future<bool> sendEmailOtp({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.sendEmailOtp(email: email);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          otpSent: true,
          pendingEmail: email,
          pendingPhone: null,
        );
        return true;
      },
    );
  }

  /// Verify email OTP and sign in
  Future<bool> verifyEmailOtp({required String otp}) async {
    final email = state.pendingEmail;
    if (email == null) {
      state = state.copyWith(error: 'No pending email verification.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.verifyEmailOtp(email: email, otp: otp);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) async {
        state = AuthState(user: user);
        // Validate role after successful authentication
        final isValid = await validateAppRole();
        return isValid;
      },
    );
  }

  /// Send OTP to phone number using Firebase (FREE)
  Future<bool> sendPhoneOtp({required String phone}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _firebasePhoneRepo.sendPhoneOtp(phone: phone);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          otpSent: true,
          pendingPhone: phone,
          pendingEmail: null,
        );
        return true;
      },
    );
  }

  /// Verify phone OTP using Firebase and mark as authenticated
  Future<bool> verifyPhoneOtp({required String otp}) async {
    final phone = state.pendingPhone;
    if (phone == null) {
      state = state.copyWith(error: 'No pending phone verification.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _firebasePhoneRepo.verifyPhoneOtp(otp: otp);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (firebaseUser) async {
        // Phone verified via Firebase - user is authenticated
        state = state.copyWith(
          isLoading: false,
          otpSent: false,
          pendingPhone: null,
          isPhoneAuthenticatedViaFirebase: true,
        );
        // Validate role after successful phone authentication
        final isValid = await validateAppRole();
        return isValid;
      },
    );
  }

  /// Reset OTP state (go back to input screen)
  void resetOtpState() {
    state = state.copyWith(
      otpSent: false,
      pendingEmail: null,
      pendingPhone: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
