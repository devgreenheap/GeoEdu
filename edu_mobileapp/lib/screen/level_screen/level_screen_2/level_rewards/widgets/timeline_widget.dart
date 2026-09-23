import 'package:flutter/material.dart';

import '../level_rewards_screen.dart';

class RewardTimelineTile extends StatelessWidget {
  final RewardLevel level;

  const RewardTimelineTile({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT TIMELINE
          Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF772997), Color(0xFF772997)],
                  ),
                ),
                child: level.badge != null
                    ? Image.asset(
                  level.badge!,
                  width: 30,
                  height: 30,
                )
                    : const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),              ),
              Container(
                width: 4,
                height: 120,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(width: 16),

          /// RIGHT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Level ${level.level} - ${level.xpRequired} XP",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// Rewards list
                if (level.rewards.isNotEmpty)
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: level.rewards
                        .map((reward) => _rewardItem(reward))
                        .toList(),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardItem(RewardItem reward) {
    return Column(
      children: [
        Image.asset(
          reward.icon,
          width: 20,
          height: 20,
        ),
        const SizedBox(height: 6),
        Text(
          reward.subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          reward.title,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}