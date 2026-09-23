import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_back_button.dart';
import 'package:geoedu/screen/auth_screen/auth_screen_controller.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';

/// Shared OTP-entry screen used by both Login and Create Account — reads
/// the same [AuthScreenController] instance already `Get.put()` by
/// [LoginScreen] (registration reuses it via `Get.find()`), so no new state
/// management is introduced; this only presents the existing OTP fields as
/// a dedicated step instead of an inline row.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneDisplay;
  final TextEditingController otpController;
  final Future<void> Function() onVerify;
  final Future<void> Function() onResend;

  /// Called after a verify attempt completes (success or failure) — the
  /// caller checks the real controller flag (e.g. `isLoginOtpVerified`) to
  /// decide whether to proceed or let the user retry on this screen.
  final VoidCallback onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneDisplay,
    required this.otpController,
    required this.onVerify,
    required this.onResend,
    required this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _resendSeconds = 30;
  final FocusNode _hiddenFocusNode = FocusNode();
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    widget.otpController.addListener(_onOtpChanged);
    _hiddenFocusNode.addListener(_onOtpChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hiddenFocusNode.requestFocus();
    });
  }

  void _onOtpChanged() => setState(() {});

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.otpController.removeListener(_onOtpChanged);
    _hiddenFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (widget.otpController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit OTP')),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _verifying = true);
    await widget.onVerify();
    if (!mounted) return;
    setState(() => _verifying = false);
    widget.onVerified();
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _resending) return;
    setState(() => _resending = true);
    widget.otpController.clear();
    await widget.onResend();
    if (!mounted) return;
    setState(() => _resending = false);
    _startTimer();
    _hiddenFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomBackButton(color: AuthColors.textPrimary, height: 22, width: 22),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text('Change Number',
                        style: TextStyle(
                            color: AuthColors.primaryOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AuthColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AuthColors.gioGreen.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: AuthColors.gioGreen, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Enter OTP',
                    style: TextStyle(color: AuthColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('We have sent a 6 digit code to',
                    style: const TextStyle(color: AuthColors.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(widget.phoneDisplay,
                    style: const TextStyle(
                        color: AuthColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 32),
              _buildOtpBoxes(),
              const SizedBox(height: 24),
              Center(
                child: _secondsLeft > 0
                    ? Text("Didn't receive OTP? Resend in 00:${_secondsLeft.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: AuthColors.textSecondary, fontSize: 13))
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                            _resending ? 'Resending...' : "Didn't receive OTP? Resend OTP",
                            style: const TextStyle(
                                color: AuthColors.primaryOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
              ),
              const SizedBox(height: 32),
              AuthPrimaryButton(
                text: 'Verify',
                isLoading: _verifying,
                onTap: _verify,
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AuthColors.success, size: 16),
                    const SizedBox(width: 6),
                    const Text('Your data is safe and secure with us',
                        style: TextStyle(color: AuthColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// One real (invisible) text field drives everything — handles manual
  /// typing, backspace, paste, and SMS autofill correctly, since none of
  /// those get artificially truncated the way per-digit boxes would. The 6
  /// boxes below it are a pure visual readout of its current text.
  Widget _buildOtpBoxes() {
    final text = widget.otpController.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _hiddenFocusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _otpBoxVisual(i, text)),
          ),
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 54,
              child: TextField(
                controller: widget.otpController,
                focusNode: _hiddenFocusNode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBoxVisual(int index, String text) {
    final char = index < text.length ? text[index] : '';
    final isActive = index == text.length && _hiddenFocusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AuthColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AuthColors.primaryOrange : AuthColors.border,
          width: isActive ? 1.6 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AuthColors.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(char,
          style: const TextStyle(
              color: AuthColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
    );
  }
}
