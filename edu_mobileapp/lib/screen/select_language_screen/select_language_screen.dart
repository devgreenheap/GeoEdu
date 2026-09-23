import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/text_button_custom.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/screen/auth_screen/registration_screen.dart';
import 'package:geoedu/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:geoedu/screen/select_language_screen/select_language_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

enum LanguageNavigationType { fromStart, fromSetting }

const _languageAccentColors = [
  Color(0xFFFF3B7F), // pink
  Color(0xFF29D9E8), // cyan
  Color(0xFF3DDC6E), // green
  Color(0xFFFF3B5C), // red
  Color(0xFFFF9F2E), // orange
  Color(0xFF2E8CFF), // blue
  Color(0xFFB84BFF), // purple
  Color(0xFF39E07A), // green (alt)
];

Color _accentForIndex(int index) =>
    _languageAccentColors[index % _languageAccentColors.length];

const _flagByCode = {
  'hi': '🇮🇳',
  'te': '🇮🇳',
  'ta': '🇮🇳',
  'mr': '🇮🇳',
  'pa': '🇮🇳',
  'kn': '🇮🇳',
  'ml': '🇮🇳',
  'gu': '🇮🇳',
  'bn': '🇧🇩',
  'ur': '🇵🇰',
  'en': '🇬🇧',
  'es': '🇪🇸',
  'fr': '🇫🇷',
  'ar': '🇸🇦',
  'zh': '🇨🇳',
  'pt': '🇵🇹',
  'ru': '🇷🇺',
  'de': '🇩🇪',
  'ja': '🇯🇵',
  'ko': '🇰🇷',
};

String _flagForCode(String? code) => _flagByCode[code?.toLowerCase()] ?? '🌐';

class SelectLanguageScreen extends StatelessWidget {
  final LanguageNavigationType languageNavigationType;

  const SelectLanguageScreen({super.key, required this.languageNavigationType});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(SelectLanguageScreenController(languageNavigationType));
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(
                    children: [
                      if (languageNavigationType == LanguageNavigationType.fromSetting)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        )
                      else
                        const SizedBox(width: 8),
                      const Icon(Icons.public_rounded, color: ColorRes.primaryColor, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'Choose Language',
                        style: TextStyleCustom.unboundedSemiBold600(
                            fontSize: 20, color: whitePure(context)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select your preferred language',
                      style: TextStyleCustom.outFitRegular400(
                          fontSize: 14, color: whitePure(context).withValues(alpha: 0.6)),
                    ),
                  ),
                ),

                /// Language list
                Expanded(
                  child: ListView.builder(
                      itemCount: controller.languages.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      itemBuilder: (context, index) {
                        Language language = controller.languages[index];
                        return Obx(
                          () {
                            bool isSelected =
                                language == controller.selectedLanguage.value;
                            final Color accent = isSelected ? ColorRes.primaryColor : _accentForIndex(index);
                            return GestureDetector(
                              onTap: () => controller.onLanguageChange(language),
                              child: Container(
                                height: 68,
                                alignment: Alignment.center,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isSelected ? ColorRes.cardBackground : const Color(0xFF14141C),
                                  border: Border.all(color: accent, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: isSelected ? 0.45 : 0.25),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_flagForCode(language.code),
                                          style: const TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            language.localizedTitle ?? '',
                                            style: TextStyleCustom.outFitSemiBold600(
                                                fontSize: 17, color: whitePure(context)),
                                          ),
                                          Text(
                                            language.title ?? '',
                                            style: TextStyleCustom.outFitMedium500(
                                                fontSize: 13, color: accent),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? accent : Colors.transparent,
                                        border: Border.all(color: accent, width: 2),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                ),
                if (languageNavigationType == LanguageNavigationType.fromStart)
                  TextButtonCustom(
                    onTap: () {
                      // Save live room language
                      final selectedLang = controller.selectedLanguage.value;
                      SessionManager.instance.storage.write(
                          SessionKeys.liveRoomLanguageCode, selectedLang?.code ?? 'en');
                      SessionManager.instance.storage.write(
                          SessionKeys.liveRoomLanguageId, selectedLang?.id);

                      // Set app language based on toggle
                      if (controller.useAppInEnglish.value) {
                        SessionManager.instance.setLang('en');
                      } else {
                        SessionManager.instance.setLang(selectedLang?.code ?? 'en');
                      }

                      SessionManager.instance.setBool(SessionKeys.isLanguageScreenSelect, true);
                      if ((controller.setting?.onBoarding ?? []).isEmpty) {
                        Get.off(() => const RegistrationScreen());
                      } else {
                        Get.off(() => const OnBoardingScreen());
                      }
                    },
                    title: LKey.continueText.tr,
                    margin: const EdgeInsets.all(15),
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Container(
                      height: 57,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [ColorRes.primaryColor, ColorRes.orangeDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LKey.continueText.tr,
                            style: TextStyleCustom.outFitSemiBold600(
                                fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
    );
  }
}
