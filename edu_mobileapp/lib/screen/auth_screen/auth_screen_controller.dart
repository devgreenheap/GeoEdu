import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
import 'package:geoedu/screen/dashboard_screen/dashboard_screen.dart';
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

  void clearErrors() {
    fieldErrors.clear();
    update();
  }

  bool validateForm() {
    fieldErrors.clear();

    if (fullNameController.text.trim().isEmpty) {
      fieldErrors['fullName'] = 'Full name is required';
    }
    if (emailController.text.trim().isEmpty) {
      fieldErrors['email'] = 'Email is required';
    } else if (!GetUtils.isEmail(emailController.text.trim())) {
      fieldErrors['email'] = 'Enter a valid email address';
    } else if (signupIdentityTab.value == 1 && !isOtpVerified) {
      fieldErrors['email'] = 'Please verify your email with OTP';
    }
    if (signupIdentityTab.value == 0) {
      if (mobileController.text.trim().isEmpty) {
        fieldErrors['mobile'] = 'Mobile number is required';
      } else if (!isOtpVerified) {
        fieldErrors['mobile'] = 'Please verify your mobile number with OTP';
      }
    }
    if (address1Controller.text.trim().isEmpty) {
      fieldErrors['address1'] = 'Address is required';
    }
    if (selectedCity == null || selectedCity!.isEmpty) {
      fieldErrors['city'] = 'Please select a city';
    }
    if (selectedCountry == null || selectedCountry!.isEmpty) {
      fieldErrors['country'] = 'Please select a country';
    }
    if (selectedState == null || selectedState!.isEmpty) {
      fieldErrors['state'] = 'Please select a state';
    }
    if (zipcodeController.text.trim().isEmpty) {
      fieldErrors['zipcode'] = 'Zipcode is required';
    } else if (zipcodeController.text.trim().length != 6 ||
        int.tryParse(zipcodeController.text.trim()) == null) {
      fieldErrors['zipcode'] = 'Zipcode must be exactly 6 digits';
    }

    update();
    return fieldErrors.isEmpty;
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
    update();
    try {
      final result = await UserService.instance.sendSignupOtp(
        mobileCountryCode: byEmail ? null : selectedCountryCode,
        mobile: byEmail ? null : mobile,
        email: byEmail ? email : null,
      );
      if (result.status == true) {
        isOtpSent = true;
        showSnackBar(result.message ?? 'OTP sent successfully');
      } else {
        showSnackBar(result.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      showSnackBar('Failed to send OTP');
    }
    isSendingOtp = false;
    update();
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      return showSnackBar('Please enter OTP');
    }
    final bool byEmail = signupIdentityTab.value == 1;
    isVerifyingOtp = true;
    update();
    try {
      final result = await UserService.instance.verifySignupOtp(
        mobile: byEmail ? null : mobileController.text.trim(),
        email: byEmail ? emailController.text.trim() : null,
        otp: otp,
      );
      if (result.status == true) {
        isOtpVerified = true;
        showSnackBar('OTP verified successfully');
      } else {
        showSnackBar(result.message ?? 'Invalid OTP');
      }
    } catch (e) {
      showSnackBar('Failed to verify OTP');
    }
    isVerifyingOtp = false;
    update();
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

    if (byEmail) {
      if (email.isEmpty || !GetUtils.isEmail(email)) {
        return showSnackBar('Please enter a valid email address');
      }
    } else if (mobile.isEmpty) {
      return showSnackBar('Please enter Mobile Number');
    }

    isSendingLoginOtp = true;
    update();
    try {
      final result = await UserService.instance.sendSignupOtp(
        mobileCountryCode: byEmail ? null : loginCountryCode,
        mobile: byEmail ? null : mobile,
        email: byEmail ? email : null,
      );
      if (result.status == true) {
        isLoginOtpSent = true;
        showSnackBar(result.message ?? 'OTP sent successfully');
      } else {
        showSnackBar(result.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      showSnackBar('Failed to send OTP');
    }
    isSendingLoginOtp = false;
    update();
  }

  Future<void> verifyLoginOtp() async {
    final otp = loginOtpController.text.trim();
    if (otp.isEmpty) {
      return showSnackBar('Please enter OTP');
    }
    final bool byEmail = loginIdentityTab.value == 1;
    isVerifyingLoginOtp = true;
    update();
    try {
      final result = await UserService.instance.verifySignupOtp(
        mobile: byEmail ? null : loginMobileController.text.trim(),
        email: byEmail ? loginEmailController.text.trim() : null,
        otp: otp,
      );
      if (result.status == true) {
        isLoginOtpVerified = true;
        showSnackBar('OTP verified successfully');
      } else {
        showSnackBar(result.message ?? 'Invalid OTP');
      }
    } catch (e) {
      showSnackBar('Failed to verify OTP');
    }
    isVerifyingLoginOtp = false;
    update();
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
      _navigateScreen(data);
    }
  }

  Future<void> onCreateAccount() async {
    if (!validateForm()) return;
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
        referId: referIdController.text.trim(),
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
      _navigateScreen(data);
    } else {
      showSnackBar('Account created successfully! Please login.');
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
      Get.offAll(() => DashboardScreen(myUser: data));
    }, milliseconds: 250);
  }
}

enum LoginVia { loginInUser, logInFakeUser }
