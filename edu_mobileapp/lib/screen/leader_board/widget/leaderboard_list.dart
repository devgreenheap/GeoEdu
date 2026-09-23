import 'package:flutter/material.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';

import 'leaderboard_user_tile.dart';

class LeaderboardList extends StatelessWidget {
  final List<LeaderboardUser> users;
  final bool isDiamond;
  final bool showWins;
  final int myUserId;
  final void Function(LeaderboardUser user)? onFollowTap;
  final void Function(LeaderboardUser user)? onUserTap;

  const LeaderboardList({
    super.key,
    required this.users,
    required this.isDiamond,
    required this.myUserId,
    this.showWins = false,
    this.onFollowTap,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 100),
      itemBuilder: (context, index) {
        final user = users[index];
        return LeaderboardUserTile(
          user: user,
          isDiamond: isDiamond,
          showWins: showWins,
          isMe: user.userId == myUserId,
          onFollowTap:
              onFollowTap == null ? null : () => onFollowTap!(user),
          onTap: onUserTap == null ? null : () => onUserTap!(user),
        );
      },
    );
  }
}
