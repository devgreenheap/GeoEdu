import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/live_stream_user_info_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class LivestreamView extends StatelessWidget {
  final RxList<StreamView> streamViews;
  final LivestreamScreenController controller;

  const LivestreamView(
      {super.key, required this.streamViews, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Livestream stream = controller.liveData.value;
      final hostId = stream.hostId.toString();
      final views = List<StreamView>.from(streamViews); // Optional: clone if needed

      final hostIndex = views.indexWhere((v) => v.streamId == hostId);
      if (hostIndex != -1 && hostIndex != 0) {
        final hostView = views.removeAt(hostIndex);
        views.insert(0, hostView);
      }
      int coHostCount = views.length;
      List<AppUser> liveUsers = controller.firestoreController.users;
      List<AppUser> allUsers = stream.getAllUsers(liveUsers);

      if (allUsers.isEmpty) {
        return _buildEmptyView();
      }

      if (views.isEmpty) {
        return const LoaderWidget();
      }

      // if(coHostCount == 1){
      //   return LiveStreamUserView(isNameAndSpeakerVisible: false, streamingView: views.first, controller: controller,);
      // }else{
      //  return EloeloStyleLayout(
      //    controller: controller,
      //    streamViews: views,
      //  );
      // }

      return switch (coHostCount) {
        2 => OneAndTwoUserView(controller: controller, streamViews: views,),
        3 => ThreeUserView(controller: controller, streamViews: views),
        4 => FourUserView(controller: controller, streamViews: views),
        1 => Stack(
            children: [
              LiveStreamUserView(isNameAndSpeakerVisible: false, streamingView: views.first, controller: controller,),
              if (controller.isHost) const _AcceptCallSlot(),
            ],
          ),
        _ => MultiUserGridView(controller: controller, streamViews: views),
      };
    });
  }



  Widget _buildEmptyView() {
    return Center(
        child: Text(
      'No users in livestream',
      style: TextStyleCustom.unboundedMedium500(color: Colors.white),
    ));
  }
}

/// Dashed "+ Accept Call" co-host slot shown to the host when solo — opens
/// the same real pending-requests sheet the "Calls"/"Requests" buttons use
/// (this is a separate co-host invite flow, never PK).
class _AcceptCallSlot extends StatelessWidget {
  const _AcceptCallSlot();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LivestreamScreenController>();
    return Positioned(
      right: 12,
      bottom: 160,
      child: GestureDetector(
        onTap: () => Get.bottomSheet(
            const MembersSheet(isHost: true),
            isScrollControlled: true),
        child: Obx(() => Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white54,
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white70, size: 26),
                  const SizedBox(height: 6),
                  const Text('Accept Call',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (controller.requestList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${controller.requestList.length} pending',
                          style: const TextStyle(color: Colors.orange, fontSize: 9)),
                    ),
                ],
              ),
            )),
      ),
    );
  }
}

class EloeloStyleLayout extends StatelessWidget {
  final LivestreamScreenController controller;
  final List<StreamView> streamViews;

  const EloeloStyleLayout({
    super.key,
    required this.controller,
    required this.streamViews,
  });

  @override
  Widget build(BuildContext context) {
    final host = streamViews.first;
    final members = streamViews.skip(1).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: LiveStreamUserView(
            isNameAndSpeakerVisible: false,
            controller: controller,
            streamingView: host,
          ),
        ),
        Positioned(
          right: 12,
          top: MediaQuery.of(context).padding.top + 100,
          bottom: 100,
          child: SizedBox(
            width: 110,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ...List.generate(
                    members.length,
                        (index) => SidebarMemberTile(
                      controller: controller,
                      streamingView: members[index],
                    ),
                  ),
                  _buildJoinPlaceholder(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SidebarMemberTile extends StatelessWidget {
  final LivestreamScreenController controller;
  final StreamView streamingView;

  const SidebarMemberTile({
    super.key,
    required this.controller,
    required this.streamingView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 130,
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
                child: Text(
                  // Fetching user name from controller using streamId
                  controller.firestoreController.users
                      .firstWhereOrNull((u) => u.userId.toString() == streamingView.streamId)
                      ?.fullname ?? "User",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildJoinPlaceholder(BuildContext context) {
  return InkWell(
    onTap: () {
      print("User requested to join the stage");
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 130,
      width: 110,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.7), size: 30),
          const SizedBox(height: 8),
          Text(
            "Join",
            style: TextStyleCustom.unboundedMedium500(
              color: Colors.white.withValues(alpha: 0.7),
            ).copyWith(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class MultiUserGridView extends StatelessWidget {
  final LivestreamScreenController controller;
  final List<StreamView> streamViews;

  const MultiUserGridView({
    super.key,
    required this.controller,
    required this.streamViews,
  });

  @override
  Widget build(BuildContext context) {
    int count = streamViews.length;

    // Dynamic column calculation
    int crossAxisCount = count <= 6 ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.only(top: 100),
      itemCount: streamViews.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return LiveStreamUserView(
          controller: controller,
          streamingView: streamViews[index],
        );
      },
    );
  }
}

class OneAndTwoUserView extends StatelessWidget {
  final LivestreamScreenController controller;
  final List<StreamView> streamViews;

  const OneAndTwoUserView({
    super.key,
    required this.controller,
    required this.streamViews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        streamViews.length,
        (index) => Expanded(
          child: LiveStreamUserView(
            isNameAndSpeakerVisible: index != 0,
            controller: controller,
            streamingView: streamViews[index],
          ),
        ),
      ),
    );
  }
}

class ThreeUserView extends StatelessWidget {
  final LivestreamScreenController controller;
  final List<StreamView> streamViews;

  const ThreeUserView({
    super.key,
    required this.controller,
    required this.streamViews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainUserView(streamViews.first),
        _buildSecondaryUsersRow(streamViews.sublist(1)),
      ],
    );
  }

  Widget _buildMainUserView(StreamView user) {
    return Expanded(
      child: LiveStreamUserView(
        isNameAndSpeakerVisible: false,
        controller: controller,
        streamingView: streamViews.first,
      ),
    );
  }

  Widget _buildSecondaryUsersRow(List<StreamView> streamViews) {
    return Expanded(
      child: Row(
        children: [
          for (final streamView in streamViews.take(2))
            Expanded(
              child: LiveStreamUserView(
                controller: controller,
                streamingView: streamView,
              ),
            ),
          if (streamViews.length < 2) ...[
            for (int i = 0; i < 2 - streamViews.length; i++)
              Expanded(child: _buildEmptyUserView()),
          ],
        ],
      ),
    );
  }
}

class FourUserView extends StatelessWidget {
  final LivestreamScreenController controller;
  final List<StreamView> streamViews;

  const FourUserView(
      {super.key, required this.controller, required this.streamViews});

  @override
  Widget build(BuildContext context) {
    if (streamViews.isEmpty) return _buildEmptyView();

    return Column(
      children: [
        _buildTopRow(streamViews.take(2)),
        _buildBottomRow(streamViews.skip(2)),
      ],
    );
  }

  Widget _buildTopRow(Iterable<StreamView> streamViews) {
    return Expanded(
      child: Row(
        children: [
          for (final user in streamViews.take(2))
            Expanded(
              child: LiveStreamUserView(
                  isNameAndSpeakerVisible:
                      streamViews.toList().indexOf(user) != 0,
                  controller: controller,
                  streamingView: user),
            ),
          if (streamViews.length < 2) Expanded(child: _buildEmptyUserView()),
        ],
      ),
    );
  }

  Widget _buildBottomRow(Iterable<StreamView> streamViews) {
    return Expanded(
      child: Row(
        children: [
          for (final user in streamViews.take(2))
            Expanded(
              child: LiveStreamUserView(
                controller: controller,
                streamingView: user,
              ),
            ),
          if (streamViews.length < 2)
            for (int i = 0; i < 2 - streamViews.length; i++)
              Expanded(child: _buildEmptyUserView()),
        ],
      ),
    );
  }
}

class LiveStreamUserView extends StatelessWidget {
  final bool isNameAndSpeakerVisible;
  final AlignmentGeometry? alignment;
  final StreamView? streamingView;
  final LivestreamScreenController controller;

  const LiveStreamUserView({
    super.key,
    this.isNameAndSpeakerVisible = true,
    this.alignment,
    required this.streamingView,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LivestreamUserState? state = controller.liveUsersStates.firstWhereOrNull(
          (element) =>
              element.userId == int.parse(streamingView?.streamId ?? ''));
      AppUser? liveUser = controller.firestoreController.users.firstWhereOrNull((element) =>
              element.userId == int.parse(streamingView?.streamId ?? ''));

      return Stack(
        children: [
          if (streamingView != null) streamingView!.streamView,
          if (state?.videoStatus != VideoAudioStatus.on)
            Stack(
              children: [
                CustomImage(
                    size: Size(Get.width, Get.height),
                    image: liveUser?.profile?.addBaseURL(),
                    fullName: liveUser?.fullname,
                    radius: 0),
                LayoutBuilder(
                  builder: (context, constraints) => ClipRect(
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          color: Colors.black.withValues(alpha: .5),
                        )),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: LayoutBuilder(builder: (context, constraints) {
                    double width = ((constraints.maxWidth * 50) / 100);
                    return CustomImage(
                        size: Size(width, width),
                        image: liveUser?.profile?.addBaseURL(),
                        fullName: liveUser?.fullname,
                        strokeWidth: 3);
                  }),
                ),
              ],
            ),
          if (state?.audioStatus != VideoAudioStatus.on)
            Align(
                alignment: Alignment.center,
                child: Image.asset(
                  AssetRes.icMicOff,
                  height: 25,
                  width: 25,
                  color: whitePure(context).withValues(alpha: .6),
                )),
          if (isNameAndSpeakerVisible)
            _buildUserInfoOverlay(context,
                streamView: streamingView!,
                state: state.obs,
                liveUser: liveUser,
                isMuteVisible: liveUser?.userId != controller.myUserId)
        ],
      );
    });
  }

  Widget _buildUserInfoOverlay(BuildContext context,
      {required AppUser? liveUser,
      required Rx<LivestreamUserState?> state,
      required StreamView? streamView,
      required bool isMuteVisible}) {
    return Align(
      alignment: alignment ?? AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            if (alignment != null && isMuteVisible)
              MuteUnMuteButton(
                isMute: (streamView?.isMuted ?? false).obs,
                onTap: () => controller.toggleStreamAudio(liveUser?.userId),
              ),
            FullNameWithBlueTick(
              username: liveUser?.username,
              fontColor: whitePure(context),
              fontSize: 12,
              isVerify: liveUser?.isVerify,
              onTap: () => _showUserActionSheet(liveUser!, state),
            ),
            if (alignment == null && isMuteVisible)
              MuteUnMuteButton(
                isMute: (streamView?.isMuted ?? false).obs,
                onTap: () => controller.toggleStreamAudio(liveUser?.userId),
              ),
          ],
        ),
      ),
    );
  }

  void _showUserActionSheet(AppUser user, Rx<LivestreamUserState?> state) {
    Get.bottomSheet(
      LiveStreamUserInfoSheet(
          isAudience: true, liveUser: user,
          controller: controller),
      isScrollControlled: true,
    );
  }
}

class MuteUnMuteButton extends StatelessWidget {
  final RxBool isMute;
  final VoidCallback? onTap;

  const MuteUnMuteButton({super.key, required this.isMute, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticManager.shared.light();
        onTap?.call();
      },
      child: Obx(
        () => Image.asset(
          isMute.value ? AssetRes.icSpeakerMute : AssetRes.icSpeaker,
          width: 24,
          height: 24,
          color: whitePure(context).withValues(alpha: .5),
        ),
      ),
    );
  }
}

// Helper extensions for common widgets
extension on Widget {
  Widget _buildEmptyUserView() {
    return Container(
      color: Colors.grey[800],
      child: const Center(child: Icon(Icons.person_off, color: Colors.white54)),
    );
  }

  Widget _buildEmptyView() {
    return const Center(child: Text('No users in livestream'));
  }
}
