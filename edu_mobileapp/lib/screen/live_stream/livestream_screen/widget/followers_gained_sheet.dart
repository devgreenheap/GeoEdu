import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';

class FollowersGainedSheet extends StatelessWidget {
  final LivestreamScreenController controller;

  const FollowersGainedSheet({
    super.key,
    required this.controller,
  });

  static void show(BuildContext context, LivestreamScreenController controller) {
    HapticManager.shared.light();
    Get.bottomSheet(
      FollowersGainedSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.48,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF20232B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Followers Gained"
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Followers Gained',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticManager.shared.light();
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content: Empty State or Followers List
          Expanded(
            child: Obx(() {
              final followerIds =
                  controller.hostUserState?.followersGained ?? [];

              if (followerIds.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: followerIds.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 16,
                  thickness: 0.6,
                  color: Color(0xFF2C303B),
                ),
                itemBuilder: (context, index) {
                  final userId = followerIds[index];
                  final AppUser? user = controller.firestoreController.users
                      .firstWhereOrNull((u) => u.userId == userId);

                  final fullname =
                      user?.fullname ?? user?.username ?? 'User $userId';
                  final photoUrl = user?.profile?.addBaseURL();

                  return Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? CustomImage(
                                image: photoUrl,
                                size: const Size(46, 46),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.white12,
                                child: const Icon(Icons.person,
                                    color: Colors.white70),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fullname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Followed during live',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_alt_outlined,
            size: 78,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 20),
          const Text(
            'Followers gained in this live\nwill be listed here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
