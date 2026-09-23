import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/level_screen/level_screen_2/level_screen_new.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

class DirectCallLevelWidget extends StatelessWidget {
  const DirectCallLevelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
    final userLevel = user?.getLevel.level ?? 0;
    final controller = Get.find<LiveStreamSearchScreenController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(child: Obx(() {
            // Find real (non-dummy) live streams
            final realLives = controller.livestreamFilterList
                .where((s) => s.isDummyLive != 1)
                .toList();
            final hasRealLive = realLives.isNotEmpty;

            // Count total watching across real lives
            final totalMembers = realLives.fold<int>(
                0, (sum, s) => sum + (s.watchingCount ?? 0));

            return _buildCard(
              gradient: const LinearGradient(
                colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              leftIcon: AssetRes.videoIcon,
              title: hasRealLive ? "Join Call" : "Direct Call",
              value: hasRealLive ? "$totalMembers watching" : "",
              rightIcon: AssetRes.personGirlIcon,
              onTap: () => _onDirectCallTap(controller, realLives, context),
            );
          })),

          const SizedBox(width: 10),

          Expanded(child: _buildCard(
            gradient: const LinearGradient(
              colors: [ColorRes.green1, ColorRes.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            leftIcon: AssetRes.levelIcon,
            title: "My Level",
            value: "$userLevel",
            valueColor: ColorRes.gold,
            rightIcon: AssetRes.levelDioIcon, onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LevelScreenNew()));
          },
          )),
        ],
      ),
    );
  }

  void _onDirectCallTap(
      LiveStreamSearchScreenController controller,
      List<Livestream> realLives,
      BuildContext context) {
    if (realLives.isNotEmpty) {
      // Join the first real live stream
      final stream = realLives.first;
      controller.onLiveUserTap(stream);
    } else {
      // No real live — show waiting screen then connect to random dummy
      _showWaitingAndConnectDummy(controller, context);
    }
  }

  void _showWaitingAndConnectDummy(
      LiveStreamSearchScreenController controller,
      BuildContext context) {
    final dummyLives = controller.livestreamFilterList
        .where((s) => s.isDummyLive == 1)
        .toList();

    Get.to(() => _FindingLiveScreen(
      onComplete: () {
        Get.back(); // Close waiting screen
        if (dummyLives.isNotEmpty) {
          final random = dummyLives[Random().nextInt(dummyLives.length)];
          controller.onLiveUserTap(random);
        }
      },
    ));
  }

  Widget _buildCard({
    required LinearGradient gradient,
    required String leftIcon,
    required String title,
    required String value,
    required String rightIcon,
    required VoidCallback onTap,
    Color valueColor = ColorRes.primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [

            /// LEFT ICON
            FittedBox(
              child: Image.asset(leftIcon, height: 16),
            ),

            const SizedBox(width: 10),

            /// TEXT AREA
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                      ),
                    ),
                    if (value.isNotEmpty)
                      Text(
                        value,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            /// RIGHT ICON
            FittedBox(
              child: Image.asset(rightIcon, height: 35),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingLiveScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const _FindingLiveScreen({required this.onComplete});

  @override
  State<_FindingLiveScreen> createState() => _FindingLiveScreenState();
}

class _FindingLiveScreenState extends State<_FindingLiveScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds then connect to dummy
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 30),
            const Text(
              "Please wait...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We will find the live for you",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}