import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Modal dialog showing live show statistics when the host ends the call,
/// matching the reference design with real-time data.
class LiveSummaryDialog extends StatelessWidget {
  final String title;
  final DateTime startTime;
  final int durationMinutes;
  final int followersCount;
  final int viewersCount;
  final int callsCount;
  final int commentsCount;
  final int premiumGiftsCount;
  final int starsEarned;
  final String endedBy;
  final VoidCallback onClose;

  const LiveSummaryDialog({
    super.key,
    required this.title,
    required this.startTime,
    required this.durationMinutes,
    required this.followersCount,
    required this.viewersCount,
    required this.callsCount,
    required this.commentsCount,
    required this.premiumGiftsCount,
    required this.starsEarned,
    this.endedBy = 'Host',
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(startTime);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2D32),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: e.g. Party Room
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFF6E00),
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),

            // Start time e.g. 03:24 PM
            Text(
              timeStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),

            // Statistics rows matching screenshot
            _buildStatRow(
              icon: Icons.access_time_rounded,
              label: 'Duration (in minutes)',
              value: '$durationMinutes',
            ),
            _buildStatRow(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Followers',
              value: '$followersCount',
            ),
            _buildStatRow(
              icon: Icons.remove_red_eye_outlined,
              label: 'Viewers',
              value: '$viewersCount',
            ),
            _buildStatRow(
              icon: Icons.add_call,
              label: 'Calls',
              value: '$callsCount',
            ),
            _buildStatRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Comments',
              value: '$commentsCount',
            ),
            _buildStatRow(
              icon: Icons.card_giftcard_rounded,
              label: 'Premium Gifts',
              value: '$premiumGiftsCount',
            ),
            _buildStatRow(
              icon: Icons.star_border_rounded,
              label: 'Stars Earned',
              value: '$starsEarned',
            ),
            _buildStatRow(
              icon: Icons.power_settings_new_rounded,
              label: 'Ended',
              value: endedBy,
              valueColor: const Color(0xFF00E676),
            ),

            const SizedBox(height: 20),

            // Close white button
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 44,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog asked when host taps to end the live show.
void showEndLiveConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'End Live',
  String cancelText = 'Cancel',
}) {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
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
                color: ColorRes.liveRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: ColorRes.liveRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      cancelText,
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
                      backgroundColor: ColorRes.liveRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      onConfirm();
                    },
                    child: Text(
                      confirmText,
                      style: const TextStyle(
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
    barrierDismissible: true,
  );
}
