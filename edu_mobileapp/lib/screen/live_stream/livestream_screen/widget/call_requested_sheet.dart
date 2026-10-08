import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';

class CallRequestedSheet extends StatelessWidget {
  final VoidCallback? onViewRequests;

  const CallRequestedSheet({super.key, this.onViewRequests});

  static void show(BuildContext context, {VoidCallback? onViewRequests}) {
    HapticManager.shared.light();
    Get.bottomSheet(
      CallRequestedSheet(onViewRequests: onViewRequests),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1E28),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Confetti celebration particles across the top area (matching Reference Image 2)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 90,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              child: CustomPaint(
                painter: _ConfettiHeaderPainter(),
              ),
            ),
          ),

          // 2. Main Sheet Content
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top small pill handle bar
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Green Glowing Check Circle (matching Reference Image 2)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title: "Call Requested!"
                  const Text(
                    'Call Requested!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle: "Your name has been added to the list"
                  Text(
                    'Your name has been added to the list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vibrant Orange Pill Button: "View Requests" (matching Reference Image 2)
                  GestureDetector(
                    onTap: () {
                      HapticManager.shared.light();
                      Get.back();
                      if (onViewRequests != null) {
                        onViewRequests!();
                      } else {
                        Get.bottomSheet(
                          const MembersSheet(isHost: false),
                          isScrollControlled: true,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5226), Color(0xFFFF3D00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF3D00).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'View Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFF5722),
      const Color(0xFFFFD600),
      const Color(0xFF00E676),
      const Color(0xFF2979FF),
      const Color(0xFFFF4081),
      Colors.white,
      const Color(0xFFFF9100),
      const Color(0xFFE040FB),
    ];

    final particles = [
      [0.08, 0.25, 6.0, 3.0, 0.4, 0],
      [0.14, 0.45, 4.0, 4.0, 0.8, 1],
      [0.22, 0.20, 7.0, 3.5, -0.5, 2],
      [0.28, 0.55, 5.0, 2.5, 0.3, 3],
      [0.35, 0.30, 6.0, 3.0, -0.6, 4],
      [0.42, 0.50, 3.5, 3.5, 0.9, 5],
      [0.50, 0.24, 5.5, 2.8, -0.2, 6],
      [0.58, 0.48, 6.0, 3.0, 0.5, 7],
      [0.65, 0.26, 4.5, 4.5, -0.7, 1],
      [0.72, 0.56, 7.0, 3.2, 0.4, 0],
      [0.78, 0.22, 5.0, 2.5, -0.4, 2],
      [0.85, 0.46, 6.5, 3.0, 0.7, 3],
      [0.92, 0.30, 4.0, 4.0, -0.8, 4],
      [0.10, 0.70, 5.0, 2.5, 0.6, 6],
      [0.18, 0.80, 6.0, 3.0, -0.3, 0],
      [0.82, 0.75, 5.5, 2.8, 0.5, 1],
      [0.90, 0.65, 4.5, 4.5, -0.5, 2],
    ];

    for (final p in particles) {
      final x = (p[0] as double) * size.width;
      final y = (p[1] as double) * size.height;
      final w = p[2] as double;
      final h = p[3] as double;
      final angle = p[4] as double;
      final color = colors[(p[5] as int) % colors.length];

      final paint = Paint()..color = color.withValues(alpha: 0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
