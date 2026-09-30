import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/livestream_audience_top_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/battle_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_stream_bottom_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/live_video_player.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/battle_start_countdown_overlay.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_background_blur_image.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requested_sheet.dart';
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: blackPure(context),
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            controller.onCloseAudienceBtn();
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
            IgnorePointer(
              ignoring: true,
              child: EntryEffectLayer(controller: controller),
            ),
            GiftEffectWidget(activeGifts: controller.activeGifts),
            KeyboardAvoider(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LiveStreamAudienceTopView(
                      isAudience: true, controller: controller),
                  LiveStreamBottomView(
                      isAudience: true, controller: controller),
                ],
              ),
            ),

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
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110, right: 4),
        child: Obx(() {
          final liveData = controller.liveData.value;
          final isBattleOn = liveData.type == LivestreamType.battle;
          final isCoHost =
              (liveData.coHostIds ?? []).contains(controller.myUserId);

          if (isBattleOn || liveData.isRestrictToJoin != 0 || isCoHost) {
            return const SizedBox();
          }

          final myState = controller.liveUsersStates
              .firstWhereOrNull((u) => u.userId == controller.myUserId);
          final isRequested = myState?.type == LivestreamUserType.requested;

          if (isRequested) {
            return GestureDetector(
              onTap: () {
                CallRequestedSheet.show(context);
              },
              child: Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white60,
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Requested',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => controller.onVideoRequestSend(liveData),
                  child: Icon(
                    Icons.video_call,
                    color: blackPure(context),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Join Call",
                style: TextStyle(
                  color: whitePure(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
