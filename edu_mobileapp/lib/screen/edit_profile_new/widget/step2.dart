import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../edit_profile_screen/edit_profile_screen_controller.dart';

class Step2 extends StatefulWidget {
  final EditProfileScreenController controller;

  const Step2({
    super.key,
    required this.controller,
  });

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDynamicField(
          label: "Username",
          hint: "Enter Username",
          controller: widget.controller.usernameController,
          isRequired: true,
          onChanged: widget.controller.checkUsernameAvailability,
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "College Name",
          hint: "Enter College Name",
          controller: widget.controller.collegeNameController,
          keyboardType: TextInputType.name,
          isRequired: true,
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicDropdown(
          label: "Highest Degree",
          isRequired: true,
          value: widget.controller.selectedHighestDegree,
          items: const ["UG", "PG", "Diploma", "Schooling"],
          hint: "Select Highest Degree",
          onChanged: (value) {
            setState(() {
              widget.controller.selectedHighestDegree = value;
            });
          },
        ),
        const SizedBox(height: 20),
        CustomDynamicDropdown(
          label: "Degree",
          isRequired: true,
          value: widget.controller.selectedDegree,
          items: const ["Bsc", "Bcom", "Btech", "BE", "Msc", "Mcom", "Mtech", "ME", "MBA", "MCA", "BCA", "PhD"],
          hint: "Select Degree",
          onChanged: (value) {
            setState(() {
              widget.controller.selectedDegree = value;
            });
          },
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          height: 78,
          label: "Full Qualification",
          hint: "Enter your Full Qualification",
          controller: widget.controller.qualificationController,
          keyboardType: TextInputType.name,
          icon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: 20),

        /// Student / Professor selection
        const Row(
          children: [
            Icon(Icons.group_rounded, color: ColorRes.primaryColor, size: 18),
            SizedBox(width: 8),
            Text(
              "Are you a Student / Professor",
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() => Row(
              spacing: 10,
              children: [
                Expanded(
                  child: roleButton(
                    text: "Student",
                    img: AssetRes.studentIcon,
                    isSelected: widget.controller.role.value == "Student",
                    onTap: () {
                      setState(() {
                        widget.controller.role.value = "Student";
                      });
                    },
                  ),
                ),
                Expanded(
                  child: roleButton(
                    text: "Professor",
                    img: AssetRes.teacherIcon,
                    isSelected: widget.controller.role.value == "Professor",
                    onTap: () {
                      setState(() {
                        widget.controller.role.value = "Professor";
                      });
                    },
                  ),
                ),
              ],
            )),
        const SizedBox(height: 20),

        /// Category / SubCategory / Topic / Language
        GetBuilder<EditProfileScreenController>(
          builder: (c) {
            return Column(
              children: [
                CustomDynamicDropdown(
                  label: "Category",
                  hint: "Select Category",
                  value: c.selectedCategory,
                  items: c.categories,
                  onChanged: c.selectCategory,
                ),
                const SizedBox(height: 20),
                CustomDynamicDropdown(
                  label: "Sub Category",
                  hint: "Select Sub Category",
                  value: c.selectedSubCategory,
                  items: c.subCategories,
                  onChanged: c.selectSubCategory,
                ),
                const SizedBox(height: 20),
                CustomDynamicDropdown(
                  label: "Topic",
                  hint: "Select Topic",
                  value: c.selectedTopic,
                  items: c.topics,
                  onChanged: c.selectTopic,
                ),
                const SizedBox(height: 20),
                CustomDynamicDropdown(
                  label: "Language",
                  hint: "Select Language",
                  value: c.selectedLanguageTitle,
                  items: c.languageTitles,
                  onChanged: c.selectLanguageTitle,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: CustomButton(
                text: "Previous",
                isPrimary: false,
                onTap: widget.controller.previous,
              ),
            ),
            Expanded(
              child: CustomButton(
                text: "Next",
                onTap: widget.controller.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

Widget roleButton(
    {required String text,
    String? img,
    required Function() onTap,
    bool isSelected = false}) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(colors: [ColorRes.primaryColor, ColorRes.orangeDark])
            : null,
        color: isSelected ? null : ColorRes.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            img!,
            fit: BoxFit.cover,
            height: 16,
            width: 16,
            color: isSelected ? Colors.white : null,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}
