import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/screen/select_language_screen/select_language_screen_controller.dart';

enum LanguageNavigationType { fromStart, fromSetting }

const _flagEmojiByCode = {
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

String _flagEmoji(String? code) => _flagEmojiByCode[code?.toLowerCase()] ?? '🌐';

/// Distinct colorful tiles matching the 2nd image style
Color _getLanguageCardColor(String? code, int index) {
  switch (code?.toLowerCase()) {
    case 'hi': // Hindi: Rich Amber/Brownish Orange
      return const Color(0xFFC04B14);
    case 'te': // Telugu: Vibrant Teal / Ocean Cyan
      return const Color(0xFF02889B);
    case 'ta': // Tamil: Warm Olive / Lime Green
      return const Color(0xFF7E8813);
    case 'bn': // Bengali: Deep Coral / Crimson Red
      return const Color(0xFFC61B24);
    case 'mr': // Marathi: Bright Carmine / Red
      return const Color(0xFFD32F2F);
    case 'pa': // Punjabi: Royal Cobalt Blue
      return const Color(0xFF0D52BA);
    case 'kn': // Kannada: Magenta / Berry Pink
      return const Color(0xFFC2185B);
    case 'ml': // Malayalam: Bright Emerald Green
      return const Color(0xFF1E8E3E);
    case 'gu': // Gujarati
      return const Color(0xFFD97706);
    case 'en': // English
      return const Color(0xFF2E384D);
    case 'ur': // Urdu
      return const Color(0xFF0F766E);
    default:
      const fallbackPalette = [
        Color(0xFFC04B14),
        Color(0xFF02889B),
        Color(0xFF7E8813),
        Color(0xFFC61B24),
        Color(0xFFD32F2F),
        Color(0xFF0D52BA),
        Color(0xFFC2185B),
        Color(0xFF1E8E3E),
      ];
      return fallbackPalette[index % fallbackPalette.length];
  }
}

class SelectLanguageScreen extends StatelessWidget {
  final LanguageNavigationType languageNavigationType;

  const SelectLanguageScreen({super.key, required this.languageNavigationType});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(SelectLanguageScreenController(languageNavigationType));

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: Stack(
        children: [
          // Background ambient gradient glow (top-right)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6A00).withValues(alpha: 0.16),
                    const Color(0xFF8A3B00).withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Background ambient gradient glow (bottom-left)
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6A00).withValues(alpha: 0.14),
                    const Color(0xFF8A3B00).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row / Back button & Globe Icon
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Orange Globe Icon Badge
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF7A00),
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: Color(0xFF0C0C0C),
                          size: 32,
                        ),
                      ),

                      if (languageNavigationType ==
                          LanguageNavigationType.fromSetting)
                        GestureDetector(
                          onTap: () => controller.applyLanguageAndContinue(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // "Choose Language" Heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.15,
                        fontFamily: 'Outfit',
                      ),
                      children: [
                        TextSpan(
                          text: 'Choose\n',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Language',
                          style: TextStyle(color: Color(0xFFFF7A00)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Select your preferred language\nto continue',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Language 2-Column Grid (Division like Image 2, retaining current dark/orange design system)
                Expanded(
                  child: Obx(
                    () => GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.languages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.85,
                      ),
                      itemBuilder: (context, index) {
                        final Language language = controller.languages[index];

                        return Obx(() {
                          final currentSelected =
                              controller.selectedLanguage.value;
                          final bool isSelected = (currentSelected?.id !=
                                      null &&
                                  language.id != null &&
                                  language.id == currentSelected?.id) ||
                              (language.code != null &&
                                  currentSelected?.code != null &&
                                  language.code?.toLowerCase() ==
                                      currentSelected?.code?.toLowerCase());

                          final tileColor = _getLanguageCardColor(language.code, index);

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => controller.selectLanguage(language),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: tileColor,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFD54F)
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Text: English title + Native script title
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          language.title ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          language.localizedTitle ??
                                              language.title ??
                                              '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Radio / Check circle
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFFFFD54F)
                                          : Colors.transparent,
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              width: 1.8,
                                            ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF141414),
                                            size: 15,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),

                // Bottom Continue Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: GestureDetector(
                    onTap: () => controller.applyLanguageAndContinue(),
                    child: Container(
                      height: 58,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF8515),
                            Color(0xFFFF5200),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6A00).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Container with rounded flag icon inside
class FlagCardWidget extends StatelessWidget {
  final String? code;

  const FlagCardWidget({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final c = code?.toLowerCase() ?? '';
    Widget flagContent;

    if (c == 'en') {
      flagContent = const _UkFlag();
    } else if (c == 'hi' ||
        c == 'ta' ||
        c == 'te' ||
        c == 'kn' ||
        c == 'ml' ||
        c == 'mr' ||
        c == 'gu' ||
        c == 'pa') {
      flagContent = const _IndiaFlag();
    } else {
      flagContent = Center(
        child: Text(
          _flagEmoji(c),
          style: const TextStyle(fontSize: 22),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 28,
            child: flagContent,
          ),
        ),
      ),
    );
  }
}

/// Crisp Indian Flag
class _IndiaFlag extends StatelessWidget {
  const _IndiaFlag();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IndiaFlagPainter(),
    );
  }
}

class _IndiaFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripeHeight = size.height / 3;

    // Saffron band
    final saffronPaint = Paint()..color = const Color(0xFFFF9933);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, stripeHeight), saffronPaint);

    // White band
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, stripeHeight, size.width, stripeHeight), whitePaint);

    // Green band
    final greenPaint = Paint()..color = const Color(0xFF138808);
    canvas.drawRect(
        Rect.fromLTWH(0, stripeHeight * 2, size.width, stripeHeight),
        greenPaint);

    // Ashoka Chakra
    final center = Offset(size.width / 2, size.height / 2);
    final radius = stripeHeight * 0.42;

    final ringPaint = Paint()
      ..color = const Color(0xFF000080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, ringPaint);

    final dotPaint = Paint()..color = const Color(0xFF000080);
    canvas.drawCircle(center, 1.2, dotPaint);

    final spokePaint = Paint()
      ..color = const Color(0xFF000080)
      ..strokeWidth = 0.7;

    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi / 12);
      final p1 = Offset(
          center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      final p2 = Offset(
          center.dx - radius * math.cos(angle), center.dy - radius * math.sin(angle));
      canvas.drawLine(p1, p2, spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Crisp UK (Union Jack) Flag
class _UkFlag extends StatelessWidget {
  const _UkFlag();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _UkFlagPainter(),
    );
  }
}

class _UkFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Navy background
    final bluePaint = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bluePaint);

    // 2. White diagonals
    final whiteDiag = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.22;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), whiteDiag);
    canvas.drawLine(
        Offset(size.width, 0), Offset(0, size.height), whiteDiag);

    // 3. Red diagonals
    final redDiag = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = size.height * 0.08;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), redDiag);
    canvas.drawLine(
        Offset(size.width, 0), Offset(0, size.height), redDiag);

    // 4. White central cross
    final whiteCross = Paint()..color = Colors.white;
    final whiteThick = size.height * 0.32;
    canvas.drawRect(
        Rect.fromLTWH((size.width - whiteThick) / 2, 0, whiteThick, size.height),
        whiteCross);
    canvas.drawRect(
        Rect.fromLTWH(0, (size.height - whiteThick) / 2, size.width, whiteThick),
        whiteCross);

    // 5. Red central cross
    final redCross = Paint()..color = const Color(0xFFC8102E);
    final redThick = size.height * 0.18;
    canvas.drawRect(
        Rect.fromLTWH((size.width - redThick) / 2, 0, redThick, size.height),
        redCross);
    canvas.drawRect(
        Rect.fromLTWH(0, (size.height - redThick) / 2, size.width, redThick),
        redCross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
