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

        // 2. Vertical Call Slots column under "Lives >" at top-right
        Positioned(
          right: 10,
          top: MediaQuery.of(context).padding.top + 80,
          child: Obx(() {
            final liveData = controller.liveData.value;
            final isRestricted = liveData.isRestrictToJoin != 0;
            final showJoinSlot = (controller.isHost || !isRestricted) && members.length < 3;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                  members.length,
                  (index) => SidebarMemberTile(
                    controller: controller,
                    streamingView: members[index],
                  ),
                ),
                if (showJoinSlot)
                  _JoinCallSlot(controller: controller),
              ],
            );
          }),
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
      margin: const EdgeInsets.only(bottom: 6),
      height: 78,
      width: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video stream or avatar
            Positioned.fill(
              child: LiveStreamUserView(
                isNameAndSpeakerVisible: false,
                controller: controller,
                streamingView: streamingView,
              ),
            ),

            // Top-right chevron / minimize icon
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

            // Bottom-left mic status badge
            Obx(() {
              final state = controller.liveUsersStates.firstWhereOrNull(
                  (element) =>
                      element.userId == int.tryParse(streamingView.streamId));
              final isAudioOn = state?.audioStatus == VideoAudioStatus.on;

              return Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAudioOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: isAudioOn ? Colors.white : const Color(0xFFFF1744),
                    size: 11,
                  ),
                ),
              );
            }),

            // Bottom user name gradient strip
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  ),
                ),
                child: Text(
                  controller.firestoreController.users
                          .firstWhereOrNull((u) => u.userId.toString() == streamingView.streamId)
                          ?.fullname ??
                      "User",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCallSlot extends StatelessWidget {
  final LivestreamScreenController controller;

  const _JoinCallSlot({required this.controller});

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
        margin: const EdgeInsets.only(bottom: 6),
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: Colors.white.withValues(alpha: 0.7),
            strokeWidth: 1.5,
            radius: 12,
            dash: 5,
            gap: 4,
          ),
          child: Stack(
            children: [
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_call_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Join Call',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Blue badge on top-right corner
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  alignment: Alignment.center,
                  child: Obx(() {
                    final count = controller.isHost
                        ? (controller.requestList.isNotEmpty ? controller.requestList.length : 1)
                        : 1;
                    return Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
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

      // CRITICAL FIX: Only hide video if camera is explicitly turned off.
      // Default / null state must keep video visible so host video is not blocked
      // by the blurred avatar placeholder while syncing with Firestore.
      final bool isVideoOff = state?.videoStatus == VideoAudioStatus.offByMe ||
          state?.videoStatus == VideoAudioStatus.offByHost;
      final bool isAudioOff = state?.audioStatus == VideoAudioStatus.offByMe ||
          state?.audioStatus == VideoAudioStatus.offByHost;
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

