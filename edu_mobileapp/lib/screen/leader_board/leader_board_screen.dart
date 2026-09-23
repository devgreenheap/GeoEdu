import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/screen/leader_board/leader_board_controller.dart';
import 'package:geoedu/screen/leader_board/widget/leader_board_background.dart';
import 'package:geoedu/screen/leader_board/widget/leaderboard_category_selector.dart';
import 'package:geoedu/screen/leader_board/widget/tab_view_widget.dart';

import '../../utilities/color_res.dart';

class LeaderBoardScreen extends StatefulWidget {
  final int initialTab;
  final int initialPeriod;

  const LeaderBoardScreen({
    super.key,
    this.initialTab = 0,
    this.initialPeriod = 0,
  });

  @override
  State<LeaderBoardScreen> createState() => _LeaderBoardScreenState();
}

class _LeaderBoardScreenState extends State<LeaderBoardScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabTitles = [
    'Top Video Gifters',
    'Top Video Hosts',
    'PK Battle',
    'Top Audio Gifters',
    'Top Audio Hosts',
  ];

  late final LeaderBoardController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LeaderBoardController(
      initialTab: widget.initialTab,
      initialPeriod: widget.initialPeriod,
    ));
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<LeaderBoardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      appBar: AppBar(
        title: const Text('Leader Board',
            style: TextStyle(color: ColorRes.whitePure)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        actions: [_languageFilter(), const SizedBox(width: 12)],
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: kAppBarGradient)),
      ),
      body: Stack(
        children: [
          const LeaderBoardBackground(),
          Column(
            children: [
              Container(
                color: ColorRes.cardBackground.withValues(alpha: 0.6),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: ColorRes.primaryColor,
                  indicatorWeight: 3,
                  labelColor: ColorRes.primaryColor,
                  unselectedLabelColor: ColorRes.textDarkGrey,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => LeaderboardCategorySelector(
                    categories: LeaderBoardController.periodLabels,
                    selectedIndex: controller.selectedPeriod.value,
                    onTap: controller.onPeriodChanged,
                  )),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    LeaderboardTab(
                        controller: controller, tabIndex: 0, isDiamond: true),
                    LeaderboardTab(
                        controller: controller, tabIndex: 1, isDiamond: false),
                    LeaderboardTab(
                        controller: controller,
                        tabIndex: 2,
                        isDiamond: true,
                        showWins: true),
                    LeaderboardTab(
                        controller: controller, tabIndex: 3, isDiamond: true),
                    LeaderboardTab(
                        controller: controller, tabIndex: 4, isDiamond: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _languageFilter() {
    return Obx(() {
      if (controller.languageList.isEmpty) return const SizedBox.shrink();
      return PopupMenuButton<Language?>(
        color: ColorRes.surfaceBackground,
        onSelected: controller.onLanguageChanged,
        itemBuilder: (context) => [
          const PopupMenuItem<Language?>(
            value: null,
            child: Text('All Languages',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
          ...controller.languageList.map((lang) => PopupMenuItem<Language?>(
                value: lang,
                child: Text(lang.title ?? '',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14)),
              )),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.selectedLanguage.value?.title ?? 'All',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white70, size: 18),
            ],
          ),
        ),
      );
    });
  }
}
