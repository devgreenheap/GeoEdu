import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/functions/media_picker_helper.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/country_state_model.dart';
import 'package:geoedu/model/general/interest_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/user_model/links_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/edit_profile_screen/widget/add_edit_link_sheet.dart';
import 'package:geoedu/screen/edit_profile_screen/widget/interests_picker_sheet.dart';
import 'package:geoedu/screen/edit_profile_screen/widget/phone_codes_screen_controller.dart';
import 'package:geoedu/screen/feed_screen/feed_screen_controller.dart';

class EditProfileScreenController extends BaseController {
  final phoneController = Get.put(PhoneCodesScreenController());
  RxList<Link> links = <Link>[].obs;
  List<Interest> interestCatalog = [];
  RxList<Interest> selectedInterests = <Interest>[].obs;
  Rx<User?> userData = Rx(null);
  Rx<XFile?> fileProfileImage = Rx(null);
  Map<String, bool> usernameCache = {}; // Cache for username availability
  Timer? _debounce;
  RxBool isValidUserName = true.obs;
  TextEditingController fullNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController instagramHandleController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  /// More details controllers (Step1, Step2, Step3)
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController collegeNameController = TextEditingController();
  TextEditingController qualificationController = TextEditingController();

  /// Address controllers
  TextEditingController address1Controller = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController zipcodeController = TextEditingController();

  /// Bank details controllers (Step3)
  TextEditingController bankNameController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController ifscCodeController = TextEditingController();
  TextEditingController branchNameController = TextEditingController();

  RxInt currentStep = 0.obs;

  void next() {
    if (!_validateStepIndex(currentStep.value)) return;
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previous() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  /// Used by the step tabs, which let a user tap ahead directly instead of
  /// only using Next — moving forward still has to pass every step in
  /// between; moving back is always free.
  void goToStep(int index) {
    if (index <= currentStep.value) {
      currentStep.value = index;
      return;
    }
    for (int i = currentStep.value; i < index; i++) {
      if (!_validateStepIndex(i)) return;
    }
    currentStep.value = index;
  }

  bool _validateStepIndex(int step) {
    switch (step) {
      case 0:
        return _validateStep1();
      case 1:
        return _validateStep2();
      case 2:
        return _validateStep3();
      default:
        return true;
    }
  }

  bool _validateStep1() {
    if (firstNameController.text.trim().isEmpty) {
      showSnackBar('First name is required');
      return false;
    }
    if (selectedGender == null || selectedGender!.isEmpty) {
      showSnackBar('Gender is required');
      return false;
    }
    if (selectedDate == null) {
      showSnackBar('Date of Birth is required');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (usernameController.text.trim().isEmpty) {
      showSnackBar(LKey.usernameEmpty.tr);
      return false;
    }
    if (!isValidUserName.value) {
      showSnackBar(LKey.validUsernameEmpty.tr);
      return false;
    }
    if (collegeNameController.text.trim().isEmpty) {
      showSnackBar('College Name is required');
      return false;
    }
    if (selectedHighestDegree == null || selectedHighestDegree!.isEmpty) {
      showSnackBar('Highest Degree is required');
      return false;
    }
    if (selectedDegree == null || selectedDegree!.isEmpty) {
      showSnackBar('Degree is required');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (selectedCountry == null || selectedCountry!.isEmpty) {
      showSnackBar('Country is required');
      return false;
    }
    return true;
  }
  String? selectedGender;
  String? selectedCountry;
  String? selectedState;
  List<CountryData> countryDataList = [];
  CountryData? selectedCountryObj;
  List<String> countryList = [];
  List<String> stateList = [];
  String? selectedDegree;
  String? selectedHighestDegree;
  RxString role = "".obs;
  DateTime? selectedDate;
  String? selectedParentType;

  /// Category / SubCategory / Topic / Language
  List<Category> categoryList = [];
  List<Language> languageList = [];

  Category? selectedCategoryObj;
  SubCategory? selectedSubCategoryObj;
  Topic? selectedTopicObj;
  Language? selectedLanguageObj;

  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedTopic;
  String? selectedLanguageTitle;

  List<String> get categories =>
      categoryList.map((e) => e.name ?? '').toList();

  List<String> get subCategories => selectedCategoryObj == null
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

  List<String> get languageTitles =>
      languageList.map((e) => e.title ?? '').toList();

  void selectCategory(String? value) {
    selectedCategory = value;
    selectedCategoryObj =
        categoryList.firstWhereOrNull((e) => e.name == value);
    selectedSubCategory = null;
    selectedSubCategoryObj = null;
    selectedTopic = null;
    selectedTopicObj = null;
    update();
  }

  void selectSubCategory(String? value) {
    selectedSubCategory = value;
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

  void selectLanguageTitle(String? value) {
    selectedLanguageTitle = value;
    selectedLanguageObj =
        languageList.firstWhereOrNull((e) => e.title == value);
    update();
  }

  void selectCountry(String? value) {
    selectedCountry = value;
    selectedCountryObj =
        countryDataList.firstWhereOrNull((e) => e.name == value);
    selectedState = null;
    stateList =
        selectedCountryObj?.states?.map((e) => e.name ?? '').toList() ?? [];
    update();
  }

  void selectState(String? value) {
    selectedState = value;
    update();
  }

  Future<void> fetchCountryStateList() async {
    try {
      final result = await CommonService.instance.fetchCountryStateList();
      countryDataList = result.data ?? [];
      countryList = countryDataList.map((e) => e.name ?? '').toList();
      _preselectCountryStateFromUser();
    } catch (e) {
      Loggers.error('Failed to fetch countries: $e');
    }
    update();
  }

  void _preselectCountryStateFromUser() {
    final user = userData.value;
    if (user?.country != null && user!.country!.isNotEmpty) {
      selectedCountry = user.country;
      selectedCountryObj =
          countryDataList.firstWhereOrNull((e) => e.name == user.country);
      stateList =
          selectedCountryObj?.states?.map((e) => e.name ?? '').toList() ?? [];
    }
    if (user?.stateName != null && user!.stateName!.isNotEmpty) {
      selectedState = user.stateName;
    }
  }

  Future<void> fetchCategorySubCategoryTopic() async {
    try {
      final result =
          await CommonService.instance.fetchCategorySubCategoryTopic();
      categoryList = result.data ?? [];
      _preselectFromUser();
    } catch (e) {
      Loggers.error('Failed to fetch categories: $e');
    }
    update();
  }

  Future<void> fetchLanguages() async {
    try {
      final result = await CommonService.instance.fetchLanguages();
      languageList = result.data ?? [];
      _preselectLanguageFromUser();
    } catch (e) {
      Loggers.error('Failed to fetch languages: $e');
    }
    update();
  }

  Future<void> fetchInterestCatalog() async {
    try {
      final result = await CommonService.instance.fetchInterests();
      interestCatalog = result.data ?? [];
    } catch (e) {
      Loggers.error('Failed to fetch interest catalog: $e');
    }
    update();
  }

  Future<void> fetchMyInterests() async {
    try {
      final result = await UserService.instance.fetchMyInterests();
      selectedInterests.value = result.data ?? [];
    } catch (e) {
      Loggers.error('Failed to fetch my interests: $e');
    }
  }

  Future<void> saveInterests(List<Interest> newSelection) async {
    showLoader();
    try {
      final result = await UserService.instance.updateMyInterests(
        interestIds: newSelection.map((e) => e.id!).toList(),
      );
      selectedInterests.value = result.data ?? newSelection;
    } catch (e) {
      Loggers.error('Failed to update interests: $e');
      showSnackBar('Failed to update interests');
    }
    stopLoader();
  }

  void removeInterest(Interest interest) {
    final reduced = selectedInterests.where((e) => e.id != interest.id).toList();
    saveInterests(reduced);
  }

  void openInterestsPicker() {
    Get.bottomSheet(
      InterestsPickerSheet(controller: this),
      isScrollControlled: true,
    );
  }

  void _preselectFromUser() {
    final user = userData.value;
    if (user?.categoryId != null) {
      selectedCategoryObj =
          categoryList.firstWhereOrNull((e) => e.id == user!.categoryId);
      selectedCategory = selectedCategoryObj?.name;
    }
    if (user?.subCategoryId != null && selectedCategoryObj != null) {
      selectedSubCategoryObj = selectedCategoryObj!.subCategories
          ?.firstWhereOrNull((e) => e.id == user!.subCategoryId);
      selectedSubCategory = selectedSubCategoryObj?.name;
    }
    if (user?.topicId != null && selectedSubCategoryObj != null) {
      selectedTopicObj = selectedSubCategoryObj!.topics
          ?.firstWhereOrNull((e) => e.id == user!.topicId);
      selectedTopic = selectedTopicObj?.name;
    }
  }

  void _preselectLanguageFromUser() {
    final user = userData.value;
    if (user?.languageId != null) {
      selectedLanguageObj =
          languageList.firstWhereOrNull((e) => e.id == user!.languageId);
      selectedLanguageTitle = selectedLanguageObj?.title;
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime maxDate = DateTime(
      DateTime.now().year - 18,
      DateTime.now().month,
      DateTime.now().day,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: maxDate,
      initialDate: selectedDate != null && selectedDate!.isBefore(maxDate)
          ? selectedDate!
          : maxDate,
    );
    if (picked != null) {
      selectedDate = picked;
    }
  }

  Setting? get setting => SessionManager.instance.getSettings();

  Function(User? user)? onUpdateUser;

  EditProfileScreenController(this.onUpdateUser);

  @override
  void onInit() {
    super.onInit();
    initUserData();
    fetchCountryStateList();
    fetchCategorySubCategoryTopic();
    fetchLanguages();
    fetchInterestCatalog();
    fetchMyInterests();
  }

  @override
  void onClose() {
    super.onClose();
    _debounce?.cancel();
  }

  void initUserData() async {
    userData.value = SessionManager.instance.getUser();
    fullNameController =
        TextEditingController(text: userData.value?.fullname ?? '');
    usernameController =
        TextEditingController(text: userData.value?.username ?? '');
    bioController = TextEditingController(text: userData.value?.bio ?? '');
    instagramHandleController =
        TextEditingController(text: userData.value?.instagramHandle ?? '');
    emailController =
        TextEditingController(text: userData.value?.identity ?? userData.value?.userEmail ?? '');
    phoneNumberController =
        TextEditingController(text: userData.value?.userMobileNo);
    links.value = userData.value?.links ?? [];

    /// Pre-fill more details from existing user data
    final user = userData.value;
    firstNameController = TextEditingController(
        text: user?.firstName ?? (user?.fullname?.split(' ').first ?? ''));
    lastNameController = TextEditingController(
        text: user?.lastName ??
            ((user?.fullname?.split(' ').length ?? 0) > 1
                ? user!.fullname!.split(' ').sublist(1).join(' ')
                : ''));
    collegeNameController = TextEditingController(text: user?.collegeName ?? '');
    qualificationController = TextEditingController(text: user?.fullQualification ?? '');

    /// Address pre-fill
    address1Controller = TextEditingController(text: user?.address1 ?? '');
    address2Controller = TextEditingController(text: user?.address2 ?? '');
    cityController = TextEditingController(text: user?.city ?? '');
    zipcodeController = TextEditingController(text: user?.zipcode ?? '');

    /// Bank details pre-fill
    bankNameController = TextEditingController(text: user?.bankName ?? '');
    accountNumberController = TextEditingController(text: user?.accountNumber ?? '');
    ifscCodeController = TextEditingController(text: user?.ifscCode ?? '');
    branchNameController = TextEditingController(text: user?.branchName ?? '');

    selectedGender = user?.gender;
    selectedCountry = user?.country;
    selectedDegree = user?.degree;
    selectedHighestDegree = user?.highestDegree;
    if (user?.userRole != null && user!.userRole!.isNotEmpty) {
      role.value = user.userRole!;
    }
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(user.dateOfBirth!);
      } catch (_) {}
    }
  }



  Future<void> saveMoreDetails() async {
    // Safety net regardless of how the user got here — the step tabs allow
    // jumping around, so re-check everything, not just the current step.
    if (!_validateStep1()) {
      currentStep.value = 0;
      return;
    }
    if (!_validateStep2()) {
      currentStep.value = 1;
      return;
    }
    if (!_validateStep3()) {
      currentStep.value = 2;
      return;
    }
    showLoader();
    final dob = selectedDate != null
        ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
        : null;
    final fullName = '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim();
    User? user = await UserService.instance.updateUserDetails(
      fullname: fullName,
      userName: usernameController.text.trim(),
      bio: bioController.text.trim(),
      instagramHandle: instagramHandleController.text.trim().isNotEmpty
          ? instagramHandleController.text.trim()
          : null,
      email: emailController.text.trim(),
      profilePhoto: fileProfileImage.value,
      phoneNumber: phoneNumberController.text.trim(),
      mobileCountryCode: int.tryParse(
          phoneController.selectedCode.value?.phoneCode.replaceAll('+', '') ?? ''),
      country: selectedCountry,
      countryCode: phoneController.selectedCode.value?.countryCode,
      categoryId: selectedCategoryObj?.id,
      subCategoryId: selectedSubCategoryObj?.id,
      topicId: selectedTopicObj?.id,
      languageId: selectedLanguageObj?.id,
      categoryName: selectedCategoryObj?.name,
      subCategoryName: selectedSubCategoryObj?.name,
      topicName: selectedTopicObj?.name,
      languageName: selectedLanguageObj?.title,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      gender: selectedGender,
      dateOfBirth: dob,
      collegeName: collegeNameController.text.trim(),
      degree: selectedDegree,
      highestDegree: selectedHighestDegree,
      fullQualification: qualificationController.text.trim(),
      userRole: role.value.isNotEmpty ? role.value : null,
      address1: address1Controller.text.trim().isNotEmpty ? address1Controller.text.trim() : null,
      address2: address2Controller.text.trim().isNotEmpty ? address2Controller.text.trim() : null,
      city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : null,
      state: selectedState,
      zipcode: zipcodeController.text.trim().isNotEmpty ? zipcodeController.text.trim() : null,
      bankName: bankNameController.text.trim().isNotEmpty ? bankNameController.text.trim() : null,
      accountNumber: accountNumberController.text.trim().isNotEmpty ? accountNumberController.text.trim() : null,
      ifscCode: ifscCodeController.text.trim().isNotEmpty ? ifscCodeController.text.trim() : null,
      branchName: branchNameController.text.trim().isNotEmpty ? branchNameController.text.trim() : null,
    );
    stopLoader();
    if (user == null) return;
    onUpdateUser?.call(user);
    if (Get.isRegistered<FeedScreenController>()) {
      final feedController = Get.find<FeedScreenController>();
      feedController.myUser.value = user;
    }
    if (fileProfileImage.value != null) {
      File(fileProfileImage.value?.path ?? '').delete();
    }
    Get.back();
    Get.snackbar(
      'Saved',
      'Details updated successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void onChangeProfileImage() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Get.back();
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Get.back();
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _pickProfileImage(ImageSource source) async {
    try {
      final XFile? image =
          await MediaPickerHelper.shared.pickImage(source: source);
      if (image == null) return;
      if (fileProfileImage.value != null) {
        File(fileProfileImage.value?.path ?? '').delete();
      }
      XFile? compressed =
          await MediaPickerHelper.shared.compressProfileImage(image.path);
      if (compressed != null) {
        Loggers.info(
            "Compressed size: ${(await compressed.length()) / 1024} KB");
        fileProfileImage.value = compressed;
      }
    } on PlatformException catch (e) {
      Loggers.error(e.message);
    }
  }

  void onSaveTap() async {
    if (fullNameController.text.trim().isEmpty) {
      return showSnackBar(LKey.fullNameEmpty.tr);
    }
    if (usernameController.text.trim().isEmpty) {
      return showSnackBar(LKey.usernameEmpty.tr);
    }
    if (!isValidUserName.value) {
      return showSnackBar(LKey.validUsernameEmpty.tr);
    }
    showLoader();
    User? userData = await UserService.instance.updateUserDetails(
        fullname: fullNameController.text.trim(),
        userName: usernameController.text.trim(),
        bio: bioController.text.trim(),
        email: emailController.text.trim(),
        profilePhoto: fileProfileImage.value,
        phoneNumber: phoneNumberController.text.trim(),
        mobileCountryCode: int.parse(
            phoneController.selectedCode.value!.phoneCode.replaceAll('+', '')),
        country: phoneController.selectedCode.value?.countryName,
        countryCode: phoneController.selectedCode.value?.countryCode,
        categoryId: selectedCategoryObj?.id,
        subCategoryId: selectedSubCategoryObj?.id,
        topicId: selectedTopicObj?.id,
        languageId: selectedLanguageObj?.id,
        categoryName: selectedCategoryObj?.name,
        subCategoryName: selectedSubCategoryObj?.name,
        topicName: selectedTopicObj?.name,
        languageName: selectedLanguageObj?.title,
        address1: address1Controller.text.trim().isNotEmpty ? address1Controller.text.trim() : null,
        address2: address2Controller.text.trim().isNotEmpty ? address2Controller.text.trim() : null,
        city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : null,
        state: selectedState,
        zipcode: zipcodeController.text.trim().isNotEmpty ? zipcodeController.text.trim() : null);
    stopLoader();
    if (userData == null) return;
    onUpdateUser?.call(userData);
    if (Get.isRegistered<FeedScreenController>()) {
      final controller = Get.find<FeedScreenController>();
      controller.myUser.value = userData;
    }
    if (fileProfileImage.value != null) {
      File(fileProfileImage.value?.path ?? '').delete();
    }
    Get.back();
  }

  void checkUsernameAvailability(String value) {
    final username = value.trim(); // Use passed value and trim it once

    // Validate for spaces
    if (username.contains(' ')) {
      isValidUserName.value = false;
      return;
    }

    // Check cache first
    if (usernameCache.containsKey(username)) {
      isValidUserName.value = usernameCache[username]!;
      return;
    }

    // Check against the current user's username
    final currentUser = SessionManager.instance.getUser()?.username;
    if (username.isNotEmpty &&
        currentUser?.toLowerCase() == username.toLowerCase()) {
      isValidUserName.value = true;
      usernameCache[username] = true; // Cache the result
      return;
    }
    if (!GetUtils.isUsername(username)) {
      isValidUserName.value = true;
      return;
    }

    // Handle debounce
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final model = await UserService.instance
          .checkUsernameAvailability(userName: username);
      final isAvailable = model.status ?? true;
      isValidUserName.value = isAvailable;
      usernameCache[username] = isAvailable; // Cache the result
    });
  }

  onLinkAddEditDelete(Link link, LinkType type) {
    switch (type) {
      case LinkType.add:
        links.add(link);
      case LinkType.edit:
        links[links.indexWhere((element) => element.id == link.id)] = link;
      case LinkType.delete:
        links.removeWhere((element) => element.id == link.id);
    }
    userData.value?.links = links;
    onUpdateUser?.call(userData.value);
  }

  void handleLinkAction(LinkType value, Link link) {
    switch (value) {
      case LinkType.edit:
        Get.bottomSheet(
            AddEditLinksSheet(
                onLinksUpdate: (link) {
                  onLinkAddEditDelete(link, LinkType.edit);
                },
                type: LinkType.edit,
                link: link),
            isScrollControlled: true);
      case LinkType.delete:
        Get.bottomSheet(
            ConfirmationSheet(
              title: LKey.deleteLinkTitle.tr,
              description: LKey.deleteLinkDescription.tr,
              onTap: () async {
                showLoader();
                LinksModel value = await UserService.instance
                    .addEditDeleteUserLink(
                        linkType: LinkType.delete, linkId: link.id?.toInt());
                stopLoader();
                if (value.status ?? false) {
                  onLinkAddEditDelete(link, LinkType.delete);
                }
                // ApiService
              },
            ),
            isScrollControlled: true);
      case LinkType.add:
    }
  }

  void openAddEditLinkSheet() {
    int limit = setting?.maxUserLinks ?? 0;
    if (links.length >= limit) {
      return showSnackBar(
          LKey.maxUserLinkAddDescription.trParams({'limit': limit.toString()}));
    }
    Get.bottomSheet(
        AddEditLinksSheet(
            onLinksUpdate: (link) => onLinkAddEditDelete(link, LinkType.add),
            type: LinkType.add),
        isScrollControlled: true);
  }
}
