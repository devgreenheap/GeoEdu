import 'package:flutter/material.dart';
import 'package:geoedu/screen/level_screen/level_screen_2/level_rewards/widgets/timeline_widget.dart';

class RewardLevel {
  final int level;
  final int xpRequired;
  final List<RewardItem> rewards;
  final String badge;

  RewardLevel({
    required this.level,
    required this.xpRequired,
    required this.rewards,
    this.badge = "assets/images/badge.png",
  });
}

class RewardItem {
  final String title;
  final String subtitle;
  final String icon;

  RewardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    List<RewardLevel> rewardLevels = [
      RewardLevel(
        level: 0,
        xpRequired: 0,
        rewards: [],
      ),
      RewardLevel(
        level: 1,
        xpRequired: 10,
        rewards: [
          RewardItem(
            title: "Level 1 Badge",
            subtitle: "Lv. 1",
            icon: "assets/images/discount.png",
          ),
          RewardItem(
            title: "5% Off Coupon",
            subtitle: "5% Off",
            icon: "assets/images/discount.png",
          ),
        ],
      ),
      RewardLevel(
        level: 2,
        xpRequired: 20,
        rewards: [
          RewardItem(
            title: "5% Off Coupon",
            subtitle: "5% Off",
            icon: "assets/images/discount.png",
          ),
        ],
      ),
      RewardLevel(
        level: 3,
        xpRequired: 30,
        rewards: [
          RewardItem(
            title: "5% Off Coupon",
            subtitle: "5% Off",
            icon: "assets/images/discount.png",
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0220),
      appBar: AppBar(
        title: const Text("All Rewards"),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewardLevels.length,
        itemBuilder: (context, index) {
          final level = rewardLevels[index];
          return RewardTimelineTile(level: level);
        },
      ),
    );
  }
}