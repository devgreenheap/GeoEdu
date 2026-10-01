import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/live_summary_dialog.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/battle_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_video_player.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_video_room_overlay.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/battle_start_countdown_overlay.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_background_blur_image.dart';
import 'package:geoedu/utilities/theme_res.dart';

import '../widget/entry_effects_widget.dart';

import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_start_countdown_overlay.dart';

class LivestreamHostScreen extends StatefulWidget {
  final Livestream livestream;
  final Widget? hostPreview;
  final bool isHost;
  final int? apiLiveStreamId;

  const LivestreamHostScreen(
      {super.key,
      this.hostPreview,
      required this.livestream,
      required this.isHost,
      this.apiLiveStreamId});

  @override
  State<LivestreamHostScreen> createState() => _LivestreamHostScreenState();
}

class _LivestreamHostScreenState extends State<LivestreamHostScreen> {
  bool _showCountdown = true;
  late final LivestreamScreenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LivestreamScreenController(
      widget.livestream.obs,
      widget.isHost,
      hostPreview: widget.hostPreview,
      apiLiveStreamId: widget.apiLiveStreamId,
    ));
    // If not host, no startup countdown needed
    if (!widget.isHost) {
      _showCountdown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackPure(context),
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            showEndLiveConfirmation(
              context: context,
              title: widget.isHost ? 'End Live' : 'Leave Live',
              message: widget.isHost
                  ? 'Are you sure you want to end this live?'
                  : 'Are you sure you want to leave this live?',
              confirmText: widget.isHost ? 'End Live' : 'Leave',
              cancelText: 'Cancel',
              onConfirm: controller.onStopButtonTap,
            );
          }
        },
        child: Stack(
          children: [
            // Background blur image view
            const LiveStreamBlurBackgroundImage(),

            /// HOST screen
            Obx(
              () {
                switch (controller.liveData.value.type) {
                  case null:
                    return const Center(child: Text('No One Can live'));
                  case LivestreamType.livestream:
                    return LivestreamView(
                        streamViews: controller.streamViews,
                        controller: controller);
                  case LivestreamType.battle:
                    return BattleView(
                        isAudience: false,
                        controller: controller,
                        margin: const EdgeInsets.only(top: 60));
                  case LivestreamType.dummy:
                    return LivestreamVideoPlayer(
                        controller: controller.videoPlayerController,
                        livestream: controller.liveData.value);
                }
              },
            ),
            IgnorePointer(
              ignoring: true,
              child: EntryEffectLayer(controller: controller),
            ),
            GiftEffectWidget(activeGifts: controller.activeGifts),
            LiveVideoRoomOverlay(
              controller: controller,
              isHost: widget.isHost,
              onBackOrClose: controller.onStopButtonTap,
            ),
            Obx(
              () {
                Livestream stream = controller.liveData.value;
                bool isBattleWaiting = stream.battleType == BattleType.waiting;
                if (isBattleWaiting) {
                  return BattleStartCountdownOverlay(
                      isHost: widget.isHost, stream: stream);
                }
                return const SizedBox();
              },
            ),
            if (_showCountdown)
              LiveStartCountdownOverlay(
                isVideo: true,
                onFinished: () {
                  if (mounted) {
                    setState(() {
                      _showCountdown = false;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
