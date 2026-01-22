import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_app/core/providers/supabase_provider.dart';
import 'package:pos_app/features/auth/repository/auth_repository.dart';
import 'package:pos_app/features/auth/repository/firebase_phone_auth_repository.dart';

part 'auth_viewmodel.g.dart';

/// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool otpSent;
  final String? pendingEmail;
  final String? pendingPhone;
  final bool isPhoneAuthenticatedViaFirebase;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.otpSent = false,
    this.pendingEmail,
    this.pendingPhone,
    this.isPhoneAuthenticatedViaFirebase = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? otpSent,
    String? pendingEmail,
    String? pendingPhone,
    bool? isPhoneAuthenticatedViaFirebase,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      isPhoneAuthenticatedViaFirebase:
          isPhoneAuthenticatedViaFirebase ??
          this.isPhoneAuthenticatedViaFirebase,
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

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    _firebasePhoneRepo = ref.read(firebasePhoneAuthRepositoryProvider);
    final currentUser = _repo.currentUser;
    return AuthState(user: currentUser);
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
      (user) {
        state = state.copyWith(isLoading: false, user: user);
        return true;
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
      (user) {
        state = AuthState(user: user);
        return true;
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
      (firebaseUser) {
        // Phone verified via Firebase - user is authenticated
        // You can optionally sync with Supabase here if needed
        state = state.copyWith(
          isLoading: false,
          otpSent: false,
          pendingPhone: null,
          isPhoneAuthenticatedViaFirebase: true,
        );
        return true;
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
