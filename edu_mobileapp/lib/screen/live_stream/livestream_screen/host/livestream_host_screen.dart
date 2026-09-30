import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:geoedu/common/widget/live_room/side_action_column.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/host/widget/live_stream_host_top_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/battle_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_stream_bottom_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_video_player.dart';
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
            controller.onStopButtonTap();
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
            KeyboardAvoider(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LiveStreamHostTopView(controller: controller),
                  LiveStreamBottomView(controller: controller),
                ],
              ),
            ),
            if (widget.isHost)
              Positioned(
                right: 10,
                bottom: MediaQuery.of(context).size.height / 2.7 + 20,
                child: SafeArea(child: SideActionColumn(controller: controller)),
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
