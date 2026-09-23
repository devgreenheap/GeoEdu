import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/level_badge.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';

import '../../../utilities/asset_res.dart';
import '../../../utilities/color_res.dart';

class LeaderboardUserTile extends StatelessWidget {
  final LeaderboardUser user;
  final bool isDiamond;
  final bool showWins;
  final bool isMe;
  final VoidCallback? onFollowTap;
  final VoidCallback? onTap;

  const LeaderboardUserTile({
    super.key,
    required this.user,
    required this.isDiamond,
    this.showWins = false,
    this.isMe = false,
    this.onFollowTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isMe
            ? BoxDecoration(
                color: ColorRes.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: ColorRes.primaryColor.withValues(alpha: 0.5)),
              )
            : null,
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(AssetRes.starOne,
                    height: 28, width: 28, fit: BoxFit.contain),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    '${user.rank ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            CustomImage(
              size: const Size(50, 50),
              image: user.profilePhoto,
              fullName: user.fullname,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullname ?? user.username ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((user.level ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        LevelBadge(level: user.level, navigateOnTap: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        (user.totalStars ?? 0).numberFormat,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                          isDiamond ? AssetRes.coinIcon : AssetRes.starScoreStar,
                          height: 12),
                      if (showWins) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${user.wins ?? 0}W / ${user.battles ?? 0}',
                          style: const TextStyle(
                              color: ColorRes.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!isMe && onFollowTap != null)
              GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        color: user.isFollowing ? Colors.white70 : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
