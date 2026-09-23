import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/gradient_border.dart';
import 'package:geoedu/screen/level_screen/level_screen_2/level_screen_new.dart';
import 'package:geoedu/utilities/color_res.dart';

/// GIO EDU brand gradient (orange -> gold), shared by every "Lvl N" badge.
const kLevelBadgeGradient = LinearGradient(
  colors: [ColorRes.primaryColor, ColorRes.gold],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Shared "Lvl N" pill, extracted from the copy-pasted version in
/// AudioCallListScreen so it can be reused in the Go-Live setup screen and
/// Leaderboard rows too. [onTap] defaults to opening LevelScreenNew (the
/// original behavior); pass null to make it non-interactive.
class LevelBadge extends StatelessWidget {
  final int? level;
  final VoidCallback? onTap;
  final bool navigateOnTap;

  const LevelBadge({
    super.key,
    required this.level,
    this.onTap,
    this.navigateOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (level == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap ?? (navigateOnTap ? () => Get.to(() => const LevelScreenNew()) : null),
      child: GradientBorder(
        strokeWidth: 1.2,
        radius: 20,
        gradient: kLevelBadgeGradient,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield, color: Color(0xffB6FF52), size: 14),
              const SizedBox(width: 4),
              Text(
                'Lvl $level',
                style: const TextStyle(
                  color: ColorRes.whitePure,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
