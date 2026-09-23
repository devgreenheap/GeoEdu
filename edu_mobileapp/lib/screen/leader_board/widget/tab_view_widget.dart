import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/service/navigation/navigate_with_controller.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/screen/leader_board/leader_board_controller.dart';
import 'package:geoedu/screen/leader_board/widget/leaderboard_user_tile.dart';
import 'package:geoedu/utilities/color_res.dart';

import 'leaderboard_list.dart';
import 'leaderboard_top_three.dart';

class LeaderboardTab extends StatelessWidget {
  final LeaderBoardController controller;
  final int tabIndex;
  final bool isDiamond;
  final bool showWins;

  const LeaderboardTab({
    super.key,
    required this.controller,
    required this.tabIndex,
    required this.isDiamond,
    this.showWins = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final users = controller.usersOf(tabIndex);
      final myRank = controller.myRank[tabIndex];

      if (controller.isTabLoading(tabIndex) && users.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      return RefreshIndicator(
        color: ColorRes.primaryColor,
        backgroundColor: ColorRes.surfaceBackground,
        onRefresh: () => controller.fetchTab(tabIndex),
        child: users.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 140),
                    child: Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(
                            color: ColorRes.textDarkGrey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          if (users.length >= 3)
                            LeaderboardTopThree(
                              isDiamond: isDiamond,
                              topUsers: users,
                              onFollowTap: controller.toggleFollow,
                              onUserTap: _openProfile,
                            ),
                          const SizedBox(height: 20),
                          LeaderboardList(
                            users: users,
                            isDiamond: isDiamond,
                            showWins: showWins,
                            myUserId: controller.myUserId,
                            onFollowTap: controller.toggleFollow,
                            onUserTap: _openProfile,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sticky own-rank row, so the viewer can see where they
                  // stand even when they fall outside the fetched page.
                  if (myRank != null)
                    Container(
                      color: ColorRes.blackPure,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SafeArea(
                        top: false,
                        child: LeaderboardUserTile(
                          user: myRank,
                          isDiamond: isDiamond,
                          showWins: showWins,
                          isMe: true,
                        ),
                      ),
                    ),
                ],
              ),
      );
    });
  }

  Future<void> _openProfile(LeaderboardUser user) async {
    if (user.userId == null) return;
    BaseController.share.showLoader();
    final fetchedUser =
        await UserService.instance.fetchUserDetails(userId: user.userId);
    BaseController.share.stopLoader();
    if (fetchedUser != null) {
      NavigationService.shared.openProfileScreen(fetchedUser);
    }
  }
}
