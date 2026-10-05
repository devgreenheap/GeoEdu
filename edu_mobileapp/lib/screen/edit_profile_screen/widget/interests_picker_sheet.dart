import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/bottom_sheet_top_view.dart';
import 'package:geoedu/model/general/interest_model.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final selected = widget.controller.selectedInterests;
    tempSelectedIds = selected
        .map((e) => e.id)
        .whereType<int>()
        .toSet();

    // Also match by name if ID was mismatched
    final selectedNames = selected
        .map((e) => e.name?.trim().toLowerCase())
        .whereType<String>()
        .toSet();

    final catalog = _getCatalog();
    for (final item in catalog) {
      if (item.id != null &&
          selectedNames.contains(item.name?.trim().toLowerCase())) {
        tempSelectedIds.add(item.id!);
      }
    }

    if (catalog.isEmpty) {
      widget.controller.fetchInterestCatalog().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  List<Interest> _getCatalog() {
    if (widget.controller.interestCatalog.isNotEmpty) {
      return widget.controller.interestCatalog;
    }
    // Fallback to Category options (the options presented after login/onboarding)
    return widget.controller.categoryList
        .map((c) => Interest(id: c.id, name: c.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _getCatalog();

    return Container(
      decoration: const ShapeDecoration(
        color: Color(0xFF1E1E1E),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 32, cornerSmoothing: 1),
          ),
        ),
      ),
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
                      child: Text(
                        'Loading interests...',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: catalog.map((interest) {
                          final isSelected =
                              tempSelectedIds.contains(interest.id);
                          return GestureDetector(
                            onTap: () {
                              if (interest.id == null) return;
                              setState(() {
                                if (isSelected) {
                                  tempSelectedIds.remove(interest.id);
                                } else {
                                  tempSelectedIds.add(interest.id!);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFC5246D),
                                          Color(0xFF6B4FD6),
                                        ],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : const Color(0xFF171717),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    interest.name ?? '',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomButton(
                text: _isSaving ? "Saving..." : "Save",
                isEnabled: !_isSaving,
                onTap: () async {
                  if (_isSaving) return;
                  setState(() => _isSaving = true);

                  final newSelection = catalog
                      .where((e) =>
                          e.id != null && tempSelectedIds.contains(e.id))
                      .toList();

                  await widget.controller.saveInterests(newSelection);

                  if (mounted) {
                    Get.back();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
