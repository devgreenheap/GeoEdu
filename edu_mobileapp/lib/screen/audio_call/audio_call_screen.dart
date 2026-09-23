import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/audio_call/audio_call.dart';
import 'package:geoedu/screen/audio_call/audio_call_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

class AudioCallScreen extends StatelessWidget {
  final AudioCall call;
  final bool isCaller;

  const AudioCallScreen({
    super.key,
    required this.call,
    required this.isCaller,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AudioCallController(call: call, isCaller: isCaller),
    );

    final otherName = isCaller ? call.calleeName : call.callerName;
    final otherPhoto = isCaller ? call.calleePhoto : call.callerPhoto;

    return Scaffold(
      backgroundColor: const Color(0xFF021636),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF214f86), Color(0xFF021636)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Avatar with glow ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffB6FF52).withValues(alpha: 0.35),
                        width: 6,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xffB6FF52).withValues(alpha: 0.8),
                          width: 6,
                        ),
                      ),
                      child: CustomImage(
                        size: const Size(120, 120),
                        image: otherPhoto,
                        radius: 60,
                        fullName: otherName,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Name
              Text(
                otherName ?? 'Unknown',
                style: const TextStyle(
                  color: ColorRes.whitePure,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Status text / duration
              Obx(() {
                if (controller.isConnected.value) {
                  return Text(
                    controller.formattedDuration,
                    style: const TextStyle(
                      color: Color(0xffB6FF52),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return Text(
                  controller.callStatusText.value,
                  style: TextStyle(
                    color: ColorRes.whitePure.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                );
              }),
              const Spacer(flex: 3),
              // Gift button (only when connected)
              Obx(() => controller.isConnected.value
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _controlButton(
                        icon: Icons.card_giftcard,
                        label: 'Send Gift',
                        color: const Color(0xFFFF6B35),
                        onTap: controller.sendGift,
                      ),
                    )
                  : const SizedBox()),
              // Bottom controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    Obx(() => _controlButton(
                          icon: controller.isMuted.value
                              ? Icons.mic_off
                              : Icons.mic,
                          label: controller.isMuted.value ? 'Unmute' : 'Mute',
                          color: Colors.white.withValues(alpha: 0.2),
                          onTap: controller.toggleMute,
                        )),
                    // End call
                    _controlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      color: Colors.red,
                      size: 64,
                      onTap: controller.endCall,
                    ),
                    // Speaker button
                    Obx(() => _controlButton(
                          icon: controller.isSpeakerOn.value
                              ? Icons.volume_up
                              : Icons.volume_off,
                          label: 'Speaker',
                          color: controller.isSpeakerOn.value
                              ? const Color(0xFF477d8d)
                              : Colors.white.withValues(alpha: 0.2),
                          onTap: controller.toggleSpeaker,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    double size = 56,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ColorRes.whitePure, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: ColorRes.whitePure.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
