import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_back_button.dart';
import 'package:geoedu/common/widget/privacy_policy_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/screen/auth_screen/auth_screen_controller.dart';
import 'package:geoedu/screen/auth_screen/login_screen.dart';
import 'package:geoedu/screen/auth_screen/otp_verification_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';

import '../../utilities/asset_res.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  void _openOtpScreen(AuthScreenController controller) {
    Get.to(() => OtpVerificationScreen(
          phoneDisplay: '${controller.selectedCountryCode} ${controller.mobileController.text}',
          otpController: controller.otpController,
          onVerify: controller.verifyOtp,
          onResend: controller.sendOtp,
          onVerified: () {
            if (controller.isOtpVerified) {
              Get.back();
            }
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AuthScreenController>()
        ? Get.find<AuthScreenController>()
        : Get.put(AuthScreenController());
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          dragStartBehavior: DragStartBehavior.down,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: GetBuilder<AuthScreenController>(
            init: controller,
            builder: (c) {
              final canContinueOtp = c.isOtpSent && !c.isOtpVerified;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    const CustomBackButton(color: AuthColors.textPrimary, height: 22, width: 22)
                  else
                    const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  Center(child: Image.asset(AssetRes.appLogo, width: 80, height: 80)),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('Create Account',
                        style: TextStyle(color: AuthColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Join us and start your learning journey',
                        style: TextStyle(color: AuthColors.textSecondary, fontSize: 13)),
                  ),
                  const SizedBox(height: 26),

                  const AuthFieldLabel('Full Name', mandatory: true),
                  AuthTextField(
                    controller: controller.fullNameController,
                    hintText: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                    hasError: c.getError('fullName') != null,
                  ),
                  AuthErrorText(c.getError('fullName')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Email Address', mandatory: true),
                  AuthTextField(
                    controller: controller.emailController,
                    hintText: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    hasError: c.getError('email') != null,
                  ),
                  AuthErrorText(c.getError('email')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Refer ID (Optional)'),
                  AuthTextField(
                    controller: controller.referIdController,
                    hintText: 'Enter refer ID',
                    icon: Icons.card_giftcard_outlined,
                  ),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Mobile Number', mandatory: true),
                  AuthMobileField(
                    countryCode: c.selectedCountryCode,
                    countryCodes: c.countryCodes,
                    onCountryCodeChanged: c.isOtpVerified ? null : controller.selectCountryCode,
                    controller: controller.mobileController,
                    enabled: !c.isOtpVerified,
                    hasError: c.getError('mobile') != null,
                  ),
                  AuthErrorText(c.getError('mobile')),
                  const SizedBox(height: 10),
                  if (c.isOtpVerified)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AuthColors.success, size: 18),
                          SizedBox(width: 6),
                          Text('Mobile verified', style: TextStyle(color: AuthColors.success, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: c.isSendingOtp
                            ? null
                            : () async {
                                if (canContinueOtp) {
                                  _openOtpScreen(controller);
                                  return;
                                }
                                await controller.sendOtp();
                                if (controller.isOtpSent) {
                                  _openOtpScreen(controller);
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AuthColors.primaryOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: c.isSendingOtp
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AuthColors.primaryOrange))
                            : Text(canContinueOtp ? 'Enter OTP' : 'Verify Mobile Number',
                                style: const TextStyle(
                                    color: AuthColors.primaryOrange, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Address Line 1', mandatory: true),
                  AuthTextField(
                    controller: controller.address1Controller,
                    hintText: 'Enter address',
                    icon: Icons.location_on_outlined,
                    hasError: c.getError('address1') != null,
                  ),
                  AuthErrorText(c.getError('address1')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Address Line 2 (Optional)'),
                  AuthTextField(
                    controller: controller.address2Controller,
                    hintText: 'Apartment, suite, etc.',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Country', mandatory: true),
                  AuthDropdownField(
                    hint: c.countryList.isEmpty ? 'Loading countries...' : 'Select Country',
                    value: c.selectedCountry,
                    items: c.countryList,
                    onChanged: c.countryList.isEmpty ? null : controller.selectCountry,
                    hasError: c.getError('country') != null,
                    icon: Icons.public_outlined,
                  ),
                  AuthErrorText(c.getError('country')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('State', mandatory: true),
                  AuthDropdownField(
                    hint: c.selectedCountry == null
                        ? 'Select a country first'
                        : (c.isLoadingStates ? 'Loading states...' : 'Select State'),
                    value: c.selectedState,
                    items: c.stateList,
                    onChanged: c.selectedCountry == null ? null : controller.selectState,
                    hasError: c.getError('state') != null,
                    icon: Icons.map_outlined,
                  ),
                  AuthErrorText(c.getError('state')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('City', mandatory: true),
                  AuthDropdownField(
                    hint: c.selectedState == null
                        ? 'Select a state first'
                        : (c.isLoadingCities ? 'Loading cities...' : 'Select City'),
                    value: c.selectedCity,
                    items: c.cityList,
                    onChanged: c.selectedState == null ? null : controller.selectCity,
                    hasError: c.getError('city') != null,
                    icon: Icons.location_city_outlined,
                  ),
                  AuthErrorText(c.getError('city')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Zipcode', mandatory: true),
                  AuthTextField(
                    controller: controller.zipcodeController,
                    hintText: 'Enter zipcode',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    hasError: c.getError('zipcode') != null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  AuthErrorText(c.getError('zipcode')),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Category'),
                  AuthDropdownField(
                    hint: c.isLoadingCategories ? 'Loading categories...' : 'Select Category',
                    value: c.selectedCategory,
                    items: c.categories,
                    onChanged: c.categories.isEmpty ? null : controller.selectCategory,
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Subject'),
                  AuthDropdownField(
                    hint: c.selectedCategory == null ? 'Select a category first' : 'Select Subject',
                    value: c.selectedSubject,
                    items: c.subjects,
                    onChanged: c.subjects.isEmpty ? null : controller.selectSubject,
                    icon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Topic'),
                  AuthDropdownField(
                    hint: c.selectedSubject == null ? 'Select a subject first' : 'Select Topic',
                    value: c.selectedTopic,
                    items: c.topics,
                    onChanged: c.topics.isEmpty ? null : controller.selectTopic,
                    icon: Icons.topic_outlined,
                  ),
                  const SizedBox(height: 14),

                  const AuthFieldLabel('Language'),
                  AuthDropdownField(
                    hint: c.isLoadingLanguages ? 'Loading languages...' : 'Select Language',
                    value: c.selectedLanguage,
                    items: c.languages,
                    onChanged: c.languages.isEmpty ? null : controller.selectLanguage,
                    icon: Icons.language_outlined,
                  ),
                  const SizedBox(height: 16),
                  const PrivacyPolicyText(
                    boldTextColor: AuthColors.textPrimary,
                    regularTextColor: AuthColors.textSecondary,
                  ),
                  const SizedBox(height: 22),
                  AuthPrimaryButton(
                    text: LKey.createAccount.tr,
                    onTap: controller.onCreateAccount,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Get.back();
                        } else {
                          Get.off(() => const LoginScreen());
                        }
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: AuthColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                    color: AuthColors.primaryOrange, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
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
