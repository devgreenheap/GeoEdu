import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';

class LiveHostMoreSheet extends StatelessWidget {
  final LivestreamScreenController controller;
  final VoidCallback onShare;

  const LiveHostMoreSheet({
    super.key,
    required this.controller,
    required this.onShare,
  });

  static void show({
    required BuildContext context,
    required LivestreamScreenController controller,
    required VoidCallback onShare,
  }) {
    HapticManager.shared.light();
    Get.bottomSheet(
      LiveHostMoreSheet(
        controller: controller,
        onShare: onShare,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiveHost = controller.isHost ||
        (controller.liveData.value.hostId != null &&
            controller.myUserId == controller.liveData.value.hostId);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E212A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Switch (Camera) | Mute/Unmute (Mic) | Video (Camera On/Off)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Switch Camera
                _buildActionItem(
                  icon: const Icon(
                    Icons.cameraswitch_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  label: 'Switch',
                  labelColor: Colors.white,
                  onTap: () {
                    HapticManager.shared.light();
                    controller.toggleFlipCamera();
                  },
                ),

                // 2. Mute / Unmute Microphone
                Obx(() {
                  final isMuted = !controller.isAudioOn.value;
                  return _buildActionItem(
                    icon: Icon(
                      isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                      color: isMuted ? const Color(0xFFFF5252) : Colors.white,
                      size: 30,
                    ),
                    label: isMuted ? 'Unmute' : 'Mute',
                    labelColor:
                        isMuted ? const Color(0xFFFF5252) : Colors.white,
                    onTap: () {
                      HapticManager.shared.light();
                      controller.toggleMic(null);
                    },
                  );
                }),

                // 3. Video (Camera On/Off)
                Obx(() {
                  final isVideoOff = !controller.isVideoOn.value;
                  return _buildActionItem(
                    icon: Icon(
                      isVideoOff
                          ? Icons.videocam_off_outlined
                          : Icons.videocam_outlined,
                      color: isVideoOff ? const Color(0xFFFF5252) : Colors.white,
                      size: 30,
                    ),
                    label: 'Video',
                    labelColor: isVideoOff
                        ? const Color(0xFFFF5252)
                        : Colors.white,
                    onTap: () {
                      HapticManager.shared.light();
                      controller.toggleVideo(null);
                    },
                  );
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Row 2: Share (aligned with the first column)
            Row(
              children: [
                _buildActionItem(
                  icon: Image.asset(
                    AssetRes.icWhatsapp,
                    width: 28,
                    height: 28,
                    color: Colors.white,
                  ),
                  label: 'Share',
                  labelColor: Colors.white,
                  onTap: () {
                    HapticManager.shared.light();
                    Get.back(); // close more sheet
                    onShare();
                  },
                ),
              ],
            ),

            // Auto Call with Red Dot & CupertinoSwitch (Host ONLY)
            if (isLiveHost) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Auto Call',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3D00),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Call request will be auto accepted',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  // Right Switch
                  Obx(() {
                    final isAuto =
                        controller.liveData.value.isAutoMode ?? false;
                    return CupertinoSwitch(
                      value: isAuto,
                      activeTrackColor: const Color(0xFF00E676),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      onChanged: (bool value) {
                        HapticManager.shared.light();
                        controller.toggleAutoCall(value);
                      },
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required Widget icon,
    required String label,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 76,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 36,
              child: Center(child: icon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
