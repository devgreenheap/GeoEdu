import 'dart:io';

import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/eula_sheet.dart';
import 'package:geoedu/common/widget/restart_widget.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/screen/select_language_screen/select_language_screen.dart';

class SelectLanguageScreenController extends BaseController {
  Rx<Language?> selectedLanguage = Rx(null);
  RxList<Language> languages = <Language>[].obs;
  LanguageNavigationType languageNavigationType;
  RxBool useAppInEnglish = true.obs;

  Setting? get setting => SessionManager.instance.getSettings();
  SelectLanguageScreenController(this.languageNavigationType);

  @override
  void onInit() {
    super.onInit();
    // Default is true (use app in English)
    final stored = SessionManager.instance.storage.read<bool>(SessionKeys.useAppInEnglish);
    useAppInEnglish.value = stored ?? true;
    initLanguage();
  }

  @override
  void onReady() {
    super.onReady();
    if (languageNavigationType == LanguageNavigationType.fromStart) {
      openEULASheet();
    }
  }

  Future<void> openEULASheet() async {
    if (Platform.isIOS) {
      bool shouldOpen = SessionManager.instance.shouldOpenEULASheet;

      await Future.delayed(const Duration(milliseconds: 250));
      Loggers.info('message  $shouldOpen');
      if (shouldOpen) {
        Get.bottomSheet(const EulaSheet(),
            isScrollControlled: true, enableDrag: false);
      }
    }
  }

  void initLanguage() {
    List<Language> items =
        SessionManager.instance.getSettings()?.languages ?? [];
    items.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
    for (Language element in items) {
      if (element.status == 1) {
        languages.add(element);
      }
    }

    // The language list selection is for live room filtering
    final savedLiveRoomCode = SessionManager.instance.storage.read<String>(SessionKeys.liveRoomLanguageCode);
    if (savedLiveRoomCode != null) {
      selectedLanguage.value = languages.firstWhereOrNull((e) => e.code == savedLiveRoomCode);
    }
    // Fallback: use the current app lang
    selectedLanguage.value ??= languages.firstWhereOrNull((e) => e.code == SessionManager.instance.getLang());
  }

  void onLanguageChange(Language? value) {
    selectedLanguage.value = value;

    // Save as live room language
    SessionManager.instance.storage.write(SessionKeys.liveRoomLanguageCode, value?.code ?? 'en');
    SessionManager.instance.storage.write(SessionKeys.liveRoomLanguageId, value?.id);

    if (!useAppInEnglish.value) {
      // Toggle is OFF → app language follows selected language
      SessionManager.instance.setLang(value?.code ?? 'en');
      RestartWidget.restartApp(Get.context!);
    }
  }

  void toggleUseAppInEnglish(bool value) {
    useAppInEnglish.value = value;
    SessionManager.instance.setBool(SessionKeys.useAppInEnglish, value);

    if (value) {
      // Toggle ON → set app language to English
      SessionManager.instance.setLang('en');
    } else {
      // Toggle OFF → set app language to selected language from list
      final selectedCode = selectedLanguage.value?.code ?? 'en';
      SessionManager.instance.setLang(selectedCode);
    }
    RestartWidget.restartApp(Get.context!);
  }
}
