import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/utilities/color_res.dart';

class LeaderBoardBackground extends StatelessWidget {
  const LeaderBoardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: Get.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorRes.blackPure, ColorRes.cardBackground, ColorRes.surfaceBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
