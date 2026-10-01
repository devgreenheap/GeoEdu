import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/privacy_policy_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/screen/auth_screen/auth_screen_controller.dart';
import 'package:geoedu/screen/auth_screen/login_screen.dart';
import 'package:geoedu/screen/auth_screen/otp_verification_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';

import '../../utilities/asset_res.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  void _openOtpScreen(BuildContext context, AuthScreenController controller) {
    Get.to(() => OtpVerificationScreen(
          phoneDisplay:
              '${controller.selectedCountryCode} ${controller.mobileController.text}',
          otpController: controller.otpController,
          onVerify: controller.verifyOtp,
          onResend: controller.sendOtp,
          onVerified: () {
            controller.goToStep(2);
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
      body: Container(
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
              return Column(
                children: [
                  _StepHeader(
                    currentStep: c.registrationStep,
                    onBack: () {
                      if (c.registrationStep > 1) {
                        controller.goToPreviousStep();
                      } else if (Navigator.canPop(context)) {
                        controller.clearRegistrationErrors();
                        controller.clearErrors();
                        controller.loginError = null;
                        Get.back();
                      } else {
                        controller.clearRegistrationErrors(notify: false);
                        controller.clearErrors(notify: false);
                        controller.loginError = null;
                        controller.resetLoginState(keepCredentials: false, notify: false);
                        Get.off(() => const LoginScreen());
                      }
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.06, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                              position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(c.registrationStep),
                        child: c.registrationStep == 1
                            ? _Step1Personal(
                                controller: controller,
                                onOpenOtp: () =>
                                    _openOtpScreen(context, controller),
                              )
                            : c.registrationStep == 2
                                ? _Step2Category(controller: controller)
                                : _Step3Address(controller: controller),
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

// ─── Step Header with Premium Progress ───────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;

  const _StepHeader({required this.currentStep, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AuthColors.surface.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
              color: AuthColors.border.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AuthColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AuthColors.border.withValues(alpha: 0.7)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AuthColors.textPrimary, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitle(currentStep),
                      style: const TextStyle(
                          color: AuthColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Step $currentStep of 3',
                      style: const TextStyle(
                          color: AuthColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Step pill indicators
              Row(
                children: List.generate(3, (i) {
                  final isActive = i + 1 == currentStep;
                  final isDone = i + 1 < currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(left: 5),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: (isActive || isDone)
                          ? LinearGradient(
                              colors: isDone
                                  ? AuthColors.greenGradient
                                  : AuthColors.orangeGradient,
                            )
                          : null,
                      color: (!isActive && !isDone)
                          ? AuthColors.border
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Segmented progress bar
          Row(
            children: List.generate(3, (i) {
              final isDone = i + 1 < currentStep;
              final isActive = i + 1 == currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuthColors.borderFaint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isDone ? 1.0 : (isActive ? 0.5 : 0.0),
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone
                            ? AuthColors.gioGreen
                            : AuthColors.primaryOrange,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 1:
        return 'Personal Info';
      case 2:
        return 'Your Preferences';
      case 3:
        return 'Address Details';
      default:
        return 'Create Account';
    }
  }
}

// ─── Step 1: Personal Info ────────────────────────────────────────────────────

class _Step1Personal extends StatelessWidget {
  final AuthScreenController controller;
  final VoidCallback onOpenOtp;

  const _Step1Personal(
      {required this.controller, required this.onOpenOtp});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthScreenController>(
      builder: (c) {
        return SingleChildScrollView(
          dragStartBehavior: DragStartBehavior.down,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero logo + title area
              Center(
                child: Column(
                  children: [
                    // Logo glow container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1F2E), Color(0xFF252C3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: AuthColors.primaryOrange
                                .withValues(alpha: 0.3),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AuthColors.primaryOrange
                                .withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(AssetRes.appLogo,
                            width: 80, height: 80, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Create Your Account',
                      style: TextStyle(
                          color: AuthColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join thousands of learners on GeoEdu',
                      style: TextStyle(
                          color: AuthColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Full Name ──
              const AuthFieldLabel('Full Name', mandatory: true),
              AuthTextField(
                controller: controller.fullNameController,
                hintText: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                hasError: c.getError('fullName') != null,
              ),
              AuthErrorText(c.getError('fullName')),
              const SizedBox(height: 16),

              // ── Phone Number ──
              const AuthFieldLabel('Mobile Number', mandatory: true),
              AuthMobileField(
                countryCode: c.selectedCountryCode,
                countryCodes: c.countryCodes,
                onCountryCodeChanged:
                    c.isOtpVerified ? null : controller.selectCountryCode,
                controller: controller.mobileController,
                onChanged: controller.onMobileChanged,
                enabled: !c.isOtpVerified,
                hasError: c.getError('mobile') != null,
              ),
              AuthErrorText(
                c.getError('mobile'),
                actionText: c.isMobileAlreadyRegistered ? 'Login' : null,
                onAction: c.isMobileAlreadyRegistered
                    ? () {
                        final mob = controller.mobileController.text.trim();
                        controller.clearRegistrationErrors(notify: false);
                        controller.clearErrors(notify: false);
                        controller.loginError = null;
                        controller.resetLoginState(keepCredentials: true, notify: false);
                        controller.loginMobileController.text = mob;
                        Get.off(() => const LoginScreen());
                      }
                    : null,
              ),

              // Phone verified badge
              if (c.isOtpVerified) ...[
                const SizedBox(height: 10),
                _VerifiedBadge(),
              ],
              const SizedBox(height: 16),

              // ── Email ──
              const AuthFieldLabel('Email Address', mandatory: true),
              AuthTextField(
                controller: controller.emailController,
                hintText: 'Enter your email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: controller.onEmailChanged,
                hasError: c.getError('email') != null,
              ),
              AuthErrorText(
                c.getError('email'),
                actionText: c.isEmailAlreadyRegistered ? 'Login' : null,
                onAction: c.isEmailAlreadyRegistered
                    ? () {
                        final em = controller.emailController.text.trim();
                        controller.clearRegistrationErrors(notify: false);
                        controller.clearErrors(notify: false);
                        controller.loginError = null;
                        controller.resetLoginState(keepCredentials: true, notify: false);
                        controller.loginEmailController.text = em;
                        Get.off(() => const LoginScreen());
                      }
                    : null,
              ),
              const SizedBox(height: 30),

              // ── Continue Button ──
              AuthPrimaryButton(
                text: c.isSendingOtp ? 'Sending OTP...' : 'Continue',
                trailingIcon: c.isSendingOtp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                onTap: () async {
                  if (controller.isMobileAlreadyRegistered) {
                    controller.fieldErrors['mobile'] =
                        'This mobile number is already registered. Please login to continue.';
                  }
                  if (controller.isEmailAlreadyRegistered) {
                    controller.fieldErrors['email'] =
                        'This email is already registered. Please login to continue.';
                  }

                  bool hasError = false;
                  if (controller.fullNameController.text.trim().isEmpty) {
                    controller.fieldErrors['fullName'] =
                        'Full name is required';
                    hasError = true;
                  }
                  if (controller.mobileController.text.trim().isEmpty) {
                    controller.fieldErrors['mobile'] =
                        'Mobile number is required';
                    hasError = true;
                  } else if (controller.isMobileAlreadyRegistered) {
                    hasError = true;
                  }
                  if (controller.emailController.text.trim().isEmpty) {
                    controller.fieldErrors['email'] = 'Email is required';
                    hasError = true;
                  } else if (!GetUtils.isEmail(
                      controller.emailController.text.trim())) {
                    controller.fieldErrors['email'] =
                        'Enter a valid email address';
                    hasError = true;
                  } else if (controller.isEmailAlreadyRegistered) {
                    hasError = true;
                  }
                  controller.update();
                  if (hasError) return;

                  if (controller.isOtpVerified) {
                    controller.goToStep(2);
                    return;
                  }

                  await controller.sendOtp();
                  if (controller.isOtpSent) {
                    // ignore: use_build_context_synchronously
                    onOpenOtp();
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── Already have account ──
              Center(
                child: GestureDetector(
                  onTap: () {
                    controller.clearRegistrationErrors(notify: false);
                    controller.clearErrors(notify: false);
                    controller.loginError = null;
                    controller.resetLoginState(keepCredentials: false, notify: false);
                    if (Navigator.canPop(context)) {
                      Get.back();
                    } else {
                      Get.off(() => const LoginScreen());
                    }
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account?  ',
                      style: TextStyle(
                          color: AuthColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                            text: 'Login',
                            style: TextStyle(
                                color: AuthColors.primaryOrange,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // ── Step benefits chips ──
              _StepBenefits(),
            ],
          ),
        );
      },
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AuthColors.greenGradient
              .map((c) => c.withValues(alpha: 0.1))
              .toList(),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AuthColors.gioGreen.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded,
              color: AuthColors.gioGreen, size: 18),
          SizedBox(width: 8),
          Text('Phone number verified ✓',
              style: TextStyle(
                  color: AuthColors.gioGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StepBenefits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const chips = [
      (Icons.lock_outline_rounded, 'Secure & Private'),
      (Icons.flash_on_rounded, 'Quick Setup'),
      (Icons.school_rounded, 'Free to Join'),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: chips.map((chip) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AuthColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AuthColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chip.$1,
                  color: AuthColors.primaryOrange, size: 14),
              const SizedBox(width: 5),
              Text(chip.$2,
                  style: const TextStyle(
                      color: AuthColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Step 2: Preferences ──────────────────────────────────────────────────────

class _Step2Category extends StatelessWidget {
  final AuthScreenController controller;

  const _Step2Category({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthScreenController>(
      builder: (c) {
        return SingleChildScrollView(
          dragStartBehavior: DragStartBehavior.down,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthSectionHeader(
                icon: Icons.school_rounded,
                title: 'Your Preferences',
                subtitle: 'Help us personalise your learning experience',
                iconGradient: [Color(0xFF1A9950), Color(0xFF2ECC71)],
              ),
              const SizedBox(height: 28),

              // Progress info card
              const _InfoCard(
                icon: Icons.info_outline_rounded,
                message:
                    'Select your language and category to see relevant content.',
              ),
              const SizedBox(height: 24),

              const AuthFieldLabel('Language', mandatory: true),
              AuthDropdownField(
                hint: c.isLoadingLanguages
                    ? 'Loading languages...'
                    : 'Select Language',
                value: c.selectedLanguage,
                items: c.languages,
                onChanged:
                    c.languages.isEmpty ? null : controller.selectLanguage,
                icon: Icons.language_outlined,
                hasError: c.getError('language') != null,
              ),
              AuthErrorText(c.getError('language')),
              const SizedBox(height: 16),

              const AuthFieldLabel('Category', mandatory: true),
              AuthDropdownField(
                hint: c.isLoadingCategories
                    ? 'Loading categories...'
                    : 'Select Category',
                value: c.selectedCategory,
                items: c.categories,
                onChanged:
                    c.categories.isEmpty ? null : controller.selectCategory,
                icon: Icons.category_outlined,
                hasError: c.getError('category') != null,
              ),
              AuthErrorText(c.getError('category')),
              const SizedBox(height: 16),

              const AuthFieldLabel('Subject'),
              AuthDropdownField(
                hint: c.selectedCategory == null
                    ? 'Select a category first'
                    : 'Select Subject',
                value: c.selectedSubject,
                items: c.subjects,
                onChanged:
                    c.subjects.isEmpty ? null : controller.selectSubject,
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 16),

              const AuthFieldLabel('Topic'),
              AuthDropdownField(
                hint: c.selectedSubject == null
                    ? 'Select a subject first'
                    : 'Select Topic',
                value: c.selectedTopic,
                items: c.topics,
                onChanged:
                    c.topics.isEmpty ? null : controller.selectTopic,
                icon: Icons.topic_outlined,
              ),
              const SizedBox(height: 30),

              AuthPrimaryButton(
                text: 'Continue',
                trailingIcon: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
                onTap: controller.onStep2Continue,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Step 3: Address ──────────────────────────────────────────────────────────

class _Step3Address extends StatefulWidget {
  final AuthScreenController controller;

  const _Step3Address({required this.controller});

  @override
  State<_Step3Address> createState() => _Step3AddressState();
}

class _Step3AddressState extends State<_Step3Address> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.isLocationAutoDetected &&
          !widget.controller.isDetectingLocation &&
          widget.controller.address1Controller.text.trim().isEmpty) {
        widget.controller.autoDetectLocation(silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GetBuilder<AuthScreenController>(
      builder: (c) {
        return SingleChildScrollView(
          dragStartBehavior: DragStartBehavior.down,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthSectionHeader(
                icon: Icons.location_on_rounded,
                title: 'Your Address',
                subtitle: 'Helps us show you localised content',
                iconGradient: [Color(0xFFE09900), Color(0xFFFFBB33)],
              ),
              const SizedBox(height: 28),

              // Auto-detect button
              _AutoDetectButton(c: c, controller: controller),
              const SizedBox(height: 24),

              const AuthFieldLabel('Address Line 1'),
              AuthTextField(
                controller: controller.address1Controller,
                hintText: 'Enter your address',
                icon: Icons.home_outlined,
                hasError: c.getError('address1') != null,
              ),
              AuthErrorText(c.getError('address1')),
              const SizedBox(height: 16),

              const AuthFieldLabel('Address Line 2 (Optional)'),
              AuthTextField(
                controller: controller.address2Controller,
                hintText: 'Apartment, floor, suite, etc.',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),

              const AuthFieldLabel('Country'),
              AuthDropdownField(
                hint: c.countryList.isEmpty
                    ? 'Loading countries...'
                    : 'Select Country',
                value: c.selectedCountry,
                items: c.countryList,
                onChanged: c.countryList.isEmpty
                    ? null
                    : controller.selectCountry,
                icon: Icons.public_outlined,
              ),
              const SizedBox(height: 16),

              const AuthFieldLabel('State'),
              AuthDropdownField(
                hint: c.selectedCountry == null
                    ? 'Select a country first'
                    : (c.isLoadingStates
                        ? 'Loading states...'
                        : 'Select State'),
                value: c.selectedState,
                items: c.stateList,
                onChanged: c.selectedCountry == null
                    ? null
                    : controller.selectState,
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 16),

              const AuthFieldLabel('City'),
              AuthDropdownField(
                hint: c.selectedState == null
                    ? 'Select a state first'
                    : (c.isLoadingCities
                        ? 'Loading cities...'
                        : 'Select City'),
                value: c.selectedCity,
                items: c.cityList,
                onChanged: c.selectedState == null
                    ? null
                    : controller.selectCity,
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 16),

              const AuthFieldLabel('Zipcode'),
              AuthTextField(
                controller: controller.zipcodeController,
                hintText: 'Enter zipcode / postal code',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 28),

              const PrivacyPolicyText(
                boldTextColor: AuthColors.textPrimary,
                regularTextColor: AuthColors.textSecondary,
              ),
              const SizedBox(height: 22),

              AuthPrimaryButton(
                text: LKey.createAccount.tr,
                onTap: controller.onCreateAccount,
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: controller.onSkipAddress,
                  child: const Text(
                    'Skip — Fill address later',
                    style: TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AutoDetectButton extends StatelessWidget {
  final AuthScreenController c;
  final AuthScreenController controller;

  const _AutoDetectButton({required this.c, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: c.isDetectingLocation ? null : controller.autoDetectLocation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AuthColors.gioGold.withValues(alpha: 0.10),
              AuthColors.primaryOrange.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AuthColors.gioGold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AuthColors.gioGold.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AuthColors.goldGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: c.isDetectingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.edit_location_alt_rounded,
                      color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.isDetectingLocation
                        ? 'Detecting your location...'
                        : 'Change Location Manually',
                    style: const TextStyle(
                        color: AuthColors.gioGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.detectedLocationLabel ??
                        'Edit fields below or tap to re-detect',
                    style: const TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AuthColors.gioGold, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Info Card ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthColors.primaryOrange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AuthColors.primaryOrange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AuthColors.primaryOrange, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AuthColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
