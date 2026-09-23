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

    final double bottomPadding = (rank == 1) ? 20 : 10;
    final double size = rank == 1 ? 100 : 80;
    final double avatarSize = rank == 1 ? 70 : 56;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        InkWell(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomImage(
                size: Size(avatarSize, avatarSize),
                image: user.profilePhoto,
                fullName: user.fullname,
              ),
              Image.asset(
                outLineImage,
                height: size,
                width: size,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.fullname ?? user.username ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        SizedBox(
            height: rank == 1
                ? 35
                : rank == 2
                    ? 25
                    : 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text((user.totalStars ?? 0).numberFormat,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 5),
            Image.asset(isDiamond ? AssetRes.coinIcon : AssetRes.starScoreStar,
                height: 14),
          ],
        ),
        const SizedBox(height: 2),
        if (onFollowTap != null)
          InkWell(
            onTap: onFollowTap,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: 20,
              width: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: user.isFollowing
                    ? ColorRes.surfaceBackground
                    : ColorRes.primaryColor,
                borderRadius: BorderRadius.circular(50),
                border:
                    user.isFollowing ? Border.all(color: Colors.white24) : null,
              ),
              child: Text(
                user.isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontSize: 9,
                  color: user.isFollowing ? Colors.white70 : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}
