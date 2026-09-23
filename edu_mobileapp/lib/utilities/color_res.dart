import 'package:flutter/material.dart';

/// Colors mirror the Login/Create Account palette (see auth_theme.dart's
/// AuthColors) so every screen reading from the shared ThemeRes/ColorRes
/// system picks up the same dark + orange/green/gold identity.
class ColorRes {
  static const Color blackPure = Color(0xFF0D1117);
  static const Color whitePure = Color(0xFFFFFFFF);
  static const Color themeGradient1 = Color(0xFF7ACBFF);
  static const Color themeGradient2 = Color(0xFF5C8CFE);
  static const Color themeAccentSolid = Color(0xFFFF5A00);

  static const Color primaryColor = Color(0xFFFF5A00);
  static const Color primaryColorEnd = Color(0xFFFF3D00);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColorEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  // Decorative-only (stat pills, never buttons/CTAs) — the reference design
  // explicitly calls for a purple diamond-total pill on the gifters banner
  // even though buttons elsewhere must stay orange.
  static const Color giftBannerPurple = Color(0xFF8B5CF6);

  static const Color themeColor = Color(0xFF0D1117);
  static const Color textDarkGrey = Color(0xFFA1A1AA);
  static const Color textLightGrey = Color(0xFF71717A);
  static const Color orange = Color(0xFFFF7A19);
  static const Color green = Color(0xFF087F3E);
  static const Color green1 = Color(0xFF39A852);
  static const Color likeRed = Color(0xFFFF5751);
  static const Color textStoryBgGradient2 = Color(0xFFFF5757);
  static const Color blueFollow = Color(0xFF3E8BFF);
  static const Color battleProgressColor = Color(0xFF2CC3FF);
  static const Color bgLightGrey = Color(0xFF14181D);
  static const Color bgGrey = Color(0xFF2A2F35);
  static const Color bgMediumGrey = Color(0xFF101318);
  static const Color disabledGrey = Color(0xFF5A5A66);
  static const Color btnbgColor = Color(0xFF565ADC);

  // Card/surface tiers + brand accents (GIO EDU dark theme)
  static const Color cardBackground = Color(0xFF151719);
  static const Color surfaceBackground = Color(0xFF1B1E21);
  static const Color gold = Color(0xFFF5C542);
  static const Color orangeDark = Color(0xFFE85D00);
  static const Color liveRed = Color(0xFFFF3B30);
}
