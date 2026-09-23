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
import 'package:geoedu/utilities/theme_res.dart';
import '../../../../utilities/asset_res.dart';
import '../host/widget/live_stream_host_top_view.dart';
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
                      controller: controller.videoPlayerController);
              }
            }),
            EntryEffectLayer(controller: controller),
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
      /// New
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Obx(() {
          final liveData = controller.liveData.value;
          final isBattleOn = liveData.type == LivestreamType.battle;
          final isCoHost =
          (liveData.coHostIds ?? []).contains(controller.myUserId);

          return (!isBattleOn &&
              liveData.isRestrictToJoin == 0 &&
              !isCoHost)
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(

                              padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 12),
                              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                    size: 24,
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
              )
              : const SizedBox();
        }),
      ),
    );
  }
}
