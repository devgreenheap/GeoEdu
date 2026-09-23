import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_back_button.dart';
import 'package:geoedu/common/widget/privacy_policy_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/screen/auth_screen/auth_screen_controller.dart';
import 'package:geoedu/screen/auth_screen/otp_verification_screen.dart';
import 'package:geoedu/screen/auth_screen/registration_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';
import 'package:geoedu/utilities/asset_res.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _openOtpScreen(AuthScreenController controller) {
    Get.to(() => OtpVerificationScreen(
          phoneDisplay: '${controller.loginCountryCode} ${controller.loginMobileController.text}',
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
    final controller = Get.put(AuthScreenController());
    return Scaffold(
      backgroundColor: AuthColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: GetBuilder<AuthScreenController>(
            builder: (c) {
              final canContinue = c.isLoginOtpSent && !c.isLoginOtpVerified;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomBackButton(color: AuthColors.textPrimary, height: 22, width: 22),
                  const SizedBox(height: 12),
                  Center(
                    child: Image.asset(AssetRes.appLogo, width: 96, height: 96),
                  ),
                  const SizedBox(height: 24),
                  const Text('Welcome Back! 👋',
                      style: TextStyle(color: AuthColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Login to continue your learning journey',
                      style: TextStyle(color: AuthColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 28),
                  const AuthFieldLabel('Mobile Number'),
                  AuthMobileField(
                    countryCode: c.loginCountryCode,
                    countryCodes: c.countryCodes,
                    onCountryCodeChanged: c.isLoginOtpVerified ? null : c.selectLoginCountryCode,
                    controller: controller.loginMobileController,
                    enabled: !c.isLoginOtpVerified,
                  ),
                  if (c.isLoginOtpVerified)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AuthColors.success, size: 18),
                          SizedBox(width: 6),
                          Text('Mobile verified', style: TextStyle(color: AuthColors.success, fontSize: 13)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 26),
                  AuthPrimaryButton(
                    text: c.isLoginOtpVerified
                        ? LKey.logIn.tr
                        : (canContinue ? 'Enter OTP' : 'Send OTP'),
                    isLoading: c.isSendingLoginOtp,
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
                  const SizedBox(height: 26),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        controller.fullNameController.clear();
                        controller.emailController.clear();
                        Get.to(() => const RegistrationScreen());
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AuthColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                    color: AuthColors.primaryOrange, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const PrivacyPolicyText(
                    boldTextColor: AuthColors.textPrimary,
                    regularTextColor: AuthColors.textSecondary,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
