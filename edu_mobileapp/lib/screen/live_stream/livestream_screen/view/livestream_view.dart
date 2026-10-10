import 'dart:async';
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
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requests_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/joined_call_user_widget.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_host_more_sheet.dart';
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
      );
    });
  }
}

class EloeloStyleLayout extends StatefulWidget {
  final LivestreamScreenController controller;

  const EloeloStyleLayout({
    super.key,
    required this.controller,
  });

  @override
  State<EloeloStyleLayout> createState() => _EloeloStyleLayoutState();
}

class _EloeloStyleLayoutState extends State<EloeloStyleLayout> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Obx(() {
      final liveData = controller.liveData.value;
      final hostId = liveData.hostId;
      final hostIdStr = hostId?.toString() ?? '';
      final roomIdStr = liveData.roomID ?? '';
      final streamViews = controller.streamViews;

      // 1. Identify Host StreamView
      StreamView? hostStream = streamViews.firstWhereOrNull(
        (s) =>
            (roomIdStr.isNotEmpty && s.streamId == roomIdStr) ||
            (hostIdStr.isNotEmpty && s.streamId == hostIdStr),
      );
      if (hostStream == null && streamViews.isNotEmpty) {
        hostStream = streamViews.first;
      }

      // If no host stream is ready yet, display joining placeholder
      if (hostStream == null) {
        final hostUser = liveData.hostUser ??
            controller.firestoreController.users
                .firstWhereOrNull((u) => u.userId == hostId);
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

      return Stack(
        children: [
          // 1. Full-screen host video background
          Positioned.fill(
            child: LiveStreamUserView(
              isNameAndSpeakerVisible: false,
              controller: controller,
              streamingView: hostStream,
            ),
          ),
        ],
      );
    });
  }
}

Widget buildColumnAcceptCallCard(
    BuildContext context, LivestreamScreenController controller, double width) {
  return Obx(() {
    final pendingCount = controller.requestList.length;
    return GestureDetector(
      onTap: () {
        CallRequestsSheet.show(context);
      },
      child: Container(
        width: width,
        height: 98,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: Colors.white.withValues(alpha: 0.75),
            strokeWidth: 1.5,
            radius: 14,
            dash: 5,
            gap: 4,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(height: 3),
                Text(
                  pendingCount > 0
                      ? 'Accept Call ($pendingCount)'
                      : 'Accept Call',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}

class ParticipantVideoCard extends StatefulWidget {
  final LivestreamScreenController controller;
  final int userId;
  final StreamView? streamingView;
  final bool isMe;
  final bool bannerDismissed;
  final VoidCallback? onDismissBanner;
  final double width;
  final double height;

  const ParticipantVideoCard({
    super.key,
    required this.controller,
    required this.userId,
    this.streamingView,
    this.isMe = false,
    this.bannerDismissed = false,
    this.onDismissBanner,
    this.width = 104.0,
    this.height = 128.0,
  });

  @override
  State<ParticipantVideoCard> createState() => _ParticipantVideoCardState();
}

class _ParticipantVideoCardState extends State<ParticipantVideoCard> {
  bool _bannerDismissed = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _bannerDismissed = widget.bannerDismissed ||
        widget.controller.hasDismissedJoinCallBanner.value;
    if (widget.isMe && !_bannerDismissed) {
      _startAutoDismissTimer();
    }
  }

  @override
  void didUpdateWidget(ParticipantVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bannerDismissed && !_bannerDismissed) {
      _dismissBanner();
    } else if (widget.isMe &&
        !oldWidget.isMe &&
        !_bannerDismissed &&
        !widget.controller.hasDismissedJoinCallBanner.value) {
      _startAutoDismissTimer();
    }
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      _dismissBanner();
    });
  }

  void _dismissBanner() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (widget.isMe) {
      widget.controller.hasDismissedJoinCallBanner.value = true;
    }
    if (mounted && !_bannerDismissed) {
      setState(() {
        _bannerDismissed = true;
      });
      widget.onDismissBanner?.call();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;
      final userId = widget.userId;
      final streamingView = widget.streamingView;
      final isMe = widget.isMe;
      final width = widget.width;
      final height = widget.height;

      final state = controller.liveUsersStates
          .firstWhereOrNull((element) => element.userId == userId);
      final user = controller.firestoreController.users
          .firstWhereOrNull((u) => u.userId == userId);

      final isAudioOff = isMe
          ? (!controller.isAudioOn.value ||
              state?.audioStatus == VideoAudioStatus.offByMe ||
              state?.audioStatus == VideoAudioStatus.offByHost)
          : (state?.audioStatus == VideoAudioStatus.offByMe ||
              state?.audioStatus == VideoAudioStatus.offByHost);
      final isVideoOff = isMe
          ? (!controller.isVideoOn.value ||
              state?.videoStatus == VideoAudioStatus.offByMe ||
              state?.videoStatus == VideoAudioStatus.offByHost)
          : (state?.videoStatus == VideoAudioStatus.offByMe ||
              state?.videoStatus == VideoAudioStatus.offByHost);

      final userName = isMe
          ? (controller.myUser.value?.fullname ??
              controller.myUser.value?.username ??
              "You")
          : (user?.fullname ?? user?.username ?? "User $userId");
      final userPhoto = isMe
          ? controller.myUser.value?.profilePhoto?.addBaseURL()
          : user?.profile?.addBaseURL();

      final isConnecting = streamingView == null;
      final isEnlarged =
          controller.isHost && controller.enlargedCoHostUserId.value == userId;
      final targetWidth = isEnlarged ? 144.0 : width;
      final targetHeight = isEnlarged ? 176.0 : height;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticManager.shared.light();
              if (isMe) {
                LiveHostMoreSheet.show(
                  context: context,
                  controller: controller,
                  onShare: () {},
                );
              } else if (controller.isHost) {
                if (controller.enlargedCoHostUserId.value != userId) {
                  // 1st click: enlarge this user's video card slightly!
                  controller.enlargedCoHostUserId.value = userId;
                } else {
                  // 2nd click: show options menu!
                  showHostParticipantControlMenu(
                    context: context,
                    controller: controller,
                    userId: userId,
                    user: user,
                    state: state,
                  );
                }
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
              curve: Curves.easeOutBack,
              width: targetWidth,
              height: targetHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1E28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnlarged
                      ? const Color(0xFFFFB300)
                      : Colors.white.withValues(alpha: 0.22),
                  width: isEnlarged ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isEnlarged
                        ? const Color(0xFFFFB300).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.45),
                    blurRadius: isEnlarged ? 16 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // 1. Video Stream or Placeholder / Connecting
                    Positioned.fill(
                      child: (isVideoOff || isConnecting)
                          ? Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.9,
                                  colors: [
                                    Color(0xFF2C3243),
                                    Color(0xFF13151D)
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomImage(
                                      size: const Size(44, 44),
                                      image: userPhoto,
                                      fullName: userName,
                                      radius: 22,
                                      strokeWidth: 1.8,
                                      strokeColor: const Color(0xFFFFB300),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.55),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isConnecting && !isVideoOff) ...[
                                            const SizedBox(
                                              width: 8,
                                              height: 8,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xFFFFB300)),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Connecting...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.videocam_off_rounded,
                                              color: Colors.white70,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 3),
                                            const Text(
                                              'Video Off',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : streamingView.streamView,
                    ),

                    // 2. Top-Right Indicator / Chevron / End Call
                    Positioned(
                      top: 6,
                      right: 6,
                      child: isMe
                          ? GestureDetector(
                              onTap: () {
                                HapticManager.shared.light();
                                controller.closeCoHostStream(userId);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF3B30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                HapticManager.shared.light();
                                if (controller.isHost) {
                                  showHostParticipantControlMenu(
                                    context: context,
                                    controller: controller,
                                    userId: userId,
                                    user: user,
                                    state: state,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                    ),

                    if (isEnlarged)
                      Positioned(
                        bottom: 22,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFFB300), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  color: Color(0xFFFFB300), size: 10),
                              SizedBox(width: 3),
                              Text(
                                'Tap for options',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 3. Bottom controls (for Self) OR Bottom Name Overlay (for Others)
                    if (isMe)
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Interactive Mic toggle
                            GestureDetector(
                              onTap: () {
                                HapticManager.shared.light();
                                controller.toggleMic(state);
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isAudioOff
                                      ? const Color(0xFFFF3B30)
                                      : const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isAudioOff
                                      ? Icons.mic_off_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),

                            // Interactive Camera Flip
                            GestureDetector(
                              onTap: () {
                                HapticManager.shared.light();
                                controller.toggleFlipCamera();
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flip_camera_ios_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Bottom User Name Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 28, right: 6, top: 12, bottom: 4),
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

                      // Bottom-left Microphone Status Badge
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isAudioOff
                                ? const Color(0xFFD32F2F)
                                    .withValues(alpha: 0.95)
                                : Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.3),
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
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 4. Purple Info Banner for Self (if not dismissed)
          if (isMe) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              ),
              child: (!_bannerDismissed &&
                      !controller.hasDismissedJoinCallBanner.value)
                  ? TapRegion(
                      key: const ValueKey('purple_banner_region'),
                      groupId: 'joined_call_banner_${widget.userId}',
                      behavior: HitTestBehavior.translucent,
                      onTapOutside: (PointerDownEvent event) {
                        _dismissBanner();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildPurpleInfoBanner(),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty_banner')),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildPurpleInfoBanner() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        Positioned(
          top: -6,
          right: 24,
          child: CustomPaint(
            size: const Size(14, 7),
            painter: SpeechBeakPainter(color: const Color(0xFF991EEB)),
          ),
        ),
        Container(
          width: 248,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF991EEB),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF991EEB).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have joined the call, Start talking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _dismissBanner();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.portrait_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Show your face to stay visible on the live call',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}



void showHostParticipantControlMenu({
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
                showKickConfirmationDialog(context, controller, userId, userName);
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

void showKickConfirmationDialog(
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_off_rounded,
                      color: Color(0xFFFF1744),
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Muted',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

