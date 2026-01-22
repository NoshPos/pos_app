import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fpdart/fpdart.dart';
import 'package:pos_app/features/auth/repository/auth_repository.dart';

/// Firebase Phone Auth Repository
/// Handles phone OTP authentication using Firebase (free tier)
class FirebasePhoneAuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  // Store verification ID for OTP verification
  String? _verificationId;
  int? _resendToken;

  // Completer for async verification flow
  Completer<Either<Failure, void>>? _verificationCompleter;

  FirebasePhoneAuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  /// Send OTP to phone number using Firebase
  Future<Either<Failure, void>> sendPhoneOtp({required String phone}) async {
    _verificationCompleter = Completer<Either<Failure, void>>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              // Auto-verification (Android only) - auto sign in
              // This happens when the SMS is auto-detected
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          String message = 'Phone verification failed';
          if (e.code == 'invalid-phone-number') {
            message = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please try again later';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded. Please try again later';
          } else if (e.message != null) {
            message = e.message!;
          }

          if (!_verificationCompleter!.isCompleted) {
            _verificationCompleter!.complete(left(Failure(message: message)));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;

          if (!_verificationCompleter!.isCompleted) {
            _verificationCompleter!.complete(right(null));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      return _verificationCompleter!.future;
    } catch (e) {
      return left(Failure(message: 'Failed to send OTP: $e'));
    }
  }

  /// Verify phone OTP and sign in with Firebase
  Future<Either<Failure, firebase_auth.User>> verifyPhoneOtp({
    required String otp,
  }) async {
    if (_verificationId == null) {
      return left(
        const Failure(
          message: 'No verification in progress. Please request OTP first.',
        ),
      );
    }

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        return left(const Failure(message: 'OTP verification failed.'));
      }

      return right(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'OTP verification failed';
      if (e.code == 'invalid-verification-code') {
        message = 'Invalid OTP. Please check and try again';
      } else if (e.code == 'session-expired') {
        message = 'OTP expired. Please request a new one';
      } else if (e.message != null) {
        message = e.message!;
      }
      return left(Failure(message: message));
    } catch (e) {
      return left(Failure(message: 'OTP verification failed: $e'));
    }
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _verificationId = null;
    _resendToken = null;
  }

  /// Get current Firebase user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Reset verification state
  void resetVerification() {
    _verificationId = null;
  }
}
