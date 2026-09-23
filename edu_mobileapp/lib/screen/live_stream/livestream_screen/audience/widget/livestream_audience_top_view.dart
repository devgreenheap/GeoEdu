import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/common/widget/gradient_border.dart';
import 'package:geoedu/common/widget/gradient_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/live_stream_user_info_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/host/widget/live_stream_host_top_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/style_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

import '../../../../../model/user_model/user_model.dart';

class LiveStreamAudienceTopView extends StatelessWidget {
  final bool isAudience;
  final LivestreamScreenController controller;

  const LiveStreamAudienceTopView(
      {super.key, this.isAudience = false, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: EdgeInsets.only(top: AppBar().preferredSize.height * 0.7),
      child: Obx(() {
        bool isVisible = controller.isViewVisible.value;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: isVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  _BuildTopView(controller: controller),
                  _BuildCenterView(controller: controller),
                  _BuildBottomView(controller: controller)
                ],
              ),
            ),
          ),
        );
      }),

    );
  }
}

class _BuildTopView extends StatelessWidget {
  final LivestreamScreenController controller;

  const _BuildTopView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Obx(
        //   () {
        //     Livestream stream = controller.liveData.value;
        //     bool isBattleRunning = stream.battleType != BattleType.initiate;
        //     bool isAudience =
        //         stream.coHostIds?.contains(controller.myUserId) == false;
        //
        //     if (isBattleRunning && !isAudience) return const SizedBox();
        //     return InkWell(
        //       onTap: controller.onCloseAudienceBtn,
        //       child: Container(
        //         height: 25,
        //         width: 25,
        //         margin: const EdgeInsets.symmetric(horizontal: 5),
        //         decoration: BoxDecoration(
        //             shape: BoxShape.circle,
        //             border: Border.all(
        //                 color: whitePure(context).withValues(alpha: .5),
        //                 width: 1.5)),
        //         alignment: Alignment.center,
        //         child: Image.asset(AssetRes.icClose1,
        //             color: whitePure(context).withValues(alpha: .5),
        //             width: 18,
        //             height: 18),
        //       ),
        //     );
        //   },
        // ),

        InkWell(
          onTap: () {
            HapticManager.shared.light();
            controller.reportUser(controller.liveData.value.hostId);
          },
          child: Image.asset(AssetRes.icReport,
              color: whitePure(context).withValues(alpha: 0.5),
              width: 20,
              height: 20),
        ),
      ],
    );
  }
}

class _BuildCenterView extends StatelessWidget {
  final LivestreamScreenController controller;

  const _BuildCenterView({required this.controller});

  /// Real follow toggle — same FollowController/updateUserStateToFirestore
  /// path [LiveStreamUserInfoSheet] uses, so this pill and that sheet never
  /// disagree about follow state.
  Future<void> _followUnFollowHost(
      LivestreamScreenController controller, Rx<User?> user) async {
    User? target = user.value;
    final hostId = controller.liveData.value.hostId;
    if (target == null && hostId != null) {
      target = await UserService.instance.fetchUserDetails(userId: hostId);
      if (target != null) {
        final index = controller.usersList.indexWhere((u) => u.id == target!.id);
        if (index != -1) {
          controller.usersList[index] = target;
        } else {
          controller.usersList.add(target);
        }
      }
    }
    if (target?.id == null) return;
    final userId = target!.id!;
    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: userId.toString())) {
      followController = Get.find<FollowController>(tag: userId.toString());
      followController.updateUser(target);
    } else {
      followController = Get.put(FollowController(target.obs), tag: userId.toString());
    }
    final updated = await followController.followUnFollowUser();
    controller.updateUserStateToFirestore(userId, isFollow: updated?.isFollowing);
    if (updated != null) {
      final index = controller.usersList.indexWhere((u) => u.id == userId);
      if (index != -1) controller.usersList[index] = updated;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Rx<User?> user = Rx(null);

      Livestream stream = controller.liveData.value;
      AppUser? hostUser = controller.firestoreController.users
          .firstWhereOrNull((element) => element.userId == stream.hostId);
      user.value = controller.usersList
          .firstWhereOrNull((element) => element.id == hostUser?.userId);

      User? users = user.value;
      bool isFollow = users?.isFollowing ?? false;
      return Row(
        spacing: 10,
        children: <Widget>[
          InkWell(
            onTap: () {
              Get.bottomSheet(
                LiveStreamUserInfoSheet(
                    isAudience: true,
                    liveUser: hostUser,
                    controller: controller),
                isScrollControlled: true,
              );
            },
            child: GradientBorder(
              strokeWidth: 2,
              gradient: StyleRes.themeGradient,
              radius: 30,
              child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: CustomImage(
                      size: const Size(40, 40),
                      image: hostUser?.profile?.addBaseURL(),
                      fit: BoxFit.cover,
                      fullName: hostUser?.fullname)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                FullNameWithBlueTick(
                  username: hostUser?.username,
                  fontSize: 13,
                  iconSize: 18,
                  fontColor: whitePure(context),
                  isVerify: hostUser?.isVerify,
                ),
                Row(
                  spacing: 5,
                  children: [
                    FittedBox(
                      child: Container(
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: ShapeDecoration(
                          color: whitePure(context).withValues(alpha: 1),
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(cornerRadius: 5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: GradientText(
                          LKey.host.tr.toUpperCase(),
                          gradient: StyleRes.themeGradient,
                          style: TextStyleCustom.unboundedBold700(fontSize: 10),
                        ),
                      ),
                    ),
                    if (users?.id != controller.myUserId)
                      InkWell(
                        onTap: () => _followUnFollowHost(controller, user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isFollow ? Colors.transparent : whitePure(context),
                            border: isFollow
                                ? Border.all(color: whitePure(context).withValues(alpha: .6))
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(isFollow ? 'Following' : '+ Follow',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isFollow ? whitePure(context) : blackPure(context))),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            Livestream liveData = controller.liveData.value;
            bool isBattleOn = liveData.type == LivestreamType.battle;
            bool isCoHost =
                (stream.coHostIds ?? []).contains(controller.myUserId);
            int count = liveData.watchingCount ?? 0;
            int watchingCount = count >= 0 ? count : 0;
            return Column(
              children: [
                Row(
                  spacing : 5,
                  children: [
                    Obx(
                          () {
                        Livestream stream = controller.liveData.value;
                        bool isBattleRunning = stream.battleType != BattleType.initiate;
                        bool isAudience =
                            stream.coHostIds?.contains(controller.myUserId) == false;

                        if (isBattleRunning && !isAudience) return const SizedBox();
                        return InkWell(
                          onTap: controller.onCloseAudienceBtn,
                          child: Container(
                            height: 20,
                            width: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: whitePure(context).withOpacity(.3),
                                border: Border.all(
                                    color: whitePure(context).withValues(alpha: 0),
                                    width: 1.5)),
                            alignment: Alignment.center,
                            child: Image.asset(AssetRes.icClose1,
                                color: whitePure(context).withValues(alpha: .9),
                                width: 18,
                                height: 18),
                          ),
                        );
                      },
                    ),
                    Image.asset(AssetRes.livestream)
                  ],
                ),
                Row(
                  spacing: 5,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13,vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: blackPure(context).withValues(alpha: .3),
                        border: Border.all(
                            color: whitePure(context).withValues(alpha: .7)),
                      ),
                      child: Row(
                        children: [
                          Image.asset(AssetRes.icEye_2, height: 15, width: 15,color: Colors.greenAccent,),
                          const SizedBox(width: 4),
                          Text(
                            watchingCount.numberFormat,
                            style: TextStyleCustom.outFitMedium500(
                                color: whitePure(context)),
                          ),
                        ],
                      ),
                    ),
                    if (!isBattleOn && liveData.isRestrictToJoin == 0 && !isCoHost)
                      LiveStreamCircleBorderButton(
                        image: AssetRes.icVideoRequest,
                        margin: EdgeInsets.zero,
                        iconColor: whitePure(context),
                        onTap: () => controller.onVideoRequestSend(liveData),
                      ),
                    if (!isBattleOn)
                      LiveStreamCircleBorderButton(
                        size: Size(22, 22),
                        image: AssetRes.icAudience,
                        margin: EdgeInsets.zero,
                        iconColor: whitePure(context),
                        onTap: () {
                          Get.bottomSheet(const MembersSheet(isHost: false),
                              isScrollControlled: true);
                        },
                      )
                  ],
                ),
              ],
            );
          })
        ],
      );
    });
  }
}

class _BuildBottomView extends StatelessWidget {
  final LivestreamScreenController controller;

  const _BuildBottomView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Livestream data = controller.liveData.value;
      bool isBattleView = data.type == LivestreamType.battle;
      StreamView? hostView = controller.streamViews
          .firstWhereOrNull((element) => element.streamId == '${data.hostId}');
      if (isBattleView) {
        return const SizedBox();
      }
      bool isDummyLive = data.isDummyLive == 1;
      return Container(
        width: 40,
        alignment: Alignment.center,
        child: MuteUnMuteButton(
            isMute: isDummyLive
                ? controller.isPlayerMute
                : (hostView?.isMuted ?? false).obs,
            onTap: () => isDummyLive
                ? controller.togglePlayerAudioToggle()
                : controller.toggleStreamAudio(data.hostId)),
      );
    });
  }
}
