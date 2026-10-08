import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/privacy_policy_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/screen/auth_screen/auth_screen_controller.dart';
import 'package:geoedu/screen/auth_screen/otp_verification_screen.dart';
import 'package:geoedu/screen/auth_screen/registration_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';
import 'package:geoedu/utilities/asset_res.dart';

/// Premium dark-theme Login Screen — unified with the 3-step registration flow.
/// Features glassmorphism cards, glowing brand logo, fluid gradients, and instant OTP verification.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthScreenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AuthScreenController>()
        ? Get.find<AuthScreenController>()
        : Get.put(AuthScreenController());

    // Dismiss any carried-over snackbars immediately
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    controller.stopSnackBar();

    // Reset registration error states so Login page opens clean without previous errors
    // Use notify: false during initState to prevent setState-during-build assertion errors
    controller.clearRegistrationErrors(notify: false);
    controller.clearErrors(notify: false);
    controller.loginError = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;  
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
      controller.stopSnackBar();
      controller.clearRegistrationErrors(notify: false);
      controller.clearErrors(notify: false);
      controller.loginError = null;
      controller.update();
    });
  }

  void _openOtpScreen(AuthScreenController controller) {
    controller.loginOtpController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    controller.isLoginOtpVerified = false;
    controller.loginError = null;
    controller.update();
    Get.to(() => OtpVerificationScreen(
          phoneDisplay:
              '${controller.loginCountryCode} ${controller.loginMobileController.text}',
          otpController: controller.loginOtpController,
          onVerify: controller.verifyLoginOtp,
          onResend: controller.sendLoginOtp,
          onVerified: () {
            if (controller.isLoginOtpVerified) {
              controller.onLogin();
            }
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AuthColors.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: GetBuilder<AuthScreenController>(
            init: controller,
            builder: (c) {
              final canContinue = c.isLoginOtpSent && !c.isLoginOtpVerified;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Bar ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (Navigator.canPop(context))
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AuthColors.cardSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AuthColors.border.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AuthColors.textPrimary,
                                size: 16,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 40, height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AuthColors.primaryOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AuthColors.primaryOrange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: AuthColors.primaryOrange, size: 13),
                              SizedBox(width: 6),
                              Text(
                                'Secure Login',
                                style: TextStyle(
                                  color: AuthColors.primaryOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Brand Logo with Glow ────────────────────────────────
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AuthColors.primaryOrange
                                      .withValues(alpha: 0.22),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 88,
                            height: 88,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AuthColors.cardSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AuthColors.border.withValues(alpha: 0.8),
                                width: 1.2,
                              ),
                            ),
                            child: Image.asset(
                              AssetRes.appLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Title & Subtitle ────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back! 👋',
                            style: TextStyle(
                              color: AuthColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your mobile number to sign in with OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AuthColors.textSecondary.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Input Card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AuthColors.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AuthColors.border.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AuthFieldLabel('Mobile Number', mandatory: true),
                          AuthMobileField(
                            countryCode: c.loginCountryCode,
                            countryCodes: c.countryCodes,
                            onCountryCodeChanged: c.isLoginOtpVerified
                                ? null
                                : c.selectLoginCountryCode,
                            controller: controller.loginMobileController,
                            enabled: !c.isLoginOtpVerified,
                            hasError: c.loginError != null &&
                                !c.loginError!.toLowerCase().contains('already registered') &&
                                !c.loginError!.toLowerCase().contains('already exists'),
                            onChanged: (val) {
                              if (c.loginError != null) {
                                c.loginError = null;
                                c.update();
                              }
                            },
                          ),
                          if (c.loginError != null &&
                              !c.loginError!.toLowerCase().contains('already registered') &&
                              !c.loginError!.toLowerCase().contains('already exists'))
                            AuthErrorText(c.loginError),

                          if (c.isLoginOtpVerified) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AuthColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AuthColors.success.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: AuthColors.success, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mobile number verified successfully',
                                    style: TextStyle(
                                      color: AuthColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Primary action button
                          AuthPrimaryButton(
                            text: c.isLoginOtpVerified
                                ? LKey.logIn.tr
                                : (canContinue ? 'Enter OTP' : 'Send OTP'),
                            isLoading: c.isSendingLoginOtp,
                            trailingIcon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            onTap: () async {
                              if (c.isLoginOtpVerified) {
                                controller.onLogin();
                                return;
                              }
                              if (canContinue) {
                                _openOtpScreen(controller);
                                return;
                              }
                              await controller.sendLoginOtp();
                              if (controller.isLoginOtpSent) {
                                _openOtpScreen(controller);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Sign Up Redirect ────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          controller.fullNameController.clear();
                          controller.emailController.clear();
                          controller.mobileController.clear();
                          controller.clearRegistrationErrors();
                          controller.clearErrors();
                          controller.loginError = null;
                          controller.goToStep(1);
                          Get.to(() => const RegistrationScreen());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AuthColors.cardSurface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AuthColors.border.withValues(alpha: 0.35),
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                color: AuthColors.textSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: AuthColors.primaryOrange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Footer / Privacy ────────────────────────────────────
                    const PrivacyPolicyText(
                      boldTextColor: AuthColors.textPrimary,
                      regularTextColor: AuthColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
