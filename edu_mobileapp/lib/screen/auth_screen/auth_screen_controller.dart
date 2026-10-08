import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/functions/debounce_action.dart';
import 'package:geoedu/common/manager/firebase_notification_manager.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/notification_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/languages/dynamic_translations.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/city_model.dart';
import 'package:geoedu/model/general/country_state_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/user_model/user_model.dart' as user;
import 'package:geoedu/screen/auth_screen/interest_category_screen.dart';
import 'package:geoedu/screen/auth_screen/login_screen.dart';
import 'package:geoedu/screen/auth_screen/photo_verification_screen.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_status_dialog.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreenController extends BaseController {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController forgetEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController referIdController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController address1Controller = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController zipcodeController = TextEditingController();

  // ── Registration step (1 = Personal, 2 = Category, 3 = Address) ──
  int registrationStep = 1;

  void goToStep(int step) {
    registrationStep = step;
    update();
    if (step == 3) {
      if (!isLocationAutoDetected && !isDetectingLocation) {
        autoDetectLocation(silent: true);
      }
    }
  }

  void goToPreviousStep() {
    if (registrationStep > 1) {
      registrationStep--;
      update();
    }
  }

  // ── Location detection ──
  bool isDetectingLocation = false;
  bool isLocationAutoDetected = false;
  String? detectedLocationLabel;

  String _cleanGeo(String? s) => (s ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> autoDetectLocation({bool silent = false}) async {
    isDetectingLocation = true;
    update();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent) showSnackBar('Location services are disabled. Please enable them.');
        isDetectingLocation = false;
        update();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent) showSnackBar('Location permission denied.');
          isDetectingLocation = false;
          update();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!silent) {
          showSnackBar(
              'Location permission permanently denied. Enable in settings.');
        }
        isDetectingLocation = false;
        update();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // ── Fill text fields ──────────────────────────────────────────────
        final street = [place.street, place.subLocality]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
        if (street.isNotEmpty) address1Controller.text = street;
        if ((place.postalCode ?? '').isNotEmpty) {
          zipcodeController.text = place.postalCode!;
        }
        detectedLocationLabel = [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        // Ensure countries are loaded
        if (countryDataList.isEmpty) {
          await fetchCountryStateList();
        }

        // ── Auto-select Country ──────────────────────────────────────────
        if (place.country != null && place.country!.isNotEmpty) {
          final cleanCountry = _cleanGeo(place.country);
          final countryMatch = countryDataList.firstWhereOrNull((e) {
            final cleanName = _cleanGeo(e.name);
            return cleanName == cleanCountry ||
                cleanName.contains(cleanCountry) ||
                cleanCountry.contains(cleanName);
          });

          if (countryMatch != null) {
            selectedCountry = countryMatch.name;
            selectedCountryObj = countryMatch;
            selectedState = null;
            stateList = [];
            selectedCity = null;
            cityDataList = [];
            update();

            // ── Await state loading ────────────────────────────────────
            if (countryMatch.id != null) {
              await fetchStatesForCountry(countryMatch.id!);
            }

            // ── Auto-select State ──────────────────────────────────────
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty &&
                stateList.isNotEmpty) {
              final cleanAdmin = _cleanGeo(place.administrativeArea);
              final stateMatch = stateList.firstWhereOrNull((s) {
                final cleanS = _cleanGeo(s);
                return cleanS == cleanAdmin ||
                    cleanS.contains(cleanAdmin) ||
                    cleanAdmin.contains(cleanS);
              });

              if (stateMatch != null) {
                selectedState = stateMatch;
                selectedCity = null;
                cityDataList = [];
                update();

                // ── Await city loading ─────────────────────────────────
                final stateObj = selectedCountryObj?.states
                    ?.firstWhereOrNull((e) => e.name == stateMatch);
                if (stateObj?.id != null) {
                  await fetchCityListForState(stateObj!.id!);
                }

                // ── Auto-select City ───────────────────────────────────
                final candidateCities = [
                  place.locality,
                  place.subAdministrativeArea,
                  place.subLocality,
                ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();

                String? matchedCity;
                for (final candidate in candidateCities) {
                  final cleanCandidate = _cleanGeo(candidate);
                  if (cleanCandidate.isEmpty) continue;
                  matchedCity = cityList.firstWhereOrNull((c) {
                    final cleanC = _cleanGeo(c);
                    return cleanC == cleanCandidate ||
                        cleanC.contains(cleanCandidate) ||
                        cleanCandidate.contains(cleanC);
                  });
                  if (matchedCity != null) break;
                }

                if (matchedCity != null) {
                  selectedCity = matchedCity;
                  update();
                }
              }
            }
          }
        }
        isLocationAutoDetected = true;
        update();
        if (!silent) showSnackBar('Location detected successfully ✅');
      }
    } catch (e) {
      Loggers.error('Location detection failed: $e');
      if (!silent) showSnackBar('Failed to detect location. Please fill manually.');
    }
    isDetectingLocation = false;
    update();
  }

  // ── Step 1 validation & navigation ──
  void onStep1Continue() {
    fieldErrors.clear();
    if (fullNameController.text.trim().isEmpty) {
      fieldErrors['fullName'] = 'Full name is required';
    }
    if (mobileController.text.trim().isEmpty) {
      fieldErrors['mobile'] = 'Mobile number is required';
    } else if (!isOtpVerified) {
      fieldErrors['mobile'] = 'Please verify your phone number with OTP';
    }
    if (emailController.text.trim().isEmpty) {
      fieldErrors['email'] = 'Email is required';
    } else if (!GetUtils.isEmail(emailController.text.trim())) {
      fieldErrors['email'] = 'Enter a valid email address';
    }
    update();
    if (fieldErrors.isEmpty) {
      goToStep(2);
    }
  }

  // ── Step 2 validation & navigation ──
  void onStep2Continue() {
    fieldErrors.clear();
    if (selectedLanguage == null || selectedLanguage!.isEmpty) {
      fieldErrors['language'] = 'Please select a language';
    }
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      fieldErrors['category'] = 'Please select a category';
    }
    update();
    if (fieldErrors.isEmpty) {
      goToStep(3);
    }
  }

  // ── Skip address & create account directly ──
  Future<void> onSkipAddress() async {
    await _submitRegistration();
  }

  // OTP (signup)
  String selectedCountryCode = '+91';
  bool isOtpSent = false;
  bool isOtpVerified = false;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  /// 0 = Mobile, 1 = Email
  RxInt signupIdentityTab = 0.obs;

  // OTP (login)
  TextEditingController loginMobileController = TextEditingController();
  TextEditingController loginEmailController = TextEditingController();
  TextEditingController loginOtpController = TextEditingController();
  String loginCountryCode = '+91';
  bool isLoginOtpSent = false;
  bool isLoginOtpVerified = false;
  bool isSendingLoginOtp = false;
  bool isVerifyingLoginOtp = false;
  /// 0 = Mobile, 1 = Email
  RxInt loginIdentityTab = 0.obs;

  void selectSignupIdentityTab(int tab) {
    if (signupIdentityTab.value == tab) return;
    signupIdentityTab.value = tab;
    isOtpSent = false;
    isOtpVerified = false;
    otpController.clear();
    update();
  }

  void selectLoginIdentityTab(int tab) {
    if (loginIdentityTab.value == tab) return;
    loginIdentityTab.value = tab;
    isLoginOtpSent = false;
    isLoginOtpVerified = false;
    loginOtpController.clear();
    update();
  }

  final List<String> countryCodes = [
    '+91', '+1', '+44', '+61', '+971', '+65', '+60', '+81', '+86', '+49',
    '+33', '+39', '+34', '+55', '+7', '+82', '+66', '+62', '+63', '+84',
  ];

/// API-backed education data
  List<Category> categoryList = [];
  List<Language> languageList = [];

  Category? selectedCategoryObj;
  SubCategory? selectedSubCategoryObj;
  Topic? selectedTopicObj;
  Language? selectedLanguageObj;

  String? selectedCategory;
  String? selectedSubject;
  String? selectedTopic;
  String? selectedLanguage;

  // Address - API backed
  List<CountryData> countryDataList = [];
  CountryData? selectedCountryObj;
  String? selectedState;
  String? selectedCountry;
  List<String> stateList = [];
  List<String> countryList = [];
  bool isLoadingStates = false;

  // City - API backed, fetched per selected state
  List<CityData> cityDataList = [];
  String? selectedCity;
  List<String> get cityList => cityDataList.map((e) => e.name ?? '').toList();
  bool isLoadingCities = false;

  // No longer user-facing — is_adult isn't enforced by the backend
  // (nullable there too); always sent true so nothing downstream regresses.
  final bool isAdult = true;
  bool isLoadingCategories = false;
  bool isLoadingLanguages = false;

  // Inline field validation errors
  Map<String, String?> fieldErrors = {};

  String? getError(String key) => fieldErrors[key];

  bool isMobileAlreadyRegistered = false;
  bool isEmailAlreadyRegistered = false;
  Timer? _mobileCheckDebounce;
  Timer? _emailCheckDebounce;

  void onMobileChanged(String value) {
    final clean = value.trim();
    if (isMobileAlreadyRegistered || fieldErrors['mobile'] != null) {
      isMobileAlreadyRegistered = false;
      fieldErrors.remove('mobile');
      update();
    }
    _mobileCheckDebounce?.cancel();
    if (clean.length >= 10) {
      _mobileCheckDebounce = Timer(const Duration(milliseconds: 500), () {
        checkMobileAvailability(clean);
      });
    }
  }

  void onEmailChanged(String value) {
    final clean = value.trim();
    if (isEmailAlreadyRegistered || fieldErrors['email'] != null) {
      isEmailAlreadyRegistered = false;
      fieldErrors.remove('email');
      update();
    }
    _emailCheckDebounce?.cancel();
    if (clean.isNotEmpty && GetUtils.isEmail(clean)) {
      _emailCheckDebounce = Timer(const Duration(milliseconds: 500), () {
        checkEmailAvailability(clean);
      });
    }
  }

  Future<void> checkMobileAvailability(String mobile) async {
    final clean = mobile.trim();
    if (clean.isEmpty) return;
    try {
      final res = await UserService.instance.checkIdentityAvailability(mobile: clean);
      if (res.alreadyRegistered ||
          (res.message ?? '').toLowerCase().contains('already registered') ||
          (res.message ?? '').toLowerCase().contains('already exists')) {
        isMobileAlreadyRegistered = true;
        registrationError = 'This mobile number is already registered. Please login to continue.';
        fieldErrors['mobile'] = registrationError;
        update();
      } else if (isMobileAlreadyRegistered) {
        isMobileAlreadyRegistered = false;
        registrationError = null;
        if (fieldErrors['mobile'] != null &&
            fieldErrors['mobile']!.contains('already registered')) {
          fieldErrors.remove('mobile');
        }
        update();
      }
    } catch (_) {}
  }

  Future<void> checkEmailAvailability(String email) async {
    final clean = email.trim();
    if (clean.isEmpty || !GetUtils.isEmail(clean)) return;
    try {
      final res = await UserService.instance.checkIdentityAvailability(email: clean);
      if (res.alreadyRegistered ||
          (res.message ?? '').toLowerCase().contains('already registered') ||
          (res.message ?? '').toLowerCase().contains('already exists')) {
        isEmailAlreadyRegistered = true;
        registrationError = 'This email is already registered. Please login to continue.';
        fieldErrors['email'] = registrationError;
        update();
      } else if (isEmailAlreadyRegistered) {
        isEmailAlreadyRegistered = false;
        registrationError = null;
        if (fieldErrors['email'] != null &&
            fieldErrors['email']!.contains('already registered')) {
          fieldErrors.remove('email');
        }
        update();
      }
    } catch (_) {}
  }

  String? registrationError;
  String? loginError;

  void clearRegistrationErrors({bool notify = true}) {
    registrationError = null;
    isMobileAlreadyRegistered = false;
    isEmailAlreadyRegistered = false;
    _mobileCheckDebounce?.cancel();
    _emailCheckDebounce?.cancel();
    fieldErrors.remove('mobile');
    fieldErrors.remove('email');
    fieldErrors.remove('fullName');
    fieldErrors.remove('category');
    fieldErrors.remove('language');
    loginError = null;
    UserService.instance.lastLoginResponse = null;
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    stopSnackBar();
    if (notify) update();
  }

  void resetLoginState({bool keepCredentials = true, bool notify = true}) {
    registrationError = null;
    isMobileAlreadyRegistered = false;
    isEmailAlreadyRegistered = false;
    _mobileCheckDebounce?.cancel();
    _emailCheckDebounce?.cancel();
    fieldErrors.clear();
    loginError = null;
    UserService.instance.lastLoginResponse = null;

    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    stopSnackBar();

    isLoginOtpSent = false;
    isLoginOtpVerified = false;
    isSendingLoginOtp = false;
    isVerifyingLoginOtp = false;
    loginOtpController.clear();

    if (!keepCredentials) {
      loginMobileController.clear();
      loginEmailController.clear();
    }
    if (notify) update();
  }

  void clearErrors({bool notify = true}) {
    registrationError = null;
    isMobileAlreadyRegistered = false;
    isEmailAlreadyRegistered = false;
    _mobileCheckDebounce?.cancel();
    _emailCheckDebounce?.cancel();
    fieldErrors.clear();
    loginError = null;
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    stopSnackBar();
    if (notify) update();
  }

  bool validateForm() {
    fieldErrors.clear();
    // Step 3 (address) is optional — no mandatory address fields here.
    update();
    return true;
  }

  List<String> get categories =>
      categoryList.map((e) => e.name ?? '').toList();

  List<String> get subjects => selectedCategoryObj == null
      ? []
      : (selectedCategoryObj!.subCategories ?? [])
          .map((e) => e.name ?? '')
          .toList();

  List<String> get topics =>
      (selectedCategoryObj != null && selectedSubCategoryObj != null)
          ? (selectedSubCategoryObj!.topics ?? [])
              .map((e) => e.name ?? '')
              .toList()
          : [];

  List<String> get languages =>
      languageList.map((e) => e.title ?? '').toList();

  void selectCategory(String? value) {
    selectedCategory = value;
    selectedCategoryObj = categoryList.firstWhereOrNull((e) => e.name == value);
    selectedSubject = null;
    selectedSubCategoryObj = null;
    selectedTopic = null;
    selectedTopicObj = null;
    update();
  }

  void selectSubject(String? value) {
    selectedSubject = value;
    selectedSubCategoryObj = selectedCategoryObj?.subCategories
        ?.firstWhereOrNull((e) => e.name == value);
    selectedTopic = null;
    selectedTopicObj = null;
    update();
  }

  void selectTopic(String? value) {
    selectedTopic = value;
    selectedTopicObj = selectedSubCategoryObj?.topics
        ?.firstWhereOrNull((e) => e.name == value);
    update();
  }

  void selectLanguage(String? value) {
    selectedLanguage = value;
    selectedLanguageObj =
        languageList.firstWhereOrNull((e) => e.title == value);
    update();
  }

  void selectState(String? value) {
    selectedState = value;
    selectedCity = null;
    cityDataList = [];
    update();
    final stateObj = selectedCountryObj?.states?.firstWhereOrNull((e) => e.name == value);
    if (stateObj?.id != null) {
      fetchCityListForState(stateObj!.id!);
    }
  }

  Future<void> fetchCityListForState(int stateId) async {
    isLoadingCities = true;
    update();
    try {
      final result = await CommonService.instance.fetchCityList(stateId: stateId);
      cityDataList = result.data ?? [];
    } catch (e) {
      Loggers.error('Failed to fetch cities: $e');
    }
    isLoadingCities = false;
    update();
  }

  void selectCity(String? value) {
    selectedCity = value;
    update();
  }

  void selectCountry(String? value) {
    selectedCountry = value;
    selectedCountryObj = countryDataList.firstWhereOrNull((e) => e.name == value);
    // Reset dependent fields and lazily fetch this country's states —
    // the initial country list is fetched without states (fast); states
    // load on demand per selection, same pattern as city-per-state.
    selectedState = null;
    stateList = [];
    selectedCity = null;
    cityDataList = [];
    update();
    if (selectedCountryObj?.id != null) {
      fetchStatesForCountry(selectedCountryObj!.id!);
    }
  }

  Future<void> fetchStatesForCountry(int countryId) async {
    isLoadingStates = true;
    update();
    try {
      final result = await CommonService.instance.fetchCountryStateList(countryId: countryId);
      final country = (result.data ?? []).firstWhereOrNull((e) => e.id == countryId);
      stateList = country?.states?.map((e) => e.name ?? '').toList() ?? [];
      selectedCountryObj = country ?? selectedCountryObj;
    } catch (e) {
      Loggers.error('Failed to fetch states: $e');
    }
    isLoadingStates = false;
    update();
  }

  void selectCountryCode(String? value) {
    if (value != null) {
      selectedCountryCode = value;
      // Reset OTP state when country code changes
      isOtpSent = false;
      isOtpVerified = false;
      otpController.clear();
      update();
    }
  }

  Future<void> sendOtp() async {
    final bool byEmail = signupIdentityTab.value == 1;
    final String email = emailController.text.trim();
    final String mobile = mobileController.text.trim();

    if (byEmail) {
      if (email.isEmpty || !GetUtils.isEmail(email)) {
        return showSnackBar('Please enter a valid email address');
      }
    } else if (mobile.isEmpty) {
      return showSnackBar('Please enter Mobile Number');
    }

    isSendingOtp = true;
    isOtpVerified = false;
    otpController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    registrationError = null;
    fieldErrors.remove('otp');
    update();
    try {
      final result = await UserService.instance.sendSignupOtp(
        mobileCountryCode: byEmail ? null : selectedCountryCode,
        mobile: byEmail ? null : mobile,
        email: byEmail ? email : null,
      );
      if (result.status == true) {
        isOtpSent = true;
        isOtpVerified = false;
        otpController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
        registrationError = null;
        fieldErrors.remove('otp');
        showSnackBar(result.message ?? 'OTP sent successfully');
      } else {
        if (result.alreadyRegistered ||
            (result.message ?? '').toLowerCase().contains('already registered') ||
            (result.message ?? '').toLowerCase().contains('already exists')) {
          if (byEmail) {
            isEmailAlreadyRegistered = true;
            registrationError = 'This email is already registered. Please login to continue.';
            fieldErrors['email'] = registrationError;
          } else {
            isMobileAlreadyRegistered = true;
            registrationError = 'This mobile number is already registered. Please login to continue.';
            fieldErrors['mobile'] = registrationError;
          }
          update();

          AuthStatusDialog.show(
            isSuccess: false,
            title: 'Already Registered',
            message: result.message ??
                'This account is already registered. Please proceed to Login.',
            buttonText: 'Go to Login',
            onConfirm: () {
              clearRegistrationErrors();
              clearErrors();
              resetLoginState(keepCredentials: true);
              loginMobileController.text = mobile;
              loginEmailController.text = email;
              Get.off(() => const LoginScreen());
            },
          );
        } else {
          showSnackBar(result.message ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      showSnackBar('Failed to send OTP');
    }
    isSendingOtp = false;
    update();
  }

  Future<bool> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      AuthStatusDialog.show(
        isSuccess: false,
        title: 'OTP Required',
        message: 'Please enter the complete 6-digit OTP sent to your number.',
      );
      return false;
    }
    final bool byEmail = signupIdentityTab.value == 1;
    isVerifyingOtp = true;
    update();
    bool success = false;
    try {
      final result = await UserService.instance.verifySignupOtp(
        mobile: byEmail ? null : mobileController.text.trim(),
        email: byEmail ? emailController.text.trim() : null,
        otp: otp,
      );
      if (result.status == true) {
        isOtpVerified = true;
        registrationError = null;
        fieldErrors.remove('otp');
        success = true;
      } else {
        isOtpVerified = false;
        registrationError = result.message ?? 'Invalid OTP code. Please check and try again.';
        AuthStatusDialog.show(
          isSuccess: false,
          title: 'Verification Failed',
          message: registrationError!,
        );
      }
    } catch (e) {
      isOtpVerified = false;
      registrationError = 'Failed to verify OTP. Please check your network and try again.';
      AuthStatusDialog.show(
        isSuccess: false,
        title: 'Verification Failed',
        message: registrationError!,
      );
    }
    isVerifyingOtp = false;
    update();
    return success;
  }

  void selectLoginCountryCode(String? value) {
    if (value != null) {
      loginCountryCode = value;
      isLoginOtpSent = false;
      isLoginOtpVerified = false;
      loginOtpController.clear();
      update();
    }
  }

  Future<void> sendLoginOtp() async {
    final bool byEmail = loginIdentityTab.value == 1;
    final String email = loginEmailController.text.trim();
    final String mobile = loginMobileController.text.trim();

    loginError = null;
    clearRegistrationErrors();
    isLoginOtpVerified = false;
    loginOtpController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );

    if (byEmail) {
      if (email.isEmpty || !GetUtils.isEmail(email)) {
        loginError = 'Please enter a valid email address';
        update();
        return showSnackBar(loginError);
      }
    } else if (mobile.isEmpty) {
      loginError = 'Please enter Mobile Number';
      update();
      return showSnackBar(loginError);
    }

    isSendingLoginOtp = true;
    update();
    try {
      final result = await UserService.instance.sendLoginOtp(
        mobileCountryCode: byEmail ? null : loginCountryCode,
        mobile: byEmail ? null : mobile,
        email: byEmail ? email : null,
      );

      final msg = (result.message ?? '').toLowerCase();
      final isAlreadyRegistered = result.alreadyRegistered ||
          msg.contains('already registered') ||
          msg.contains('already exists');
      final isNotRegistered = result.notRegistered ||
          msg.contains('not registered') ||
          msg.contains('no account found') ||
          msg.contains('does not exist');

      if (result.status == true) {
        isLoginOtpSent = true;
        isLoginOtpVerified = false;
        loginOtpController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
        loginError = null;
        showSnackBar(result.message ?? 'OTP sent successfully');
      } else if (isNotRegistered) {
        isLoginOtpSent = false;
        loginError = byEmail
            ? 'This email is not registered. Please sign up to continue.'
            : 'This mobile number is not registered. Please sign up to continue.';
        showSnackBar(loginError);
      } else if (isAlreadyRegistered) {
        // An existing user is a valid login case!
        // The Login page must NEVER display "already registered, please login".
        // Treat as valid login attempt and allow proceeding to OTP screen:
        isLoginOtpSent = true;
        isLoginOtpVerified = false;
        loginOtpController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
        loginError = null;
        showSnackBar('OTP sent to your ${byEmail ? 'email' : 'mobile number'}');
      } else {
        loginError = result.message ?? 'Failed to send OTP';
        showSnackBar(loginError);
      }
    } catch (e) {
      loginError = 'Failed to send OTP';
      showSnackBar(loginError);
    }
    isSendingLoginOtp = false;
    update();
  }

  Future<bool> verifyLoginOtp() async {
    final otp = loginOtpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      loginError = 'Please enter the complete 6-digit OTP sent to your number.';
      update();
      AuthStatusDialog.show(
        isSuccess: false,
        title: 'OTP Required',
        message: loginError!,
      );
      return false;
    }
    final bool byEmail = loginIdentityTab.value == 1;
    isVerifyingLoginOtp = true;
    update();
    bool success = false;
    try {
      final result = await UserService.instance.verifySignupOtp(
        mobile: byEmail ? null : loginMobileController.text.trim(),
        email: byEmail ? loginEmailController.text.trim() : null,
        otp: otp,
      );
      if (result.status == true) {
        isLoginOtpVerified = true;
        loginError = null;
        success = true;
      } else {
        isLoginOtpVerified = false;
        loginError = result.message ?? 'Invalid OTP code. Please check and try again.';
        AuthStatusDialog.show(
          isSuccess: false,
          title: 'Verification Failed',
          message: loginError!,
        );
      }
    } catch (e) {
      isLoginOtpVerified = false;
      loginError = 'Failed to verify OTP. Please check your network and try again.';
      AuthStatusDialog.show(
        isSuccess: false,
        title: 'Verification Failed',
        message: loginError!,
      );
    }
    isVerifyingLoginOtp = false;
    update();
    return success;
  }

  Future<void> fetchCategorySubCategoryTopic() async {
    isLoadingCategories = true;
    update();
    try {
      final result =
          await CommonService.instance.fetchCategorySubCategoryTopic();
      categoryList = result.data ?? [];
    } catch (e) {
      Loggers.error('Failed to fetch categories: $e');
    }
    isLoadingCategories = false;
    update();
  }

  Future<void> fetchCountryStateList() async {
    try {
      // Fast path: country names only — states are loaded lazily per
      // selection (fetchStatesForCountry) instead of one huge nested payload.
      final result = await CommonService.instance.fetchCountryStateList(includeStates: false);
      countryDataList = result.data ?? [];
      countryList = countryDataList.map((e) => e.name ?? '').toList();
    } catch (e) {
      Loggers.error('Failed to fetch countries: $e');
    }
    update();
  }

  Future<void> fetchLanguages() async {
    isLoadingLanguages = true;
    update();
    try {
      final result = await CommonService.instance.fetchLanguages();
      languageList = result.data ?? [];
    } catch (e) {
      Loggers.error('Failed to fetch languages: $e');
    }
    isLoadingLanguages = false;
    update();
  }








  @override
  void onInit() {
    CommonService.instance.fetchGlobalSettings();
    FirebaseNotificationManager.instance;
    fetchCategorySubCategoryTopic();
    fetchLanguages();
    fetchCountryStateList();
    super.onInit();
  }

  Future<void> onLogin() async {
    final bool byEmail = loginIdentityTab.value == 1;
    final String mobile = loginMobileController.text.trim();
    final String email = loginEmailController.text.trim();

    if (byEmail) {
      if (email.isEmpty) {
        return showSnackBar('Please enter Email');
      }
    } else if (mobile.isEmpty) {
      return showSnackBar('Please enter Mobile Number');
    }
    if (!isLoginOtpVerified) {
      return showSnackBar(byEmail
          ? 'Please verify your email with OTP'
          : 'Please verify your mobile number with OTP');
    }

    showLoader();
    String? deviceToken = await FirebaseNotificationManager.instance.getNotificationToken();
    final user.User? data = await UserService.instance.logInWithVerifiedOtp(
      mobile: byEmail ? null : mobile,
      email: byEmail ? email : null,
      deviceToken: deviceToken,
    );
    stopLoader();

    if (data != null) {
      loginError = null;
      await AuthStatusDialog.show(
        isSuccess: true,
        title: 'Welcome Back! 👋',
        message: 'You have logged in successfully.',
        autoDismiss: true,
        autoDismissDuration: const Duration(milliseconds: 1800),
        onConfirm: () => _navigateScreen(data),
      );
    } else {
      loginError = 'No account found for this number. Please register first.';
      update();
      AuthStatusDialog.show(
        isSuccess: false,
        title: 'Login Failed',
        message: loginError!,
      );
    }
  }

  Future<void> onCreateAccount() async {
    await _submitRegistration();
  }

  Future<void> _submitRegistration() async {
    showLoader();
    user.User? data = await _registration(
        identity: emailController.text.trim(),
        loginMethod: LoginMethod.mobile,
        fullname: fullNameController.text.trim(),
        loginVia: LoginVia.loginInUser,
        categoryId: selectedCategoryObj?.id,
        subCategoryId: selectedSubCategoryObj?.id,
        topicId: selectedTopicObj?.id,
        languageId: selectedLanguageObj?.id,
        categoryName: selectedCategoryObj?.name,
        subCategoryName: selectedSubCategoryObj?.name,
        topicName: selectedTopicObj?.name,
        languageName: selectedLanguageObj?.title,
        isAdult: isAdult,
        referId: '',
        mobile: mobileController.text.trim(),
        mobileCountryCode: selectedCountryCode,
        address1: address1Controller.text.trim(),
        address2: address2Controller.text.trim(),
        city: selectedCity,
        state: selectedState,
        country: selectedCountry,
        zipcode: zipcodeController.text.trim());
    stopLoader();
    if (data != null) {
      // Show success dialog with sound & SVG then navigate
      await AuthStatusDialog.show(
        isSuccess: true,
        title: 'Profile Created Successfully! 🎉',
        message: 'Welcome to GeoEdu, ${data.fullname ?? 'Explorer'}! Your account is ready.',
        autoDismiss: true,
        autoDismissDuration: const Duration(milliseconds: 2200),
        onConfirm: () => _navigateScreenWithInterest(data),
      );
    } else {
      final lastResp = UserService.instance.lastLoginResponse;
      final errorMsg = lastResp?.message ?? '';
      final isAlreadyRegistered = lastResp?.alreadyRegistered == true ||
          errorMsg.toLowerCase().contains('already registered') ||
          errorMsg.toLowerCase().contains('already exists');

      if (isAlreadyRegistered) {
        await AuthStatusDialog.show(
          isSuccess: false,
          title: 'Already Registered',
          message: errorMsg.isNotEmpty
              ? errorMsg
              : 'This mobile number is already registered. Please login to continue.',
          buttonText: 'Go to Login',
          onConfirm: () {
            final m = mobileController.text.trim();
            final e = emailController.text.trim();
            resetLoginState(keepCredentials: true);
            loginMobileController.text = m;
            loginEmailController.text = e;
            Get.off(() => const LoginScreen());
          },
        );
      } else {
        await AuthStatusDialog.show(
          isSuccess: false,
          title: 'Registration Failed',
          message: errorMsg.isNotEmpty
              ? errorMsg
              : 'Failed to complete registration. Please try again.',
        );
      }
    }
  }

  void onGoogleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithGoogle();
    } catch (e) {
      Loggers.error(e);
      Get.back();
    }

    if (credential?.user == null) return;
    user.User? data = await _registration(
        identity: credential?.user?.email ?? '',
        loginMethod: LoginMethod.google,
        fullname: credential?.user?.displayName ?? credential?.user?.email?.split('@')[0],
        loginVia: LoginVia.loginInUser);
    Get.back();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  void onAppleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
      Loggers.info(
          'EMAIL : ${credential.user?.email} FULLNAME : ${credential.user?.displayName ?? credential.user?.email?.split('@')[0]}');
    } catch (e) {
      Loggers.error(e);
      Get.back();
    }
    if (credential?.user == null) return;
    user.User? data = await _registration(
        identity: credential?.user?.email ?? '',
        loginMethod: LoginMethod.apple,
        fullname: credential?.user?.displayName ?? credential?.user?.email?.split('@')[0],
        loginVia: LoginVia.loginInUser);
    Get.back();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  Future<user.User?> _registration(
      {required String identity,
      required LoginMethod loginMethod,
      String? fullname,
      required LoginVia loginVia,
      String? password,
      int? categoryId,
      int? subCategoryId,
      int? topicId,
      int? languageId,
      String? categoryName,
      String? subCategoryName,
      String? topicName,
      String? languageName,
      bool? isAdult,
      String? referId,
      String? mobile,
      String? mobileCountryCode,
      String? address1,
      String? address2,
      String? city,
      String? state,
      String? country,
      String? zipcode}) async {
    String? deviceToken = await FirebaseNotificationManager.instance.getNotificationToken();

    user.User? userData;
    switch (loginVia) {
      case LoginVia.loginInUser:
        userData = await UserService.instance.logInUser(
            identity: identity,
            loginMethod: loginMethod,
            deviceToken: deviceToken,
            fullName: fullname,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            topicId: topicId,
            languageId: languageId,
            categoryName: categoryName,
            subCategoryName: subCategoryName,
            topicName: topicName,
            languageName: languageName,
            isAdult: isAdult,
            referId: referId,
            mobile: mobile,
            mobileCountryCode: mobileCountryCode,
            address1: address1,
            address2: address2,
            city: city,
            state: state,
            country: country,
            zipcode: zipcode);
      case LoginVia.logInFakeUser:
        userData = await UserService.instance
            .logInFakeUser(identity: identity, loginMethod: loginMethod, deviceToken: deviceToken, password: password);
    }

    Setting? setting = SessionManager.instance.getSettings();
    if (userData?.isDummy == 0 && userData?.newRegister == true && setting?.registrationBonusStatus == 1) {
      final translations = Get.find<DynamicTranslations>();
      final languageData = translations.keys[userData?.appLanguage] ?? {};

      NotificationService.instance.pushNotification(
          title: languageData[LKey.registrationBonusTitle] ?? LKey.registrationBonusTitle.tr,
          body: languageData[LKey.registrationBonusDescription] ?? LKey.registrationBonusDescription.tr,
          type: NotificationType.other,
          deviceType: userData?.device,
          token: userData?.deviceToken,
          authorizationToken: userData?.token?.authToken);
    }
    if (userData != null) {
      // Subscribe My Following Ids For Live streaming notification
      return userData;
    }
    return null;
  }

  Future<UserCredential?> createUserWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      SessionManager.instance.setPassword(passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      Loggers.error(e.message);
      if (e.code == 'weak-password') {
        showSnackBar(LKey.weakPassword.tr);
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(LKey.accountExists.tr);
      } else {
        showSnackBar(e.message);
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      if (e.code == 'user-not-found') {
        showSnackBar(LKey.noUserFound.tr);
        Loggers.info(LKey.noUserFound.tr);
      } else if (e.code == 'wrong-password') {
        showSnackBar(LKey.incorrectPassword.tr);
        Loggers.info(LKey.incorrectPassword.tr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    googleSignIn.initialize();
    GoogleSignInAccount account = await googleSignIn.authenticate();

    // Create a new credential
    final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com")
        .credential(idToken: appleCredential.identityToken, accessToken: appleCredential.authorizationCode);

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  void forgetPassword() async {
    final email = forgetEmailController.text.trim();
    if (email.isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    showLoader();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      stopLoader();
      Get.back(); // Close the BottomSheet
      showSnackBar(LKey.resetPasswordLinkSent.tr);
    } on FirebaseAuthException catch (e) {
      stopLoader();
      showSnackBar(e.message ?? "An error occurred. Please try again.");
    }
  }

  void _navigateScreen(user.User? data) {
    DebounceAction.shared.call(() async {
      SessionManager.instance.setLogin(true);
      SessionManager.instance.setUser(data);
      if (data?.verificationPhoto == null || (data?.verificationPhoto ?? '').isEmpty) {
        Get.offAll(() => PhotoVerificationScreen(userData: data));
      } else {
        Get.offAll(() => InterestCategoryScreen(userData: data));
      }
    }, milliseconds: 250);
  }

  /// For registrations and logins — route through Photo Verification first if needed, then Interest selection.
  void _navigateScreenWithInterest(user.User? data) {
    DebounceAction.shared.call(() async {
      SessionManager.instance.setLogin(true);
      SessionManager.instance.setUser(data);
      if (data?.verificationPhoto == null || (data?.verificationPhoto ?? '').isEmpty) {
        Get.offAll(() => PhotoVerificationScreen(userData: data));
      } else {
        Get.offAll(() => InterestCategoryScreen(userData: data));
      }
    }, milliseconds: 250);
  }
}

enum LoginVia { loginInUser, logInFakeUser }

/// Full-screen Lottie success animation shown after a successful login.
/// Uses the same interest/success.json as the interest selection flow.
/// Auto-navigates to Dashboard after 2.5 seconds.
class _LoginSuccessScreen extends StatefulWidget {
  final dynamic userData;
  const _LoginSuccessScreen({this.userData});

  @override
  State<_LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<_LoginSuccessScreen> {
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _playSound();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Get.offAll(() => DashboardScreen(myUser: widget.userData));
      }
    });
  }

  Future<void> _playSound() async {
    try {
      _player = AudioPlayer();
      await _player?.setAsset('assets/interest/Success.mp3');
      await _player?.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1DB954).withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                        blurRadius: 70,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    'assets/interest/success.json',
                    fit: BoxFit.contain,
                    repeat: false,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1DB954),
                      size: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome Back! 👋',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1DB954),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'You have logged in successfully.\nLet\'s get learning!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
