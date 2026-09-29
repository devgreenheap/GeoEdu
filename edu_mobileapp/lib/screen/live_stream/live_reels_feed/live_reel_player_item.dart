import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/livestream_audience_top_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/battle_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_stream_bottom_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_video_player.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/battle_start_countdown_overlay.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/entry_effects_widget.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_background_blur_image.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/theme_res.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class LiveReelPlayerItem extends StatefulWidget {
  final Livestream livestream;
  final bool isActive;
  final bool isTabActive;

  const LiveReelPlayerItem({
    super.key,
    required this.livestream,
    required this.isActive,
    required this.isTabActive,
  });

  @override
  State<LiveReelPlayerItem> createState() => _LiveReelPlayerItemState();
}

class _LiveReelPlayerItemState extends State<LiveReelPlayerItem> {
  LivestreamScreenController? _controller;
  bool _isConnected = false;
  Timer? _debounceTimer;

  bool get _shouldPlay => widget.isActive && widget.isTabActive;

  @override
  void initState() {
    super.initState();
    if (_shouldPlay) {
      _scheduleStartStream();
    }
  }

  @override
  void didUpdateWidget(LiveReelPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasPlaying = oldWidget.isActive && oldWidget.isTabActive;
    final nowPlaying = widget.isActive && widget.isTabActive;

    if (nowPlaying && !wasPlaying) {
      _scheduleStartStream();
    } else if (!nowPlaying && wasPlaying) {
      _cancelDebounceAndStopStream();
    }
  }

  void _scheduleStartStream() {
    _debounceTimer?.cancel();
    // 100ms debounce ensures fast flinging doesn't trigger rapid consecutive logins
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted || !_shouldPlay) return;
      _startStream();
    });
  }

  void _cancelDebounceAndStopStream() {
    _debounceTimer?.cancel();
    _stopStream();
  }

  void _startStream() {
    if (_isConnected) return;

    try {
      // Unmute Zego audio when joining
      try {
        ZegoExpressEngine.instance.muteAllPlayStreamAudio(false);
      } catch (_) {}

      // Remove any previously registered LivestreamScreenController
      if (Get.isRegistered<LivestreamScreenController>()) {
        final old = Get.find<LivestreamScreenController>();
        old.onClose();
        Get.delete<LivestreamScreenController>(force: true);
      }

      // Instantiate new controller for this live stream
      final newController = LivestreamScreenController(
        widget.livestream.obs,
        false, // Audience mode
      );

      _controller = Get.put<LivestreamScreenController>(newController);
      _isConnected = true;
      if (mounted) setState(() {});
    } catch (e) {
      Loggers.error('LiveReelPlayerItem: _startStream error: $e');
    }
  }

  void _stopStream() {
    if (!_isConnected && _controller == null) return;
    _isConnected = false;

    try {
      // 1. Immediately mute and pause video player if any
      _controller?.videoPlayerController.value?.setVolume(0.0);
      _controller?.videoPlayerController.value?.pause();

      // 2. Immediately stop all active stream views in Zego
      if (_controller != null) {
        for (var stream in List<StreamView>.from(_controller!.streamViews)) {
          try {
            ZegoExpressEngine.instance.stopPlayingStream(stream.streamId);
          } catch (_) {}
        }
      }

      // 3. Immediately mute all Zego audio
      try {
        ZegoExpressEngine.instance.muteAllPlayStreamAudio(true);
      } catch (_) {}

      // 4. Close and delete controller
      _controller?.onClose();
      if (Get.isRegistered<LivestreamScreenController>()) {
        Get.delete<LivestreamScreenController>(force: true);
      }
    } catch (e) {
      Loggers.error('LiveReelPlayerItem: _stopStream error: $e');
    }
    _controller = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected && _controller != null) {
      return _buildActiveLiveStream(_controller!);
    }
    return _buildPlaceholderPreview();
  }

  Widget _buildActiveLiveStream(LivestreamScreenController controller) {
    return Scaffold(
      backgroundColor: blackPure(context),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LiveStreamBlurBackgroundImage(),

          // Live Stream View (Zego camera / PK Battle / Dummy Video)
          Obx(() {
            switch (controller.liveData.value.type) {
              case null:
              case LivestreamType.livestream:
                return LivestreamView(
                  streamViews: controller.streamViews,
                  controller: controller,
                );
              case LivestreamType.battle:
                return BattleView(
                  isAudience: true,
                  controller: controller,
                  margin: const EdgeInsets.only(top: 100),
                );
              case LivestreamType.dummy:
                return LivestreamVideoPlayer(
                  controller: controller.videoPlayerController,
                  livestream: widget.livestream,
                );
            }
          }),

          // Double tap to like detector (Instagram style)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () => controller.onLikeButtonTap(),
              child: const SizedBox.expand(),
            ),
          ),

          // Realtime Entry & Gift Animation Layers (never block touches)
          IgnorePointer(
            ignoring: true,
            child: EntryEffectLayer(controller: controller),
          ),
          GiftEffectWidget(activeGifts: controller.activeGifts),

          // Overlays: Top host info bar & bottom interactive chat
          KeyboardAvoider(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LiveStreamAudienceTopView(
                  isAudience: true,
                  controller: controller,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LiveStreamBottomView(
                    isAudience: true,
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),

          // Floating "Join Call" Video Request Button
          Positioned(
            right: 14,
            bottom: 115,
            child: _buildJoinCallButton(controller),
          ),

          // PK Battle countdown overlay if pending
          Obx(() {
            final stream = controller.liveData.value;
            if (stream.battleType == BattleType.waiting) {
              return BattleStartCountdownOverlay(isHost: false, stream: stream);
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildJoinCallButton(LivestreamScreenController controller) {
    return Obx(() {
      final liveData = controller.liveData.value;
      final isBattleOn = liveData.type == LivestreamType.battle;
      final isCoHost = (liveData.coHostIds ?? []).contains(controller.myUserId);

      if (isBattleOn || liveData.isRestrictToJoin != 0 || isCoHost) {
        return const SizedBox();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF3366), Color(0xFFFF5E3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF3366),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => controller.onVideoRequestSend(liveData),
              child: const Icon(
                Icons.video_call_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Join Call",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPlaceholderPreview() {
    final host = widget.livestream.hostUser;
    final photo = host?.profile ?? widget.livestream.thumbnailUrl;
    final name = host?.fullname ?? host?.username ?? widget.livestream.description ?? 'Live Host';

    return Container(
      color: const Color(0xFF0F0C20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background image
          if (photo != null && photo.isNotEmpty)
            Opacity(
              opacity: 0.35,
              child: CustomImage(
                image: photo.addBaseURL(),
                size: Size.infinite,
                radius: 0,
                fit: BoxFit.cover,
              ),
            ),

          // Subtle gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Centered preview badge with spinner
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorRes.primaryColor, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55FF5E3A),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CustomImage(
                    size: const Size(86, 86),
                    image: photo?.addBaseURL(),
                    fullName: name,
                    radius: 43,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF3366)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Connecting live...",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
