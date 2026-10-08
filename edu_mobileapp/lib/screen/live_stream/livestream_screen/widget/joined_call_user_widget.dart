import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requested_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_host_more_sheet.dart';

// ============================================================================
// 1. Join Call / Requested Dashed Card for Viewers (Reference Image 1 & 2)
// ============================================================================
class AudienceJoinCallDashedCard extends StatelessWidget {
  final LivestreamScreenController controller;
  final double width;
  final double height;

  const AudienceJoinCallDashedCard({
    super.key,
    required this.controller,
    this.width = 84,
    this.height = 98,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myState = controller.liveUsersStates
          .firstWhereOrNull((u) => u.userId == controller.myUserId);
      final isRequested = myState?.type == LivestreamUserType.requested;

      return GestureDetector(
        onTap: () {
          HapticManager.shared.light();
          if (!isRequested) {
            controller.onVideoRequestSend(controller.liveData.value);
          } else {
            CallRequestedSheet.show(context);
          }
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(14),
          ),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: Colors.white.withValues(alpha: 0.78),
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
                  // Icon
                  if (isRequested)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  else
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 5),

                  // Label: "Join Call" or "Requested"
                  Text(
                    isRequested ? 'Requested' : 'Join Call',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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
}

// ============================================================================
// 2. Joined Caller Video Preview Card & Purple Banner (Reference Image 3)
// ============================================================================
class JoinedCallUserSection extends StatefulWidget {
  final LivestreamScreenController controller;

  const JoinedCallUserSection({
    super.key,
    required this.controller,
  });

  @override
  State<JoinedCallUserSection> createState() => _JoinedCallUserSectionState();
}

class _JoinedCallUserSectionState extends State<JoinedCallUserSection> {
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. Top-Right Video Preview Card (Matching Reference Image 3)
        _buildUserVideoCard(),

        // 2. Purple Speech-Bubble Information Banner (Matching Reference Image 3)
        if (!_bannerDismissed) ...[
          const SizedBox(height: 10),
          _buildPurpleInfoBanner(),
        ],
      ],
    );
  }

  Widget _buildUserVideoCard() {
    return Obx(() {
      final myUserId = widget.controller.myUserId;
      final myStream = widget.controller.streamViews
          .firstWhereOrNull((s) => s.streamId == '$myUserId');
      final isVideoOn = widget.controller.isVideoOn.value;
      final isAudioOn = widget.controller.isAudioOn.value;
      final myUser = widget.controller.myUser.value;

      return GestureDetector(
        onTap: () {
          HapticManager.shared.light();
          LiveHostMoreSheet.show(
            context: context,
            controller: widget.controller,
            onShare: () {},
          );
        },
        child: Container(
          width: 104,
          height: 128,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera stream or Avatar
                if (myStream != null && isVideoOn)
                  myStream.streamView
                else
                  Container(
                    color: const Color(0xFF1E212B),
                    child: Center(
                      child: CustomImage(
                        size: const Size(48, 48),
                        image: myUser?.profilePhoto?.addBaseURL(),
                        fullName: myUser?.fullname ?? myUser?.username,
                        radius: 24,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFFFFB300),
                      ),
                    ),
                  ),

                // Bottom indicators row (Green Mic on Left, Switch/Mute on Right)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mic indicator
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isAudioOn
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAudioOn
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),

                      // Camera / Flip indicator
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPurpleInfoBanner() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        // Upward pointer beak towards video card
        Positioned(
          top: -6,
          right: 28,
          child: CustomPaint(
            size: const Size(14, 7),
            painter: SpeechBeakPainter(color: const Color(0xFF991EEB)),
          ),
        ),

        // Main Purple Box
        Container(
          width: 248,
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF991EEB),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF991EEB).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Video camera icon + "You have joined the call, Start talking"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have joined the call, Start talking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _bannerDismissed = true;
                      });
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
              const SizedBox(height: 8),

              // Row 2: User silhouette icon + "Show your face to stay visible on"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.portrait_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Show your face to stay visible on',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// Custom Painters
// ----------------------------------------------------------------------------
class SpeechBeakPainter extends CustomPainter {
  final Color color;

  SpeechBeakPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 14,
    this.dash = 5,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dash > metric.length)
            ? metric.length - distance
            : dash;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
