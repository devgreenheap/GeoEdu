import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/live_stream_user_info_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requested_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/utilities/asset_res.dart';
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

      final hostIndex = views.indexWhere(
          (v) => v.streamId == hostId || v.streamId == (stream.roomID ?? ''));
      if (hostIndex != -1 && hostIndex != 0) {
        final hostView = views.removeAt(hostIndex);
        views.insert(0, hostView);
      }

      if (views.isEmpty) {
        final hostUser = stream.hostUser ??
            controller.firestoreController.users
                .firstWhereOrNull((u) => u.userId == stream.hostId);
        final hostName = hostUser?.fullname ?? hostUser?.username ?? 'Host';
        final hostPhoto = hostUser?.profile?.addBaseURL();

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomImage(
                size: const Size(84, 84),
                image: hostPhoto,
                radius: 42,
                strokeWidth: 2.5,
                strokeColor: const Color(0xFFFFB300),
                fullName: hostName,
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Joining live video call...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return EloeloStyleLayout(
        controller: controller,
        streamViews: views,
      );
    });
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
    if (streamViews.isEmpty) return const SizedBox.shrink();

    final hostIdStr = controller.liveData.value.hostId?.toString() ?? '';
    final roomIdStr = controller.liveData.value.roomID ?? '';

    // Identify the host stream reliably, falling back to index 0
    final host = streamViews.firstWhere(
      (s) =>
          (roomIdStr.isNotEmpty && s.streamId == roomIdStr) ||
          (hostIdStr.isNotEmpty && s.streamId == hostIdStr),
      orElse: () => streamViews.first,
    );
    final members = streamViews.where((s) => s != host).toList();

    return Stack(
      children: [
        // 1. Full-screen host video background
        Positioned.fill(
          child: LiveStreamUserView(
            isNameAndSpeakerVisible: false,
            controller: controller,
            streamingView: host,
          ),
        ),

        // 2. Large, prominent Participant Video Cards row (Matching Reference Image 2)
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).padding.top + 74,
          child: Obx(() {
            final liveData = controller.liveData.value;
            final isRestricted = liveData.isRestrictToJoin != 0;
            final showJoinSlot =
                (controller.isHost || !isRestricted) && members.length < 8;

            // Responsive card sizing: 1 participant -> larger card; multiple -> properly sized cards
            final double cardWidth = members.length <= 1 ? 116.0 : 108.0;
            final double cardHeight = members.length <= 1 ? 136.0 : 126.0;

            if (members.isEmpty && !showJoinSlot) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: cardHeight + 10,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                            members.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ParticipantVideoCard(
                                controller: controller,
                                streamingView: members[index],
                                width: cardWidth,
                                height: cardHeight,
                              ),
                            ),
                          ),
                          if (showJoinSlot)
                            _JoinCallSlot(
                              controller: controller,
                              width: cardWidth,
                              height: cardHeight,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class ParticipantVideoCard extends StatelessWidget {
  final LivestreamScreenController controller;
  final StreamView streamingView;
  final double width;
  final double height;

  const ParticipantVideoCard({
    super.key,
    required this.controller,
    required this.streamingView,
    this.width = 108.0,
    this.height = 126.0,
  });

  @override
  Widget build(BuildContext context) {
    final streamUserId = int.tryParse(streamingView.streamId);

    return Obx(() {
      final state = controller.liveUsersStates.firstWhereOrNull(
          (element) => element.userId == streamUserId);
      final user = controller.firestoreController.users.firstWhereOrNull(
          (u) => u.userId.toString() == streamingView.streamId);

      final isAudioOff = state?.audioStatus == VideoAudioStatus.offByMe ||
          state?.audioStatus == VideoAudioStatus.offByHost;
      final isVideoOff = state?.videoStatus == VideoAudioStatus.offByMe ||
          state?.videoStatus == VideoAudioStatus.offByHost;

      final userName = user?.fullname ?? user?.username ?? "User";
      final userPhoto = user?.profile?.addBaseURL();

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticManager.shared.light();
          if (controller.isHost) {
            _showHostParticipantControlMenu(
              context: context,
              controller: controller,
              userId: streamUserId ?? 0,
              user: user,
              state: state,
            );
          } else {
            if (user != null) {
              Get.bottomSheet(
                LiveStreamUserInfoSheet(
                  isAudience: true,
                  liveUser: user,
                  controller: controller,
                ),
                isScrollControlled: true,
              );
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Video Stream or Avatar Placeholder (When camera disabled/turned off)
                Positioned.fill(
                  child: isVideoOff
                      ? Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.9,
                              colors: [Color(0xFF2C3243), Color(0xFF13151D)],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomImage(
                                  size: const Size(48, 48),
                                  image: userPhoto,
                                  fullName: userName,
                                  radius: 24,
                                  strokeWidth: 1.8,
                                  strokeColor: const Color(0xFFFFB300),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.videocam_off_rounded,
                                        color: Colors.white70,
                                        size: 11,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Video Off',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : streamingView.streamView,
                ),

                // 2. Top-left Chevron Icon (matching Reference Image 2)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),

                // 3. Bottom-right Microphone Status Badge (matching Reference Image 2)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isAudioOff
                          ? const Color(0xFFD32F2F).withValues(alpha: 0.95)
                          : const Color(0xFF2E7D32).withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isAudioOff
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),

                // 4. Bottom User Name Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 7, right: 28, top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Text(
                      userName,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _JoinCallSlot extends StatelessWidget {
  final LivestreamScreenController controller;
  final double width;
  final double height;

  const _JoinCallSlot({
    required this.controller,
    this.width = 108.0,
    this.height = 126.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticManager.shared.light();
        if (controller.isHost) {
          Get.bottomSheet(
            const MembersSheet(isHost: true),
            isScrollControlled: true,
          );
        } else {
          final isCoHost = (controller.liveData.value.coHostIds ?? [])
              .contains(controller.myUserId);
          if (isCoHost) {
            controller.toggleMic(null);
          } else {
            final myState = controller.liveUsersStates
                .firstWhereOrNull((u) => u.userId == controller.myUserId);
            final isRequested =
                myState?.type == LivestreamUserType.requested;
            if (isRequested) {
              CallRequestedSheet.show(context);
            } else {
              controller.onVideoRequestSend(controller.liveData.value);
            }
          }
        }
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: Colors.white.withValues(alpha: 0.7),
            strokeWidth: 1.5,
            radius: 16,
            dash: 5,
            gap: 4,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.video_call_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join Call',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Request count badge on top-right corner
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  alignment: Alignment.center,
                  child: Obx(() {
                    final count = controller.isHost
                        ? (controller.requestList.isNotEmpty ? controller.requestList.length : 1)
                        : 1;
                    return Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showHostParticipantControlMenu({
  required BuildContext context,
  required LivestreamScreenController controller,
  required int userId,
  required AppUser? user,
  required LivestreamUserState? state,
}) {
  final userName = user?.fullname ?? user?.username ?? 'Participant';
  final userPhoto = user?.profile?.addBaseURL();
  final isAudioMuted = state?.audioStatus == VideoAudioStatus.offByMe ||
      state?.audioStatus == VideoAudioStatus.offByHost;
  final isVideoOff = state?.videoStatus == VideoAudioStatus.offByMe ||
      state?.videoStatus == VideoAudioStatus.offByHost;

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E212B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // User header info
            Row(
              children: [
                CustomImage(
                  size: const Size(48, 48),
                  image: userPhoto,
                  fullName: userName,
                  radius: 24,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFFFFB300),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          // Mic status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isAudioMuted
                                  ? const Color(0xFFD32F2F).withValues(alpha: 0.2)
                                  : const Color(0xFF2E7D32).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAudioMuted
                                    ? const Color(0xFFD32F2F).withValues(alpha: 0.6)
                                    : const Color(0xFF2E7D32).withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAudioMuted
                                      ? Icons.mic_off_rounded
                                      : Icons.mic_rounded,
                                  size: 11,
                                  color: isAudioMuted
                                      ? const Color(0xFFFF5252)
                                      : const Color(0xFF69F0AE),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isAudioMuted ? 'Mic Muted' : 'Mic Active',
                                  style: TextStyle(
                                    color: isAudioMuted
                                        ? const Color(0xFFFF5252)
                                        : const Color(0xFF69F0AE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Video status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isVideoOff
                                  ? const Color(0xFFE65100).withValues(alpha: 0.2)
                                  : const Color(0xFF2E7D32).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isVideoOff
                                    ? const Color(0xFFE65100).withValues(alpha: 0.6)
                                    : const Color(0xFF2E7D32).withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVideoOff
                                      ? Icons.videocam_off_rounded
                                      : Icons.videocam_rounded,
                                  size: 11,
                                  color: isVideoOff
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFF69F0AE),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isVideoOff ? 'Video Off' : 'Video Active',
                                  style: TextStyle(
                                    color: isVideoOff
                                        ? const Color(0xFFFFB74D)
                                        : const Color(0xFF69F0AE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),

            // 1. Mute / Unmute
            _buildHostControlTile(
              icon: isAudioMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
              iconColor: isAudioMuted
                  ? const Color(0xFF69F0AE)
                  : const Color(0xFFFFB300),
              title: isAudioMuted ? 'Unmute User' : 'Mute User',
              subtitle: isAudioMuted
                  ? 'Allow user to speak in the live room'
                  : "Mute user's microphone for all listeners",
              onTap: () {
                Get.back();
                HapticManager.shared.light();
                controller.hostMuteUser(userId, !isAudioMuted);
              },
            ),

            // 2. Turn Video Off / On
            _buildHostControlTile(
              icon: isVideoOff
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              iconColor: isVideoOff
                  ? const Color(0xFF69F0AE)
                  : const Color(0xFFFFB300),
              title: isVideoOff ? 'Turn On Video' : 'Turn Off Video',
              subtitle: isVideoOff
                  ? 'Enable user camera'
                  : 'Disable user camera and display profile avatar',
              onTap: () {
                Get.back();
                HapticManager.shared.light();
                controller.hostToggleUserVideo(userId, !isVideoOff);
              },
            ),

            // 3. Remove / Kick User
            _buildHostControlTile(
              icon: Icons.person_remove_rounded,
              iconColor: const Color(0xFFFF3B30),
              title: 'Remove / Kick User',
              titleColor: const Color(0xFFFF5252),
              subtitle: 'Disconnect user and remove them from the call',
              onTap: () {
                Get.back();
                _showKickConfirmationDialog(context, controller, userId, userName);
              },
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _buildHostControlTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Color? titleColor,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 22),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: titleColor ?? Colors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Colors.white54, fontSize: 11.5),
    ),
    trailing: const Icon(Icons.arrow_forward_ios_rounded,
        color: Colors.white24, size: 14),
    onTap: onTap,
  );
}

void _showKickConfirmationDialog(
  BuildContext context,
  LivestreamScreenController controller,
  int userId,
  String userName,
) {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1E212B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: Color(0xFFFF3B30),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Remove $userName?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to remove $userName from the live call? They will be disconnected from the video call.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      HapticManager.shared.medium();
                      controller.hostKickUser(userId);
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedRRectPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.5,
    this.dash = 5.0,
    this.gap = 4.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
            size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(radius),
      ));

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dash > metric.length)
            ? metric.length - distance
            : dash;
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap ||
      oldDelegate.radius != radius;
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
      final streamIdStr = streamingView?.streamId ?? '';
      final streamUserId = int.tryParse(streamIdStr);
      final isHost = streamIdStr == controller.liveData.value.roomID ||
          (controller.liveData.value.hostId != null &&
              (streamUserId == controller.liveData.value.hostId ||
                  streamIdStr == controller.liveData.value.hostId.toString()));

      LivestreamUserState? state = controller.liveUsersStates.firstWhereOrNull(
          (element) =>
              (streamUserId != null && element.userId == streamUserId) ||
              (isHost && element.userId == controller.liveData.value.hostId));

      AppUser? liveUser = controller.firestoreController.users.firstWhereOrNull(
          (element) =>
              (streamUserId != null && element.userId == streamUserId) ||
              (isHost && element.userId == controller.liveData.value.hostId));
      if (liveUser == null && isHost) {
        liveUser = controller.liveData.value.hostUser;
      }

      final bool isMyOwnStream = (isHost && controller.myUserId == controller.liveData.value.hostId) ||
          (streamUserId != null && streamUserId == controller.myUserId);
      final bool isVideoOff = isMyOwnStream
          ? (!controller.isVideoOn.value ||
              state?.videoStatus == VideoAudioStatus.offByMe ||
              state?.videoStatus == VideoAudioStatus.offByHost)
          : (state?.videoStatus == VideoAudioStatus.offByMe ||
              state?.videoStatus == VideoAudioStatus.offByHost);
      final bool isAudioOff = isMyOwnStream
          ? (!controller.isAudioOn.value ||
              state?.audioStatus == VideoAudioStatus.offByMe ||
              state?.audioStatus == VideoAudioStatus.offByHost)
          : (state?.audioStatus == VideoAudioStatus.offByMe ||
              state?.audioStatus == VideoAudioStatus.offByHost);
      final bool isAudioOn = !isAudioOff;

      return Stack(
        children: [
          if (streamingView != null) streamingView!.streamView,
          if (isVideoOff)
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
                    double width =
                        ((constraints.maxWidth * 45) / 100).clamp(110.0, 160.0);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFB300),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB300)
                                    .withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CustomImage(
                            size: Size(width, width),
                            image: liveUser?.profile?.addBaseURL(),
                            fullName: liveUser?.fullname,
                            radius: width / 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Animated purple equalizer soundwave bars (matching Photo 1)
                        if (isAudioOn)
                          const _AnimatedPurpleSoundwave()
                        else
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFFF1744), width: 1.2),
                            ),
                            child: const Icon(
                              Icons.mic_off_rounded,
                              color: Color(0xFFFF1744),
                              size: 18,
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          if (!isVideoOff && isAudioOff)
            Align(
                alignment: Alignment.center,
                child: Image.asset(
                  AssetRes.icMicOff,
                  height: 25,
                  width: 25,
                  color: whitePure(context).withValues(alpha: .6),
                )),
          if (isNameAndSpeakerVisible && streamingView != null)
            _buildUserInfoOverlay(context,
                streamView: streamingView!,
                state: Rx<LivestreamUserState?>(state),
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
              onTap: () {
                if (liveUser != null) {
                  _showUserActionSheet(liveUser, state);
                }
              },
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

// -------------------------------------------------------------
// Animated Purple Equalizer Soundwave Bars
// -------------------------------------------------------------
class _AnimatedPurpleSoundwave extends StatefulWidget {
  const _AnimatedPurpleSoundwave();

  @override
  State<_AnimatedPurpleSoundwave> createState() =>
      _AnimatedPurpleSoundwaveState();
}

class _AnimatedPurpleSoundwaveState extends State<_AnimatedPurpleSoundwave>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final t = _animController.value * 2 * math.pi;
        final h1 = 12.0 + 8.0 * (0.5 + 0.5 * math.sin(t));
        final h2 = 14.0 + 14.0 * (0.5 + 0.5 * math.sin(t + 1.2));
        final h3 = 18.0 + 18.0 * (0.5 + 0.5 * math.sin(t + 2.4));
        final h4 = 14.0 + 14.0 * (0.5 + 0.5 * math.sin(t + 3.6));
        final h5 = 12.0 + 8.0 * (0.5 + 0.5 * math.sin(t + 4.8));

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBar(h1),
            const SizedBox(width: 4),
            _buildBar(h2),
            const SizedBox(width: 4),
            _buildBar(h3),
            const SizedBox(width: 4),
            _buildBar(h4),
            const SizedBox(width: 4),
            _buildBar(h5),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 4.5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

