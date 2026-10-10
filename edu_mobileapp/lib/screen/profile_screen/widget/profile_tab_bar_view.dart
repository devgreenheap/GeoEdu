import 'package:flutter/material.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';

class ProfileTabs extends StatelessWidget {
  final ProfileScreenController controller;

  const ProfileTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Obx(() {
        final user = controller.userData.value;
        final bool isHost = user?.isHost == 1;
        final isMe = user?.id?.toInt() == SessionManager.instance.getUserID();
        final firstName = (user?.fullname ?? '').split(' ').first;

        if (isHost) {
          final livesLabel = isMe
              ? "My Lives"
              : (firstName.isNotEmpty ? "$firstName's Lives" : "Lives");

          return TabBar(
            onTap: (value) {
              controller.userData.value?.checkIsBlocked(() {
                controller.onTabChanged(value);
                if (controller.pageController.hasClients) {
                  controller.pageController.animateToPage(
                    value,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.linear,
                  );
                }
              });
            },
            indicatorColor: const Color(0xFFFF3B30),
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            tabs: [
              Tab(text: livesLabel),
              const Tab(text: "Insights"),
            ],
          );
        }

        // Separate Gifter Dashboard Tabs
        return TabBar(
          onTap: (value) {
            controller.userData.value?.checkIsBlocked(() {
              controller.onTabChanged(value);
              if (controller.pageController.hasClients) {
                controller.pageController.animateToPage(
                  value,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.linear,
                );
              }
            });
          },
          indicatorColor: const Color(0xFFFF9500),
          indicatorWeight: 3.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded, size: 17, color: Color(0xFFFF9500)),
                  SizedBox(width: 5),
                  Text("Gifting"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFD700)),
                  SizedBox(width: 5),
                  Text("Supported Hosts"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 16),
                  SizedBox(width: 5),
                  Text("Posts"),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
