import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';

/// Audio player service specifically for Registration and Auth events
class AuthAudioPlayer {
  static AudioPlayer? _player;

  static Future<void> playSuccess() async {
    try {
      _player ??= AudioPlayer();
      await _player?.stop();
      await _player?.setAsset('assets/register/Success.mp3');
      await _player?.play();
    } catch (e) {
      Loggers.error('AuthAudioPlayer playSuccess error: $e');
    }
  }

  static Future<void> playFail() async {
    try {
      _player ??= AudioPlayer();
      await _player?.stop();
      await _player?.setAsset('assets/register/Fail.mp3');
      await _player?.play();
    } catch (e) {
      Loggers.error('AuthAudioPlayer playFail error: $e');
    }
  }
}

/// Full-screen page to display Success / Failure with Lottie JSON animations and sound
class AuthStatusScreen extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final String? buttonText;

  const AuthStatusScreen({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    this.onConfirm,
    this.buttonText,
  });

  static Future<void> show({
    required bool isSuccess,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? buttonText,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(milliseconds: 2200),
  }) async {
    // Play sound immediately
    if (isSuccess) {
      AuthAudioPlayer.playSuccess();
    } else {
      AuthAudioPlayer.playFail();
    }

    if (autoDismiss) {
      bool handled = false;
      void doConfirm() {
        if (!handled) {
          handled = true;
          onConfirm?.call();
        }
      }

      Get.to(
        () => AuthStatusScreen(
          isSuccess: isSuccess,
          title: title,
          message: message,
          buttonText: buttonText,
          onConfirm: () {
            if (Get.isRegistered<AuthStatusScreen>() || Get.currentRoute != '/') {
              Get.back();
            }
            doConfirm();
          },
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
      );

      await Future.delayed(autoDismissDuration);
      // Auto-navigate away
      if (Get.currentRoute != '/') {
        Get.back();
      }
      doConfirm();
    } else {
      await Get.to(
        () => AuthStatusScreen(
          isSuccess: isSuccess,
          title: title,
          message: message,
          buttonText: buttonText,
          onConfirm: () {
            Get.back();
            onConfirm?.call();
          },
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lottieAsset =
        isSuccess ? 'assets/register/Success.json' : 'assets/register/Fail.json';
    final Color accentColor = isSuccess ? AuthColors.gioGreen : AuthColors.error;
    final Color bgColor = isSuccess
        ? const Color(0xFF071A0F)  // deep dark green
        : const Color(0xFF1A0707); // deep dark red

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glow circle behind Lottie
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    lottieAsset,
                    fit: BoxFit.contain,
                    repeat: false,
                    errorBuilder: (_, __, ___) => Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: accentColor,
                      size: 100,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 14),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Action button — full width
                AuthPrimaryButton(
                  text: buttonText ?? (isSuccess ? 'Continue' : 'Try Again'),
                  gradientColors: isSuccess
                      ? AuthColors.greenGradient
                      : [AuthColors.error, const Color(0xFFD63031)],
                  height: 54,
                  onTap: () {
                    Get.back();
                    onConfirm?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep old name as alias so existing controller code still compiles
typedef AuthStatusDialog = AuthStatusScreen;
