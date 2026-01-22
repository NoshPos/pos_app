import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_app/core/providers/supabase_provider.dart';
import 'package:pos_app/features/auth/repository/auth_repository.dart';

part 'auth_viewmodel.g.dart';

/// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool otpSent;
  final String? pendingEmail;
  final String? pendingPhone;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.otpSent = false,
    this.pendingEmail,
    this.pendingPhone,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? otpSent,
    String? pendingEmail,
    String? pendingPhone,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingPhone: pendingPhone ?? this.pendingPhone,
    );
  }
}

/// Auth repository provider
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
}

/// Auth ViewModel
@riverpod
class AuthViewModel extends _$AuthViewModel {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
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

  /// Send OTP to phone number
  Future<bool> sendPhoneOtp({required String phone}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.sendPhoneOtp(phone: phone);

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

  /// Verify phone OTP and sign in
  Future<bool> verifyPhoneOtp({required String otp}) async {
    final phone = state.pendingPhone;
    if (phone == null) {
      state = state.copyWith(error: 'No pending phone verification.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.verifyPhoneOtp(phone: phone, otp: otp);

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
