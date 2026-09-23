import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen_controller.dart';

class BuildInterestsView extends StatelessWidget {
  final EditProfileScreenController controller;

  const BuildInterestsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.heart, color: Color(0xFFFF3B7F), size: 16),
            const SizedBox(width: 8),
            const Text('Interests',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            InkWell(
                onTap: controller.openInterestsPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF3B7F), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.pencil, color: Color(0xFFFF3B7F), size: 12),
                      SizedBox(width: 4),
                      Text('Edit',
                          style: TextStyle(
                              color: Color(0xFFFF3B7F), fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ))
          ],
        ),
        const SizedBox(height: 10),
        Obx(() {
          final interests = controller.selectedInterests;
          if (interests.isEmpty) {
            return const Text('No interests selected yet',
                style: TextStyle(color: Colors.white38, fontSize: 13));
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.only(left: 14, right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC5246D), Color(0xFF6B4FD6)],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(interest.name ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => controller.removeInterest(interest),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
