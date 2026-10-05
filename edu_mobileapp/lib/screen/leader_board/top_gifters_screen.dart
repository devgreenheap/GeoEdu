import 'package:flutter/material.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/service/navigation/navigate_with_controller.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/screen/leader_board/widget/leader_board_background.dart';
import 'package:geoedu/screen/leader_board/widget/leaderboard_list.dart';
import 'package:geoedu/screen/leader_board/widget/leaderboard_top_three.dart';
import '../../utilities/color_res.dart';

class TopGiftersScreen extends StatefulWidget {
  const TopGiftersScreen({super.key});

  @override
  State<TopGiftersScreen> createState() => _TopGiftersScreenState();
}

class _TopGiftersScreenState extends State<TopGiftersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      appBar: AppBar(
        title: const Text(
          "Top Gifters",
          style: TextStyle(color: ColorRes.whitePure),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: kAppBarGradient),
            ),
            Positioned(
              left: 150,
              right: 20,
              top: 8,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              left: 200,
              top: 20,
              right: 15,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const LeaderBoardBackground(),
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: ColorRes.cardBackground.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    labelPadding: EdgeInsets.symmetric(horizontal: 14),
                    indicatorColor: ColorRes.primaryColor,
                    indicatorWeight: 3,
                    labelColor: ColorRes.primaryColor,
                    unselectedLabelColor: ColorRes.textDarkGrey,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    tabs: [
                      Tab(text: "Yesterday"),
                      Tab(text: "Today"),
                      Tab(text: "This Month"),
                      Tab(text: "This Week"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _DynamicGifterTab(period: "yesterday"),
                      _DynamicGifterTab(period: "today"),
                      _DynamicGifterTab(period: "this_month"),
                      _DynamicGifterTab(period: "this_week"),
                    ],
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

class _DynamicGifterTab extends StatefulWidget {
  final String period;

  const _DynamicGifterTab({required this.period});

  @override
  State<_DynamicGifterTab> createState() => _DynamicGifterTabState();
}

class _DynamicGifterTabState extends State<_DynamicGifterTab>
    with AutomaticKeepAliveClientMixin {
  List<LeaderboardUser> users = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final model = await CommonService.instance
          .fetchTopGifters(period: widget.period);
      if (!mounted) return;
      setState(() {
        users = model.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _openProfile(LeaderboardUser user) async {
    if (user.userId == null) return;
    BaseController.share.showLoader();
    try {
      final fetchedUser =
          await UserService.instance.fetchUserDetails(userId: user.userId);
      BaseController.share.stopLoader();
      if (fetchedUser != null) {
        NavigationService.shared.openProfileScreen(fetchedUser);
      }
    } catch (_) {
      BaseController.share.stopLoader();
    }
  }

  Future<void> _toggleFollow(LeaderboardUser user) async {
    final userId = user.userId;
    final myUserId = SessionManager.instance.getUser()?.id ?? -1;
    if (userId == null || userId == myUserId) return;

    final wasFollowing = user.isFollowing;
    setState(() {
      user.isFollowing = !wasFollowing;
    });

    final result = wasFollowing
        ? await UserService.instance.unFollowUser(userId: userId)
        : await UserService.instance.followUser(userId: userId);

    if (result.status != true && mounted) {
      setState(() {
        user.isFollowing = wasFollowing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: ColorRes.textDarkGrey, fontSize: 16),
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (users.length >= 3)
            LeaderboardTopThree(
              isDiamond: true,
              topUsers: users,
              onUserTap: _openProfile,
              onFollowTap: _toggleFollow,
            ),
          const SizedBox(height: 16),
          LeaderboardList(
            users: users,
            isDiamond: true,
            myUserId: SessionManager.instance.getUser()?.id ?? -1,
            onUserTap: _openProfile,
            onFollowTap: _toggleFollow,
          ),
        ],
      ),
    );
  }
}
