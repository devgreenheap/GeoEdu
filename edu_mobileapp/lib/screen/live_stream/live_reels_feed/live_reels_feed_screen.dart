import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/live_stream/go_live_setup_screen.dart';
import 'package:geoedu/screen/live_stream/live_reels_feed/live_reel_player_item.dart';
import 'package:geoedu/screen/live_stream/live_reels_feed/live_reels_feed_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/style_res.dart';
import 'package:geoedu/utilities/theme_res.dart';

class LiveReelsFeedScreen extends StatefulWidget {
  const LiveReelsFeedScreen({super.key});

  @override
  State<LiveReelsFeedScreen> createState() => _LiveReelsFeedScreenState();
}

class _LiveReelsFeedScreenState extends State<LiveReelsFeedScreen>
    with SingleTickerProviderStateMixin {
  late final LiveReelsFeedController controller;
  late final AnimationController _pulseController;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LiveReelsFeedController());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Fade out swipe hint after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackPure(context),
      body: Obx(() {
        if (controller.isLoading.value && controller.liveStreams.isEmpty) {
          return _buildLoadingState(context);
        }

        if (controller.liveStreams.isEmpty) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            // Vertical TikTok / Instagram Reels feed
            PageView.builder(
              controller: controller.pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: controller.liveStreams.length,
              onPageChanged: (index) {
                controller.onPageChanged(index);
                if (_showSwipeHint) {
                  setState(() {
                    _showSwipeHint = false;
                  });
                }
              },
              itemBuilder: (context, index) {
                final stream = controller.liveStreams[index];
                return Obx(() {
                  final isCurrent = controller.currentIndex.value == index;
                  final isTabActive = controller.isTabActive.value;

                  return LiveReelPlayerItem(
                    key: ValueKey(stream.roomID ?? 'reel_$index'),
                    livestream: stream,
                    isActive: isCurrent,
                    isTabActive: isTabActive,
                  );
                });
              },
            ),

            // Top Floating Live Count Badge
            SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3366),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "LIVE REELS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Obx(() => Text(
                                "${controller.currentIndex.value + 1}/${controller.liveStreams.length}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Swipe Up Hint Overlay on first reel
            if (_showSwipeHint && controller.liveStreams.length > 1)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _showSwipeHint ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_double_arrow_up_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Swipe up for next live",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF3366), Color(0xFFFF5E3A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Connecting to Real-time Lives...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF140D26), Color(0xFF090614), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Live Pulse Radar
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.1);
                final glowOpacity = 0.2 + (_pulseController.value * 0.3);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3366), Color(0xFFFF8C3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3366).withValues(alpha: glowOpacity),
                          blurRadius: 35,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.live_tv_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              "No Host Is Live Right Now",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "There are currently no hosts live. When a host starts broadcasting, their live stream will appear here in real-time.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // "Go Live Now" Primary Gradient Button
            InkWell(
              onTap: () => Get.to(() => const GoLiveSetupScreen(initialTab: 0)),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: StyleRes.themeGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: ColorRes.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Start Your Live Stream",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Pull to Refresh Button
            TextButton.icon(
              onPressed: controller.refreshStreams,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              label: const Text(
                "Refresh Live Feed",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
