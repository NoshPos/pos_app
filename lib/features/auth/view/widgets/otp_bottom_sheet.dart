import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/auth/viewmodel/auth_viewmodel.dart';

/// Shows OTP verification bottom sheet
/// Returns true if verification was successful, false otherwise
Future<bool> showOtpBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String destination,
  required bool isPhone,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (context) =>
        OtpBottomSheet(destination: destination, isPhone: isPhone),
  );
  return result ?? false;
}

class OtpBottomSheet extends ConsumerStatefulWidget {
  final String destination;
  final bool isPhone;

  const OtpBottomSheet({
    super.key,
    required this.destination,
    required this.isPhone,
  });

  @override
  ConsumerState<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends ConsumerState<OtpBottomSheet> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpValue {
    return _otpControllers.map((c) => c.text).join();
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _handleVerify() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    bool success;
    if (widget.isPhone) {
      success = await ref
          .read(authViewModelProvider.notifier)
          .verifyPhoneOtp(otp: otp);
    } else {
      success = await ref
          .read(authViewModelProvider.notifier)
          .verifyEmailOtp(otp: otp);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        _clearOtp();
      }
    }
  }

  Future<void> _handleResend() async {
    bool success;
    if (widget.isPhone) {
      success = await ref
          .read(authViewModelProvider.notifier)
          .sendPhoneOtp(phone: widget.destination);
    } else {
      success = await ref
          .read(authViewModelProvider.notifier)
          .sendEmailOtp(email: widget.destination);
    }

    if (success && mounted) {
      _clearOtp();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP resent successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _handleClose() {
    ref.read(authViewModelProvider.notifier).resetOtpState();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Listen for errors
    ref.listen(authViewModelProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: colorScheme.error,
          ),
        );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              spreadRadius: 2,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle and close button
            _buildHeader(colorScheme),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  _buildIcon(colorScheme),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Enter the 6-digit code sent to',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.destination,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // OTP Input Fields
                  _buildOtpFields(colorScheme),
                  const SizedBox(height: 32),
                  // Verify Button
                  _buildVerifyButton(colorScheme, authState),
                  const SizedBox(height: 20),
                  // Resend OTP
                  _buildResendRow(colorScheme, authState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Close button
          IconButton(
            onPressed: _handleClose,
            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.isPhone ? Icons.sms_outlined : Icons.email_outlined,
        size: 36,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildOtpFields(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              }
              // Auto-submit when all fields are filled
              if (_otpValue.length == 6) {
                _handleVerify();
              }
            },
            onTap: () {
              // Select all text on tap for easy replacement
              _otpControllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _otpControllers[index].text.length,
              );
            },
            // Handle backspace to move to previous field
            onEditingComplete: () {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(ColorScheme colorScheme, AuthState authState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: authState.isLoading ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: authState.isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : const Text(
                'Verify & Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildResendRow(ColorScheme colorScheme, AuthState authState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        GestureDetector(
          onTap: authState.isLoading ? null : _handleResend,
          child: Text(
            'Resend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: authState.isLoading
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
