import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/share_manager.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/screen/settings_screen/settings_screen.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Right-side vertical action column on the video-live host screen:
/// Calls (requests sheet), Themes (beauty filters), More (⋮).
class SideActionColumn extends StatelessWidget {
  final LivestreamScreenController controller;

  const SideActionColumn({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isViewVisible.value) return const SizedBox.shrink();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIcon(
            icon: Icons.call_rounded,
            label: 'Calls',
            badgeCount: controller.requestList.length,
            onTap: () => Get.bottomSheet(const MembersSheet(isHost: true), isScrollControlled: true),
          ),
          const SizedBox(height: 16),
          _ActionIcon(
            icon: Icons.face_retouching_natural_rounded,
            label: 'Themes',
            onTap: () => Get.snackbar('Themes', 'Beauty filters are not available yet.',
                snackPosition: SnackPosition.TOP, colorText: Colors.white, backgroundColor: Colors.black87),
          ),
          const SizedBox(height: 16),
          _ActionIcon(
            icon: Icons.more_vert_rounded,
            label: 'More',
            onTap: () => _showMoreSheet(context),
          ),
        ],
      );
    });
  }

  void _showMoreSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
              title: const Text('Flip Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                controller.toggleFlipCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                final hostId = controller.liveData.value.hostId;
                if (hostId != null) {
                  ShareManager.shared.shareTheContent(key: ShareKeys.user, value: hostId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                Get.to(() => SettingsScreen());
              },
            ),
            Obx(() => SwitchListTile(
                  value: LivestreamScreenController.isGiftSoundOn.value,
                  onChanged: (v) => LivestreamScreenController.isGiftSoundOn.value = v,
                  activeColor: ColorRes.primaryColor,
                  title: const Text('Gift Sound', style: TextStyle(color: Colors.white)),
                  secondary: const Icon(Icons.volume_up_rounded, color: Colors.white),
                )),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(color: ColorRes.liveRed, borderRadius: BorderRadius.circular(8)),
                    child: Text(badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
