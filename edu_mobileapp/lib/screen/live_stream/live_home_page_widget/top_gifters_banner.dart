import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/screen/leader_board/leader_board_screen.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Today's top 3 gifters, shown between rows of the Home rooms grid.
/// The data is fetched once by the parent grid and passed in, so repeating
/// the banner down a long list costs no extra requests.
class TopGiftersBanner extends StatelessWidget {
  final List<LeaderboardUser> gifters;

  const TopGiftersBanner({super.key, required this.gifters});

  @override
  Widget build(BuildContext context) {
    if (gifters.isEmpty) return const SizedBox.shrink();

    final totalStars =
        gifters.fold<num>(0, (sum, g) => sum + (g.totalStars ?? 0));

    return GestureDetector(
      onTap: () => Get.to(() => const LeaderBoardScreen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD84D), Color(0xFFFFB300)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Top Gifters 🎁',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const Text('Daily Leaderboard',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Check Your Rank',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.black, size: 13),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorRes.giftBannerPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${totalStars.numberFormat} 💎',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _MiniPodium(gifters: gifters),
          ],
        ),
      ),
    );
  }
}

/// #2 left, #1 center + raised, #3 right — mirrors the full Leaderboard's
/// podium ordering at a small scale.
class _MiniPodium extends StatelessWidget {
  final List<LeaderboardUser> gifters;

  const _MiniPodium({required this.gifters});

  @override
  Widget build(BuildContext context) {
    Widget avatar(int index, double size, {bool crown = false}) {
      if (index >= gifters.length) return SizedBox(width: size);
      final user = gifters[index];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crown) const Text('👑', style: TextStyle(fontSize: 14)),
          CustomImage(
            size: Size(size, size),
            radius: size / 2,
            image: user.profilePhoto,
            fullName: user.fullname,
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
        ],
      );
    }

    return SizedBox(
      width: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          avatar(1, 34),
          const SizedBox(width: 4),
          avatar(0, 44, crown: true),
          const SizedBox(width: 4),
          avatar(2, 34),
        ],
      ),
    );
  }
}
