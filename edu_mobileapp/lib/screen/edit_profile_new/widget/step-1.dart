import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';
import 'package:geoedu/screen/edit_profile_screen/widget/build_interests_view.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../../common/widget/custom_image.dart';
import '../../edit_profile_screen/edit_profile_screen_controller.dart';

/// Basic Info step — deliberately kept to just identity/profile-type fields
/// (name, DOB, bio, gender, social links), matching the reference design.
/// Contact/address fields moved to Bank Details (KYC-style grouping);
/// account/academic-status fields moved to Academic.
class Step1 extends StatefulWidget {
  final EditProfileScreenController controller;

  const Step1({
    super.key,
    required this.controller,
  });

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Profile Image
        Center(
          child: InkWell(
            onTap: widget.controller.onChangeProfileImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [ColorRes.primaryColor, ColorRes.orangeDark],
                    ),
                  ),
                  child: Container(
                    width: 86,
                    height: 86,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Obx(
                      () => widget.controller.fileProfileImage.value != null
                          ? ClipOval(
                              child: Image.file(
                                  File(widget.controller
                                          .fileProfileImage.value?.path ??
                                      ''),
                                  fit: BoxFit.cover))
                          : ClipOval(
                              child: CustomImage(
                                size: const Size(80, 80),
                                image: widget.controller.userData.value?.profilePhoto
                                    ?.addBaseURL(),
                                fullName:
                                    widget.controller.userData.value?.fullname,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: const BoxDecoration(
                        color: ColorRes.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 2))),
                    child: const Center(
                      child: Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomDynamicField(
          label: "First Name",
          hint: "Enter First Name",
          controller: widget.controller.firstNameController,
          isRequired: true,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Last Name",
          hint: "Enter Last Name",
          controller: widget.controller.lastNameController,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),

        /// Date of Birth
        RichText(
          text: const TextSpan(
            text: "Date of Birth",
            style: TextStyle(color: kLabelLavender, fontSize: 13, fontWeight: FontWeight.w600),
            children: [TextSpan(text: " *", style: TextStyle(color: ColorRes.liveRed))],
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () async {
            await widget.controller.selectDate(context);
            setState(() {});
          },
          child: GradientPillBorder(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.controller.selectedDate == null
                          ? "Select Date"
                          : "${widget.controller.selectedDate!.day.toString().padLeft(2, '0')}/${widget.controller.selectedDate!.month.toString().padLeft(2, '0')}/${widget.controller.selectedDate!.year}",
                      style: TextStyle(
                        color: widget.controller.selectedDate == null
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: ColorRes.primaryColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Bio",
          hint: "Enter Bio",
          controller: widget.controller.bioController,
          height: 78,
          icon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: 20),

        /// Gender — inline radio pill, matching the reference
        RichText(
          text: const TextSpan(
            text: "Gender",
            style: TextStyle(color: kLabelLavender, fontSize: 13, fontWeight: FontWeight.w600),
            children: [TextSpan(text: " *", style: TextStyle(color: ColorRes.liveRed))],
          ),
        ),
        const SizedBox(height: 7),
        GradientPillBorder(
          height: 54,
          child: Row(
            children: ["Male", "Female", "Other"].map((gender) {
              final isSelected = widget.controller.selectedGender == gender;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => widget.controller.selectedGender = gender),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 18,
                        color: isSelected ? ColorRes.primaryColor : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(gender,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Instagram Handle",
          hint: "@yourusername",
          controller: widget.controller.instagramHandleController,
          icon: Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 20),

        /// Interests
        BuildInterestsView(controller: widget.controller),
        const SizedBox(height: 20),
        CustomButton(
          text: "Next",
          onTap: widget.controller.next,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
