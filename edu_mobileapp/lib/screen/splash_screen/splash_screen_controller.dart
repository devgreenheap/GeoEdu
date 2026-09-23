import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/service/network_helper/network_helper.dart';
import 'package:geoedu/common/widget/no_internet_sheet.dart';
import 'package:geoedu/common/widget/restart_widget.dart';
import 'package:geoedu/languages/dynamic_translations.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/screen/auth_screen/login_screen.dart';
import 'package:geoedu/screen/auth_screen/registration_screen.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen.dart';
import 'package:geoedu/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:geoedu/screen/select_language_screen/select_language_screen.dart';
import 'package:geoedu/utilities/app_res.dart';

class SplashScreenController extends BaseController {
  late StreamSubscription _subscription;
  bool isOnline = true;
  bool _noInternetShown = false;
  bool _hasNavigatedAway = false;

  /// Hard ceiling on how long the splash screen will wait on network calls
  /// before forcing navigation forward, so a hung request (as opposed to a
  /// clean failure) can never leave the user stuck here indefinitely.
  static const Duration _maxSplashWait = Duration(seconds: 10);

  @override
  void onReady() {
    super.onReady();

    Future.wait([fetchSettings()]);

    Future.delayed(_maxSplashWait, () {
      if (!_hasNavigatedAway) {
        Loggers.error(
            'Splash screen exceeded ${_maxSplashWait.inSeconds}s, forcing navigation forward');
        _navigateForward();
      }
    });

    _subscription = NetworkHelper().onConnectionChange.listen((status) {
      isOnline = status;
      if (isOnline) {
        // Only pop if we actually pushed the No Internet screen — this
        // listener also fires on ordinary connectivity events during cold
        // start, and calling Get.back() with nothing pushed pops the
        // splash screen itself, leaving a blank/stuck screen.
        if (_noInternetShown) {
          _noInternetShown = false;
          Get.back();
        }
      } else {
        _noInternetShown = true;
        Get.to(() => const NoInternetSheet(), transition: Transition.downToUp);
      }
    });
  }

  /// Timeout fallback: get the user off the splash screen using whatever
  /// session state we already have locally, without waiting on any network
  /// call that may be hung. Real navigation paths in [fetchSettings] mark
  /// [_hasNavigatedAway] first, so this becomes a no-op once they've fired.
  void _navigateForward() {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    if (SessionManager.instance.isLogin()) {
      final user = SessionManager.instance.getUser();
      if (user != null) {
        Get.off(() => DashboardScreen(myUser: user));
      } else {
        Get.off(() => const LoginScreen());
      }
    } else {
      Get.off(() => const RegistrationScreen());
    }
  }

  @override
  void onClose() {
    super.onClose();
    _subscription.cancel();
  }

  Future<void> fetchSettings() async {
    bool showNavigate = await CommonService.instance.fetchGlobalSettings();
    if (showNavigate) {
      final translations = Get.find<DynamicTranslations>();
      var setting = SessionManager.instance.getSettings();
      var languages = setting?.languages ?? [];
      List<Language> downloadLanguages = languages.where((element) => element.status == 1).toList();
      if (downloadLanguages.isEmpty) {
        showSnackBar(AppRes.languageAdd, second: 3);
        return;
      }

      // Skip re-downloading every launch when the cached translations already
      // cover the current set of active language codes. Any failure here
      // (corrupt/legacy cache, unexpected shape) falls back to a normal
      // download so this optimization can never block startup.
      Map<String, Map<String, String>>? downloadedFiles;
      try {
        final currentCodes = downloadLanguages.map((e) => e.code ?? '').toSet();
        final cachedCodes = (SessionManager.instance.storage
                    .read<List>(SessionKeys.cachedTranslationLangCodes) ??
                [])
            .cast<String>()
            .toSet();
        final cachedTranslations = SessionManager.instance.storage
            .read<Map>(SessionKeys.cachedTranslations);

        if (cachedTranslations != null &&
            cachedCodes.isNotEmpty &&
            cachedCodes.containsAll(currentCodes) &&
            currentCodes.containsAll(cachedCodes)) {
          downloadedFiles = cachedTranslations.map((lang, value) => MapEntry(
              lang as String, Map<String, String>.from(value as Map)));
        }
      } catch (e) {
        Loggers.error('Translation cache read failed, will re-download: $e');
        downloadedFiles = null;
      }

      if (downloadedFiles == null) {
        downloadedFiles = await downloadAndParseLanguages(downloadLanguages);
        try {
          final currentCodes = downloadLanguages.map((e) => e.code ?? '').toSet();
          await SessionManager.instance.storage
              .write(SessionKeys.cachedTranslations, downloadedFiles);
          await SessionManager.instance.storage.write(
              SessionKeys.cachedTranslationLangCodes, currentCodes.toList());
        } catch (e) {
          Loggers.error('Translation cache write failed (non-fatal): $e');
        }
      }

      // GetMaterialApp was built in main.dart before any translations existed,
      // so it only needs a restart the first time this process populates them.
      // Restarting unconditionally re-triggers this whole method (the restart
      // tears down and rebuilds GetMaterialApp, which resets its navigation
      // stack back to SplashScreen), causing a repeating loop.
      final isFirstLoad = translations.keys.isEmpty;

      translations.addTranslations(downloadedFiles);

      var defaultLang = languages.firstWhereOrNull((element) => element.isDefault == 1);

      if (defaultLang != null) {
        SessionManager.instance.setFallbackLang(defaultLang.code ?? 'en');
      }

      if (isFirstLoad) {
        RestartWidget.restartApp(Get.context!);
      }
      if (SessionManager.instance.isLogin()) {
        UserService.instance.fetchUserDetails(userId: SessionManager.instance.getUserID()).then((value) {
          if (_hasNavigatedAway) return;
          _hasNavigatedAway = true;
          if (value != null) {
            Get.off(() => DashboardScreen(myUser: value));
          } else {
            Get.off(() => const LoginScreen());
          }
        });
      } else {


        bool isLanguageSelect = SessionManager.instance.getBool(SessionKeys.isLanguageScreenSelect);
        bool onBoardingShow = SessionManager.instance.getBool(SessionKeys.isOnBoardingScreenSelect);

        print('isLanguageSelect==> ${isLanguageSelect}');

        _hasNavigatedAway = true;
        if (isLanguageSelect == false) {
          Get.off(() => const SelectLanguageScreen(languageNavigationType: LanguageNavigationType.fromStart));
        } else if (onBoardingShow == false && (setting?.onBoarding ?? []).isNotEmpty) {
          Get.off(() => const OnBoardingScreen());
        } else {
          Get.off(() => const RegistrationScreen());
        }
      }
    }
  }

  Future<Map<String, Map<String, String>>> downloadAndParseLanguages(List<Language> languages) async {
    const int maxConcurrentDownloads = 3; // Limit concurrent downloads
    final Set<Future<void>> activeDownloads = {}; // Track active downloads
    final languageData = <String, Map<String, String>>{};

    for (var language in languages) {
      if (language.code != null && language.csvFile != null) {
        // Start the download and add it to the active set
        final downloadTask = downloadAndProcessLanguage(language, languageData);
        activeDownloads.add(downloadTask);

        // Limit concurrency
        if (activeDownloads.length >= maxConcurrentDownloads) {
          // Wait for any download to complete
          await Future.any(activeDownloads);

          // Remove completed tasks from the set
          activeDownloads.removeWhere((task) => task == Future.any(activeDownloads));
        }
      }
    }

    // Wait for all remaining downloads to complete
    await Future.wait(activeDownloads);

    return languageData;
  }

  Future<void> downloadAndProcessLanguage(Language language, Map<String, Map<String, String>> languageData) async {
    try {
      final response = await http.get(Uri.parse(language.csvFile?.addBaseURL() ?? ''));
      if (response.statusCode == 200) {
        final csvContent = utf8.decode(response.bodyBytes);
        // Parse the CSV into a map
        final parsedMap = _parseCsvToMap(csvContent);
        languageData[language.code!] = parsedMap;

        Loggers.info('Downloaded and parsed: ${language.code}');
      } else {
        Loggers.error('Failed to download ${language.code}: ${response.statusCode}');
      }
    } catch (e) {
      Loggers.error('Error downloading ${language.code}: $e');
    }
  }

  Map<String, String> _parseCsvToMap(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    final map = <String, String>{};

    for (var row in rows) {
      if (row.length >= 2) {
        map[row[0].toString()] = row[1].toString();
      }
    }
    return map;
  }
}
