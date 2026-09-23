import 'package:flutter/material.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

class ProfileTabs extends StatelessWidget {
  final ProfileScreenController controller;

  const ProfileTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: TabBar(
        onTap: (value) {
          controller.userData.value?.checkIsBlocked(() {
            controller.onTabChanged(value);
            controller.pageController.animateToPage(
              value,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            );
          });
        },
        indicatorColor: ColorRes.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: ColorRes.primaryColor,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        tabs: const [
          Tab(text: "My Lives"),
          Tab(text: "Insights"),
        ],
      ),
    );
  }
}
