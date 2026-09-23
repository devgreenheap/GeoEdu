import 'package:flutter/material.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/screen/leader_board/widget/top_user_widget.dart';

import '../../../utilities/asset_res.dart';

class LeaderboardTopThree extends StatelessWidget {
  final bool isDiamond;
  final List<LeaderboardUser> topUsers;
  final void Function(LeaderboardUser user)? onFollowTap;
  final void Function(LeaderboardUser user)? onUserTap;

  const LeaderboardTopThree({
    super.key,
    required this.isDiamond,
    required this.topUsers,
    this.onFollowTap,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    // Podium order is 2nd, 1st, 3rd left-to-right.
    const podium = [1, 0, 2];
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.asset(AssetRes.pyramid, fit: BoxFit.contain),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: podium.map((index) {
              return Expanded(
                child: TopUser(
                  rank: index + 1,
                  user: topUsers[index],
                  isDiamond: isDiamond,
                  onFollowTap: onFollowTap == null
                      ? null
                      : () => onFollowTap!(topUsers[index]),
                  onTap: onUserTap == null
                      ? null
                      : () => onUserTap!(topUsers[index]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
