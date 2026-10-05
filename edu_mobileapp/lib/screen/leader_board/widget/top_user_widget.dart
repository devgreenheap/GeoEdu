import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';

import '../../../utilities/asset_res.dart';
import '../../../utilities/color_res.dart';

class TopUser extends StatelessWidget {
  final int rank;
  final LeaderboardUser user;
  final bool isDiamond;
  final VoidCallback? onFollowTap;
  final VoidCallback? onTap;

  const TopUser({
    super.key,
    required this.rank,
    required this.user,
    required this.isDiamond,
    this.onFollowTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String outLineImage = (rank == 1)
        ? AssetRes.rank1
        : (rank == 2)
            ? AssetRes.rank2
            : AssetRes.rank3;

    final double frameSize = rank == 1 ? 94 : 76;
    final double avatarSize = rank == 1 ? 66 : 54;
    final double bottomPadding = rank == 1 ? 32 : (rank == 2 ? 22 : 12);
    final double midGap = rank == 1 ? 52 : (rank == 2 ? 38 : 26);

    final Color badgeBorderColor = rank == 1
        ? const Color(0xFFFFD700)
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. Avatar with Crown & Ribbon Frame
          Stack(
            alignment: Alignment.center,
            children: [
              CustomImage(
                size: Size(avatarSize, avatarSize),
                image: user.profilePhoto,
                fullName: user.fullname,
                radius: avatarSize / 2,
              ),
              Image.asset(
                outLineImage,
                height: frameSize,
                width: frameSize,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 2. Username Capsule (positioned cleanly ABOVE the pedestal, never overlapping)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.6,
              ),
            ),
            child: Text(
              user.fullname ?? user.username ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),

          // 3. Clear vertical separation placing diamond count squarely on the pedestal face
          SizedBox(height: midGap),

          // 4. Diamond / Star Score Pill on the pedestal face
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badgeBorderColor.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (user.totalStars ?? 0).numberFormat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                Image.asset(
                  isDiamond ? AssetRes.coinIcon : AssetRes.starScoreStar,
                  height: 12,
                ),
              ],
            ),
          ),
          if (onFollowTap != null) ...[
            const SizedBox(height: 3),
            InkWell(
              onTap: onFollowTap,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                height: 18,
                width: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: user.isFollowing
                      ? ColorRes.surfaceBackground
                      : ColorRes.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                  border: user.isFollowing
                      ? Border.all(color: Colors.white24)
                      : null,
                ),
                child: Text(
                  user.isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: user.isFollowing ? Colors.white70 : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
