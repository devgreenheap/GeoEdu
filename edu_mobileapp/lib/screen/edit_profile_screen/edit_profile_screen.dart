import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/edit_profile_new/widget/indicator.dart';
import 'package:geoedu/screen/edit_profile_new/widget/step-1.dart';
import 'package:geoedu/screen/edit_profile_new/widget/step2.dart';
import 'package:geoedu/screen/edit_profile_new/widget/step3.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen_controller.dart';

class EditProfileScreen extends StatelessWidget {
  final Function(User? user)? onUpdateUser;

  const EditProfileScreen({super.key, this.onUpdateUser});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileScreenController(onUpdateUser));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    LKey.editProfile.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() => StepTabs(
                tabs: const ["Basic Info", "Academic", "Bank Details"],
                currentStep: controller.currentStep.value,
                onChanged: controller.goToStep,
              )),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Obx(() {
                  if (controller.currentStep.value == 0) {
                    return Step1(controller: controller);
                  } else if (controller.currentStep.value == 1) {
                    return Step2(controller: controller);
                  } else {
                    return Step3(controller: controller);
                  }
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
