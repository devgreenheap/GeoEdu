import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';

/// Premium OTP verification screen with in-page verification feedback.
/// When the correct OTP is entered, this page visually celebrates with
/// a green glowing checkmark, "Verified Successfully!" celebration,
/// and automatically transitions directly to Step 2 without bouncing back to Step 1.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneDisplay;
  final TextEditingController otpController;
  final Future<bool> Function() onVerify;
  final Future<void> Function() onResend;
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

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const int _resendSeconds = 30;
  final FocusNode _hiddenFocusNode = FocusNode();
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _verifying = false;
  bool _resending = false;
  bool _isSuccessVerified = false;
  int _fieldRevision = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  void _clearOtpFields({bool refocus = true}) {
    widget.otpController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    if (mounted) {
      setState(() {
        _fieldRevision++;
      });
    }
    if (refocus && !_isSuccessVerified) {
      _hiddenFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isSuccessVerified) {
          _hiddenFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fresh start: ensure controller is empty and reset to offset 0
    _clearOtpFields(refocus: false);
    _startTimer();
    widget.otpController.addListener(_onOtpChanged);
    _hiddenFocusNode.addListener(_onOtpChanged);

    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hiddenFocusNode.requestFocus();
    });
  }

  void _onOtpChanged() {
    if (!mounted) return;
    setState(() {});
    // Auto-verify when 6 digits are reached
    if (widget.otpController.text.trim().length == 6 &&
        !_verifying &&
        !_isSuccessVerified) {
      _verify();
    }
  }

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
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying || _isSuccessVerified) return;

    if (widget.otpController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete 6-digit OTP'),
          backgroundColor: AuthColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _verifying = true);

    final bool verified = await widget.onVerify();
    if (!mounted) return;

    if (verified) {
      HapticFeedback.mediumImpact();
      setState(() {
        _verifying = false;
        _isSuccessVerified = true;
      });

      // Show the glowing verified status on THIS PAGE for 850ms so user clearly sees it
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;

      // Update parent step to Step 2 so underneath screen is immediately ready
      widget.onVerified();

      // Close this OTP screen smoothly
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() => _verifying = false);
      // Requirement: "If an incorrect OTP is submitted, show the existing wrong-OTP error normally,
      // but do not permanently lock or retain the entered value."
      // Clear OTP input fields immediately so user can enter fresh OTP without being locked:
      _clearOtpFields(refocus: true);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _resending || _isSuccessVerified) return;

    // 1. Immediately clear/reset all OTP input fields, controller, focus, and error state
    _clearOtpFields(refocus: false);
    ScaffoldMessenger.of(context).clearSnackBars();

    setState(() => _resending = true);

    // 2. Call onResend to generate and send fresh OTP
    await widget.onResend();
    if (!mounted) return;

    setState(() => _resending = false);
    _startTimer();

    // 3. Ensure keyboard/focus moves correctly to the first OTP field with a completely fresh state
    _clearOtpFields(refocus: true);
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.otpController.text;
    final isComplete = otp.length == 6;

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AuthColors.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isSuccessVerified)
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AuthColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AuthColors.border
                                    .withValues(alpha: 0.7)),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AuthColors.textPrimary,
                              size: 16),
                        ),
                      )
                    else
                      const SizedBox(width: 40, height: 40),
                    if (!_isSuccessVerified)
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Text(
                          'Change Number',
                          style: TextStyle(
                              color: AuthColors.primaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AuthColors.gioGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AuthColors.gioGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'Step 1 of 3 Verified',
                          style: TextStyle(
                            color: AuthColors.gioGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 36),

                // ── Center Icon: morphs to glowing green check on verified ──
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: _isSuccessVerified
                        ? Container(
                            key: const ValueKey('verified_icon'),
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D3820), Color(0xFF1B6B38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                  color: AuthColors.gioGreen, width: 2.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AuthColors.gioGreen
                                      .withValues(alpha: 0.55),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 56),
                          )
                        : AnimatedBuilder(
                            key: const ValueKey('lock_icon'),
                            animation: _pulseAnim,
                            builder: (ctx, child) => Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF131F30),
                                    Color(0xFF1C2A3A)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                    color: AuthColors.gioGreen
                                        .withValues(alpha: 0.5),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AuthColors.gioGreen.withValues(
                                        alpha: 0.3 * _pulseAnim.value),
                                    blurRadius: 30,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                            child: const Icon(Icons.lock_outline_rounded,
                                color: AuthColors.gioGreen, size: 44),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Title ──
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _isSuccessVerified
                          ? 'Verified Successfully! 🎉'
                          : 'Verify Your Number',
                      key: ValueKey(_isSuccessVerified),
                      style: TextStyle(
                          color: _isSuccessVerified
                              ? AuthColors.gioGreen
                              : AuthColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Subtitle ──
                Center(
                  child: Column(
                    children: [
                      Text(
                        _isSuccessVerified
                            ? 'Phone number verified. Continuing to Step 2...'
                            : 'We sent a 6-digit code to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _isSuccessVerified
                                ? AuthColors.textPrimary
                                : AuthColors.textSecondary,
                            fontSize: 14),
                      ),
                      if (!_isSuccessVerified) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.phoneDisplay,
                          style: const TextStyle(
                              color: AuthColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── OTP Box row ──
                _buildOtpBoxes(otp),
                const SizedBox(height: 28),

                // ── Resend timer ──
                if (!_isSuccessVerified)
                  Center(
                    child: _secondsLeft > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: AuthColors.textSecondary,
                                  size: 15),
                              const SizedBox(width: 6),
                              Text(
                                "Resend in 00:${_secondsLeft.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                    color: AuthColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _resend,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: AuthColors.primaryOrange
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AuthColors.primaryOrange
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _resending
                                    ? 'Resending...'
                                    : '↺  Resend OTP',
                                style: const TextStyle(
                                    color: AuthColors.primaryOrange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AuthColors.gioGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AuthColors.gioGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AuthColors.gioGreen, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'OTP Match Confirmed',
                            style: TextStyle(
                              color: AuthColors.gioGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 36),

                // ── Verify Button ──
                AuthPrimaryButton(
                  text: _isSuccessVerified
                      ? '✓  Verified! Continuing...'
                      : 'Verify & Continue',
                  isLoading: _verifying,
                  gradientColors: (_isSuccessVerified || isComplete)
                      ? AuthColors.greenGradient
                      : null,
                  onTap: (isComplete && !_verifying && !_isSuccessVerified)
                      ? _verify
                      : null,
                ),
                const SizedBox(height: 24),

                // ── Trust line ──
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSuccessVerified
                            ? Icons.verified_user_rounded
                            : Icons.shield_outlined,
                        color: _isSuccessVerified
                            ? AuthColors.gioGreen
                            : AuthColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSuccessVerified
                            ? 'Verification completed securely'
                            : 'Your data is safe and end-to-end encrypted',
                        style: TextStyle(
                          color: _isSuccessVerified
                              ? AuthColors.gioGreen
                              : AuthColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBoxes(String text) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_isSuccessVerified) {
          if (widget.otpController.text.length == 6) {
            _clearOtpFields(refocus: true);
          } else {
            _hiddenFocusNode.requestFocus();
          }
        }
      },
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
              height: 58,
              child: TextField(
                key: ValueKey('otp_hidden_field_rev_$_fieldRevision'),
                controller: widget.otpController,
                focusNode: _hiddenFocusNode,
                enabled: !_isSuccessVerified,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    counterText: '', border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBoxVisual(int index, String text) {
    final char = index < text.length ? text[index] : '';
    final isFilled = char.isNotEmpty;
    final isActive =
        index == text.length && _hiddenFocusNode.hasFocus && !_isSuccessVerified;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: (isFilled || _isSuccessVerified)
            ? LinearGradient(
                colors: [
                  AuthColors.gioGreen.withValues(
                      alpha: _isSuccessVerified ? 0.25 : 0.15),
                  AuthColors.gioGreen.withValues(
                      alpha: _isSuccessVerified ? 0.1 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: (isFilled || _isSuccessVerified) ? null : AuthColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isFilled || _isSuccessVerified)
              ? AuthColors.gioGreen
              : isActive
                  ? AuthColors.primaryOrange
                  : AuthColors.border,
          width: (_isSuccessVerified || isFilled || isActive) ? 1.6 : 1.0,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AuthColors.primaryOrange.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          if (isFilled || _isSuccessVerified)
            BoxShadow(
              color: AuthColors.gioGreen.withValues(
                  alpha: _isSuccessVerified ? 0.35 : 0.2),
              blurRadius: _isSuccessVerified ? 16 : 12,
              spreadRadius: _isSuccessVerified ? 2 : 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Text(
          char,
          key: ValueKey('$char-$_isSuccessVerified'),
          style: TextStyle(
              color: (isFilled || _isSuccessVerified)
                  ? AuthColors.gioGreen
                  : AuthColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
