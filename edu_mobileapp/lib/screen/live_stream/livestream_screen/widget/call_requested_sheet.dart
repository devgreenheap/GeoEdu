import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';

class CallRequestedSheet extends StatelessWidget {
  final VoidCallback? onViewRequests;

  const CallRequestedSheet({super.key, this.onViewRequests});

  static void show(BuildContext context, {VoidCallback? onViewRequests}) {
    Get.bottomSheet(
      CallRequestedSheet(onViewRequests: onViewRequests),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF141418),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small top handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Green check circle
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF34C759),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),

          // "Call Requested!" Title
          const Text(
            'Call Requested!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Your name has been added to the list',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Orange "View Requests" button
          GestureDetector(
            onTap: () {
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
                color: const Color(0xFFFF5500),
                borderRadius: BorderRadius.circular(24),
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
