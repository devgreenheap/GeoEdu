import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/black_gradient_shadow.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/host/widget/live_stream_host_top_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_comment_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_like_button.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_text_field.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/livestream_exist_message_bar.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

class LiveStreamBottomView extends StatelessWidget {
  final bool isAudience;
  final LivestreamScreenController controller;

  const LiveStreamBottomView(
      {super.key, this.isAudience = false, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: Get.height / 2.7,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            const BlackGradientShadow(height: 200),
            SafeArea(
              top: false,
              child: Column(
                spacing: 5,
                children: [
                  Expanded(
                    child: Obx(() {
                      bool isVisible = controller.isViewVisible.value;
                      Livestream stream = controller.liveData.value;
                      Duration animationDuration =
                          const Duration(milliseconds: 200);
                      double animationOpacity = isVisible ? 1 : 0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            Expanded(
                                child: AnimatedOpacity(
                                    duration: animationDuration,
                                    opacity: animationOpacity,
                                    child: LiveStreamCommentView(
                                        controller: controller))),
                            Row(spacing: 5, children: [
                              if (stream.type != LivestreamType.battle)
                                AnimatedRotation(
                                  duration: animationDuration,
                                  turns: isVisible ? 0 : 0.5,
                                  child: LiveStreamCircleBorderButton(
                                      // iconColor: ColorRes.whitePure,
                                      image: AssetRes.icDownArrow_1,
                                      size: const Size(40, 40),
                                      onTap: controller.toggleView),
                                ),
                              Expanded(
                                  child: AnimatedOpacity(
                                duration: animationDuration,
                                opacity: animationOpacity,
                                child: IgnorePointer(
                                  ignoring: !isVisible,
                                  child: LiveStreamTextFieldView(
                                      isAudience: isAudience,
                                      controller: controller),
                                ),
                              )),
                              AnimatedOpacity(
                                duration: animationDuration,
                                opacity: animationOpacity,
                                child: IgnorePointer(
                                  ignoring: !isVisible,
                                  child: LiveStreamLikeButton(
                                      onLikeTap: (p0) {
                                        controller.onLikeTap = p0;
                                      },
                                      onTap: controller.onLikeButtonTap),
                                ),
                              )
                            ]),
                            Obx(() {
                              int? userId = controller.myUser.value?.id;
                              LivestreamUserState? userState = controller
                                  .liveUsersStates
                                  .firstWhereOrNull((element) => element.userId == userId);
                              if (userState?.type != LivestreamUserType.host) {
                                return const SizedBox();
                              }
                              Livestream stream = controller.liveData.value;
                              bool isVisibleBattleBtn =
                                  stream.battleType == BattleType.initiate &&
                                      controller.streamViews.length == 2 &&
                                      controller.setting?.liveBattle == 1;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Get.bottomSheet(
                                          const MembersSheet(isHost: true),
                                          isScrollControlled: true),
                                      child: Container(
                                        height: 34,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        decoration: BoxDecoration(
                                          gradient: ColorRes.primaryGradient,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                            '📞 ${LKey.requests.tr} (${controller.requestList.length})',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    if (isVisibleBattleBtn)
                                      GestureDetector(
                                        onTap: controller.startBattle,
                                        child: Container(
                                          height: 34,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(LKey.startBattle.tr,
                                              style: const TextStyle(
                                                  color: Colors.black, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            Obx(
                              () {
                                int? userId = controller.myUser.value?.id;
                                LivestreamUserState? userState =
                                    controller.liveUsersStates.firstWhereOrNull(
                                        (element) => element.userId == userId);
                                if (userState == null) return const SizedBox();
                                final isHostOrCoHost = userState.type ==
                                        LivestreamUserType.host ||
                                    userState.type == LivestreamUserType.coHost;
                                if (!isHostOrCoHost) return const SizedBox();
                                Livestream stream = controller.liveData.value;
                                bool isBattleRunning =
                                    stream.battleType == BattleType.running;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    if (LivestreamUserType.coHost ==
                                            userState.type &&
                                        stream.type ==
                                            LivestreamType.livestream)
                                      LiveStreamCircleBorderButton(
                                          onTap: () {
                                            if (isBattleRunning) {
                                              controller.showSnackBar(LKey
                                                  .cannotLeaveDuringBattle.tr);
                                            } else {
                                              controller
                                                  .closeCoHostStream(userId);
                                            }
                                          },
                                          image: AssetRes.icClose,
                                          iconColor: ColorRes.likeRed,
                                          bgColor: ColorRes.likeRed,
                                          borderColor: ColorRes.likeRed
                                              .withValues(alpha: .2)),
                                    LiveStreamCircleBorderButton(
                                        image: AssetRes.icFlip,
                                        onTap: controller.toggleFlipCamera),
                                    LiveStreamCircleBorderButton(
                                        image: userState.audioStatus ==
                                                VideoAudioStatus.on
                                            ? AssetRes.icMicrophone
                                            : AssetRes.icMicOff,
                                        onTap: () =>
                                            controller.toggleMic(userState)),
                                    LiveStreamCircleBorderButton(
                                        image: userState.videoStatus ==
                                                VideoAudioStatus.on
                                            ? AssetRes.icVideoCamera
                                            : AssetRes.icVideoOff,
                                        onTap: () =>
                                            controller.toggleVideo(userState)),
                                  ],
                                );
                              },
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                  Obx(() {
                    Livestream stream = controller.liveData.value;
                    if ((stream.type == LivestreamType.battle &&
                            stream.battleType == BattleType.end) ||
                        controller.isMinViewerTimeout.value) {
                      return LivestreamExistMessageBar(
                          controller: controller, stream: stream);
                    } else {
                      return const SizedBox();
                    }
                  }),
                  // const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
