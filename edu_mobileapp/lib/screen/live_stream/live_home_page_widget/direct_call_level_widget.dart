import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/level_screen/level_screen_2/level_screen_new.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
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
              final myUserId = SessionManager.instance.getUserID();
              final allLives = controller.livestreamList
                  .where((s) => s.hostId != myUserId)
                  .toList();

              // Top 3 host avatars for overlapping stack
              final avatarList = <String>[];
              for (final live in allLives) {
                final p = live.hostUser?.profile;
                if (p != null && p.isNotEmpty && !avatarList.contains(p)) {
                  avatarList.add(p);
                  if (avatarList.length == 3) break;
                }
              }

              // Also check audio rooms for avatars if needed
              if (avatarList.length < 3 && Get.isRegistered<AudioCallListController>()) {
                final audioCtrl = Get.find<AudioCallListController>();
                for (final room in audioCtrl.audioRooms) {
                  final p = room.hostPhoto;
                  if (p != null && p.isNotEmpty && !avatarList.contains(p)) {
                    avatarList.add(p);
                    if (avatarList.length == 3) break;
                  }
                }
              }

              return _buildDirectCallCard(
                avatarUrls: avatarList,
                onTap: () => _onDirectCallTap(controller, context),
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
      BuildContext context) {
    final myUserId = SessionManager.instance.getUserID();

    // Check video lives (filter-matching first, then all)
    final realFilteredLives = controller.livestreamFilterList
        .where((s) => s.isDummyLive != 1 && s.hostId != myUserId)
        .toList();
    final allRealLives = controller.livestreamList
        .where((s) => s.isDummyLive != 1 && s.hostId != myUserId)
        .toList();
    final videoLives = realFilteredLives.isNotEmpty ? realFilteredLives : allRealLives;

    // Check audio rooms
    final audioController = Get.isRegistered<AudioCallListController>()
        ? Get.find<AudioCallListController>()
        : null;
    final audioRooms = audioController?.audioRooms
            .where((r) => r.hostId != myUserId && (r.isActive ?? true))
            .toList() ??
        [];

    // Check dummy lives
    final dummyLives = controller.livestreamList
        .where((s) => s.isDummyLive == 1 && s.hostId != myUserId)
        .toList();

    Get.to(() => _FindingLiveScreen(
      videoLives: videoLives,
      audioRooms: audioRooms,
      dummyLives: dummyLives,
      controller: controller,
      audioController: audioController,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Color(0xFFFF6B4A),
                size: 20,
              ),
            ),

            const SizedBox(width: 7),

            // Title & Subtitle
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Call',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Connect with hosts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
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
                  width: 38,
                  height: 20,
                  child: Stack(
                    children: [
                      for (int i = 0; i < (avatarUrls.isEmpty ? 3 : avatarUrls.length); i++)
                        Positioned(
                          left: i * 9.0,
                          child: Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.2),
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
                const SizedBox(height: 4),
                // Circular white pill with arrow
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF5E62),
                      size: 11,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  width: 4,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7A2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7A2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7A2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 7),

            // Title & Level value
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Level',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '$level',
                          style: const TextStyle(
                            color: Color(0xFFFFD233),
                            fontSize: 10.5,
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
              width: 38,
              height: 38,
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
                  size: 22,
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
  final List<Livestream> videoLives;
  final List<AudioRoom> audioRooms;
  final List<Livestream> dummyLives;
  final LiveStreamSearchScreenController controller;
  final AudioCallListController? audioController;

  const _FindingLiveScreen({
    required this.videoLives,
    required this.audioRooms,
    required this.dummyLives,
    required this.controller,
    this.audioController,
  });

  @override
  State<_FindingLiveScreen> createState() => _FindingLiveScreenState();
}

class _FindingLiveScreenState extends State<_FindingLiveScreen> {
  bool _noHostFound = false;

  @override
  void initState() {
    super.initState();
    _startSearching();
  }

  void _startSearching() {
    setState(() {
      _noHostFound = false;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _connectToAvailableLive();
    });
  }

  void _connectToAvailableLive() {
    final myUserId = SessionManager.instance.getUserID();

    // 1. Check real video lives (refresh from controller or use passed list)
    final freshRealLives = widget.controller.livestreamList
        .where((s) => s.isDummyLive != 1 && s.hostId != myUserId)
        .toList();
    final availableVideos =
        freshRealLives.isNotEmpty ? freshRealLives : widget.videoLives;

    if (availableVideos.isNotEmpty) {
      final chosen = availableVideos[Random().nextInt(availableVideos.length)];
      Get.off(() => LiveStreamAudienceScreen(isHost: false, livestream: chosen));
      return;
    }

    // 2. Check audio rooms
    final freshAudioRooms = widget.audioController?.audioRooms
            .where((r) => r.hostId != myUserId && (r.isActive ?? true))
            .toList() ??
        widget.audioRooms;

    if (freshAudioRooms.isNotEmpty && widget.audioController != null) {
      final chosen = freshAudioRooms[Random().nextInt(freshAudioRooms.length)];
      Get.back();
      widget.audioController!.joinAudioRoom(chosen);
      return;
    }

    // 3. Check dummy lives
    final freshDummyLives = widget.controller.livestreamList
        .where((s) => s.isDummyLive == 1 && s.hostId != myUserId)
        .toList();
    final availableDummies =
        freshDummyLives.isNotEmpty ? freshDummyLives : widget.dummyLives;

    if (availableDummies.isNotEmpty) {
      final chosen =
          availableDummies[Random().nextInt(availableDummies.length)];
      Get.off(() => LiveStreamAudienceScreen(isHost: false, livestream: chosen));
      return;
    }

    // 4. No hosts live right now
    if (mounted) {
      setState(() {
        _noHostFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _noHostFound ? _buildNoHostView() : _buildSearchingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            color: Color(0xFFFF5E62),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "Connecting to Live...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Finding an active host for you",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNoHostView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF5E62).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFFFF5E62).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.videocam_off_rounded,
              color: Color(0xFFFF5E62),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "No Hosts Live Right Now",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "There are currently no active video streams or audio rooms. Start your own live stream to connect with others!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        // Go Live Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
              backgroundColor: Colors.transparent,
              shadowColor: const Color(0xFFFF5E62).withValues(alpha: 0.4),
            ),
            onPressed: () {
              Get.back();
              widget.controller.onGoLive();
            },
            icon: Container(),
            label: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8533), Color(0xFFFF5E62)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Go Live Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Try Again & Back to Home row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _startSearching,
                child: const Text(
                  "Try Again",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Get.back(),
                child: Text(
                  "Back to Home",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}