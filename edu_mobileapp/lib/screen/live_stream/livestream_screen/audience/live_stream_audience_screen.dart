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

class LiveStreamAudienceScreen extends StatefulWidget {
  final Livestream livestream;
  final bool isHost;

  const LiveStreamAudienceScreen(
      {super.key, required this.livestream, required this.isHost});

  @override
  State<LiveStreamAudienceScreen> createState() => _LiveStreamAudienceScreenState();
}

class _LiveStreamAudienceScreenState extends State<LiveStreamAudienceScreen> {
  late LivestreamScreenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      LivestreamScreenController(widget.livestream.obs, widget.isHost),
    );
  }

  void _handleBackOrClose() {
    showEndLiveConfirmation(
      context: context,
      title: 'Leave Live',
      message: 'Are you sure you want to leave this live?',
      confirmText: 'Leave',
      cancelText: 'Cancel',
      onConfirm: controller.onCloseAudienceBtn,
    );
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
            _handleBackOrClose();
          }
        },
        child: Stack(
          children: [
            const LiveStreamBlurBackgroundImage(),
            /// Live StreamView
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
                    livestream: controller.liveData.value,
                  );
              }
            }),
            LiveVideoRoomOverlay(
              controller: controller,
              isHost: widget.isHost,
              onBackOrClose: _handleBackOrClose,
            ),
            IgnorePointer(
              ignoring: true,
              child: EntryEffectLayer(controller: controller),
            ),
            GiftEffectWidget(activeGifts: controller.activeGifts),
            Obx(
              () {
                Livestream stream = controller.liveData.value;
                bool isBattle = stream.battleType == BattleType.waiting;
                if (isBattle) {
                  return BattleStartCountdownOverlay(
                      isHost: widget.isHost, stream: stream);
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}
