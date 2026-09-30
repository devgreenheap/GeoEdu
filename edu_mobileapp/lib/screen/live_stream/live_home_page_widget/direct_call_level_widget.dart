import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/level_screen/level_screen_2/level_screen_new.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';

class DirectCallLevelWidget extends StatelessWidget {
  const DirectCallLevelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
    final userLevel = user?.getLevel.level ?? 1;
    final controller = Get.find<LiveStreamSearchScreenController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // DIRECT CALL CARD
          Expanded(
            child: Obx(() {
              final realLives = controller.livestreamFilterList
                  .where((s) => s.isDummyLive != 1)
                  .toList();
              final dummyLives = controller.livestreamFilterList
                  .where((s) => s.isDummyLive == 1)
                  .toList();

              // Top 3 host avatars for overlapping stack
              final avatarList = <String>[];
              for (final live in [...realLives, ...dummyLives]) {
                final p = live.hostUser?.profile;
                if (p != null && p.isNotEmpty && !avatarList.contains(p)) {
                  avatarList.add(p);
                  if (avatarList.length == 3) break;
                }
              }

              return _buildDirectCallCard(
                avatarUrls: avatarList,
                onTap: () => _onDirectCallTap(controller, realLives, context),
              );
            }),
          ),

          const SizedBox(width: 12),

          // MY LEVEL CARD
          Expanded(
            child: _buildMyLevelCard(
              level: userLevel,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const LevelScreenNew()));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onDirectCallTap(
      LiveStreamSearchScreenController controller,
      List<Livestream> realLives,
      BuildContext context) {
    if (realLives.isNotEmpty) {
      final stream = realLives.first;
      controller.onLiveUserTap(stream);
    } else {
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
        Get.back();
        if (dummyLives.isNotEmpty) {
          final random = dummyLives[Random().nextInt(dummyLives.length)];
          controller.onLiveUserTap(random);
        }
      },
    ));
  }

  Widget _buildDirectCallCard({
    required List<String> avatarUrls,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF8533),
              Color(0xFFFF5E62),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E62).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // White rounded video camera icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Color(0xFFFF6B4A),
                size: 24,
              ),
            ),

            const SizedBox(width: 10),

            // Title & Subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Direct Call',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Connect with hosts',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Right side: overlapping avatars + arrow button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Overlapping avatar stack
                SizedBox(
                  width: 44,
                  height: 24,
                  child: Stack(
                    children: [
                      for (int i = 0; i < (avatarUrls.isEmpty ? 3 : avatarUrls.length); i++)
                        Positioned(
                          left: i * 11.0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              color: const Color(0xFF333333),
                            ),
                            child: ClipOval(
                              child: (avatarUrls.length > i && avatarUrls[i].isNotEmpty)
                                  ? Image.network(
                                      avatarUrls[i],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        AssetRes.personGirlIcon,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      AssetRes.personGirlIcon,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Circular white pill with arrow
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF5E62),
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLevelCard({
    required int level,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F5A38),
              Color(0xFF07331E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F5A38).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Signal/Bar chart icon in mint green
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 4.5,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7A2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 2.5),
                Container(
                  width: 4.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7A2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 2.5),
                Container(
                  width: 4.5,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7A2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // Title & Level value
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Level',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Level ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '$level',
                          style: const TextStyle(
                            color: Color(0xFFFFD233),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Golden crown inside dashed circular border
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD233).withValues(alpha: 0.6),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.military_tech_rounded,
                  color: Color(0xFFFFD233),
                  size: 26,
                ),
              ),
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