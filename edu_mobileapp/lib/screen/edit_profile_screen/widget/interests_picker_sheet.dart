import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/bottom_sheet_top_view.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen_controller.dart';

class InterestsPickerSheet extends StatefulWidget {
  final EditProfileScreenController controller;

  const InterestsPickerSheet({super.key, required this.controller});

  @override
  State<InterestsPickerSheet> createState() => _InterestsPickerSheetState();
}

class _InterestsPickerSheetState extends State<InterestsPickerSheet> {
  late Set<int> tempSelectedIds;

  @override
  void initState() {
    super.initState();
    tempSelectedIds =
        widget.controller.selectedInterests.map((e) => e.id!).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.controller.interestCatalog;

    return Container(
      decoration: const ShapeDecoration(
          color: Color(0xFF1E1E1E),
          shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.vertical(
                  top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1)))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetTopView(title: 'Select Interests'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: catalog.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text('No interests available yet',
                          style: TextStyle(color: Colors.white38)),
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: catalog.map((interest) {
                        final isSelected = tempSelectedIds.contains(interest.id);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                tempSelectedIds.remove(interest.id);
                              } else {
                                tempSelectedIds.add(interest.id!);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFFC5246D), Color(0xFF6B4FD6)])
                                  : null,
                              color: isSelected ? null : const Color(0xFF171717),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              interest.name ?? '',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomButton(
                text: "Save",
                onTap: () {
                  final newSelection = catalog
                      .where((e) => tempSelectedIds.contains(e.id))
                      .toList();
                  widget.controller.saveInterests(newSelection);
                  Get.back();
                },
              ),
            ),
            SizedBox(height: AppBar().preferredSize.height),
          ],
        ),
      ),
    );
  }
}
