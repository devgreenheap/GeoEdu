import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/screen/edit_profile_new/widget/indicator.dart';
import 'package:geoedu/screen/edit_profile_new/widget/step-1.dart';
import 'package:geoedu/screen/edit_profile_new/widget/step2.dart';
import 'package:geoedu/screen/edit_profile_new/widget/step3.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../common/widget/custom_app_bar.dart';
import '../../common/widget/custom_image.dart';
import '../../languages/languages_keys.dart';
import '../../utilities/asset_res.dart';
import '../../utilities/theme_res.dart';

class EditProfileNewScreen extends StatefulWidget {
  const EditProfileNewScreen({super.key});

  @override
  State<EditProfileNewScreen> createState() => _EditProfileNewScreenState();
}

class _EditProfileNewScreenState extends State<EditProfileNewScreen> {
  final controller = Get.put(EditProfileScreenController((user) {}));






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          Positioned.fill(
            child: Image.asset(
              AssetRes.honeyHexBg,
              fit: BoxFit.cover,
            ),
          ),

          /// Foreground Content
          Column(children: [
            CustomAppBar(
              iconColor: ColorRes.whitePure,
              title: LKey.editProfile.tr,
            ),
            Obx(() => StepTabs(
              tabs: ["Basic Info", "Academic", "Bank Details"],
              currentStep: controller.currentStep.value,
              onChanged: (index) =>
              controller.currentStep.value = index,
            )),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ColorRes.whitePure.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Obx(() {
                        if (controller.currentStep.value == 0) {
                          return Step1(controller: controller);
                        } else if (controller.currentStep.value == 1) {
                          return Step2(controller: controller);
                        } else {
                          return Step3(controller: controller);
                        }
                      })
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: 50),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        child: const Text("Save"),
      ),
    );
  }
}
