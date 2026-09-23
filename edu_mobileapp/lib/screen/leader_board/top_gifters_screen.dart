import 'package:flutter/material.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
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
                  color: Colors.white.withOpacity(0.05),
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
                  color: Colors.white.withOpacity(0.05),
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
                  ),
                  child: const TabBar(
                    isScrollable: true,
                    indicatorColor: ColorRes.primaryColor,
                    indicatorWeight: 3,
                    labelColor: ColorRes.primaryColor,
                    unselectedLabelColor: ColorRes.textDarkGrey,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    tabs: [
                      Tab(text: "Yesterday"),
                      Tab(text: "Today"),
                      Tab(text: "This Month"),
                      Tab(text: "This Week"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
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
      child: Column(
        children: [
          if (users.length >= 3)
            LeaderboardTopThree(isDiamond: true, topUsers: users),
          const SizedBox(height: 20),
          LeaderboardList(
            users: users,
            isDiamond: true,
            myUserId: SessionManager.instance.getUser()?.id ?? -1,
          ),
        ],
      ),
    );
  }
}
