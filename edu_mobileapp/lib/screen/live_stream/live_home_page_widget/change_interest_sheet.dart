import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/bottom_sheet_top_view.dart';
import 'package:geoedu/model/general/interest_model.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

/// A standalone bottom sheet for changing user interests from the home page.
/// On save, it calls [LiveStreamSearchScreenController.onInterestsSaved] so
/// the category filter auto-selects based on the new interest selection.
class ChangeInterestSheet extends StatefulWidget {
  const ChangeInterestSheet({super.key});

  @override
  State<ChangeInterestSheet> createState() => _ChangeInterestSheetState();
}

class _ChangeInterestSheetState extends State<ChangeInterestSheet> {
  List<Interest> catalog = [];
  late Set<int> tempSelectedIds;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    tempSelectedIds = {};
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = Get.find<LiveStreamSearchScreenController>();
      // Re-use already-fetched data if available, else fetch fresh
      List<Interest> cat = controller.interestCatalog;
      List<Interest> mine = controller.myInterests;

      if (cat.isEmpty) {
        final r = await CommonService.instance.fetchInterests();
        cat = r.data ?? [];
      }
      if (mine.isEmpty) {
        final r = await UserService.instance.fetchMyInterests();
        mine = r.data ?? [];
      }

      if (mounted) {
        setState(() {
          catalog = cat;
          tempSelectedIds = mine.map((e) => e.id!).toSet();
          isLoading = false;
        });
      }
    } catch (e) {
      Loggers.error('ChangeInterestSheet load error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    try {
      final newSelection = catalog.where((e) => tempSelectedIds.contains(e.id)).toList();
      final result = await UserService.instance.updateMyInterests(
        interestIds: newSelection.map((e) => e.id!).toList(),
      );
      final saved = result.data ?? newSelection;

      // Notify the home controller so it can re-filter
      if (Get.isRegistered<LiveStreamSearchScreenController>()) {
        await Get.find<LiveStreamSearchScreenController>().onInterestsSaved(saved);
      }
      Get.back();
    } catch (e) {
      Loggers.error('ChangeInterestSheet save error: $e');
    }
    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const ShapeDecoration(
        color: Color(0xFF1E1E1E),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetTopView(title: 'Change Interests'),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: ColorRes.primaryColor),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: catalog.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          'No interests available yet',
                          style: TextStyle(color: Colors.white38),
                        ),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFFC5246D), Color(0xFF6B4FD6)],
                                      )
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
              child: isSaving
                  ? const CircularProgressIndicator(color: ColorRes.primaryColor)
                  : CustomButton(
                      text: 'Save & Apply',
                      onTap: _save,
                    ),
            ),
            SizedBox(height: AppBar().preferredSize.height),
          ],
        ),
      ),
    );
  }
}
