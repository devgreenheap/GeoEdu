import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/widget/bottom_sheet_top_view.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Interactive filter sheet for Categories, Sub Categories, Divisions, and Topics.
class ChangeInterestSheet extends StatefulWidget {
  const ChangeInterestSheet({super.key});

  @override
  State<ChangeInterestSheet> createState() => _ChangeInterestSheetState();
}

class _ChangeInterestSheetState extends State<ChangeInterestSheet> {
  List<Category> categories = [];
  bool isLoading = true;

  // Selected hierarchy
  Category? selectedCategory;
  SubCategory? selectedSubCategory;
  Division? selectedDivision;
  Topic? selectedTopic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = Get.find<LiveStreamSearchScreenController>();
      if (controller.filterCategories.isNotEmpty) {
        categories = controller.filterCategories;
      } else {
        final result = await CommonService.instance.fetchCategorySubCategoryTopic();
        categories = result.data ?? [];
        controller.filterCategories.value = categories;
      }

      // Pre-select currently active filter
      if (controller.selectedCategoryIndex.value > 0 &&
          controller.selectedCategoryIndex.value - 1 < categories.length) {
        selectedCategory = categories[controller.selectedCategoryIndex.value - 1];
        selectedSubCategory = controller.selectedSubCategory.value;
        selectedDivision = controller.selectedDivision.value;
        selectedTopic = controller.selectedTopic.value;
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      Loggers.error('ChangeInterestSheet load error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onCategorySelected(Category cat) {
    setState(() {
      if (selectedCategory?.id == cat.id) {
        selectedCategory = null;
        selectedSubCategory = null;
        selectedDivision = null;
        selectedTopic = null;
      } else {
        selectedCategory = cat;
        selectedSubCategory = null;
        selectedDivision = null;
        selectedTopic = null;
      }
    });
  }

  void _onSubCategorySelected(SubCategory sub) {
    setState(() {
      if (selectedSubCategory?.id == sub.id) {
        selectedSubCategory = null;
        selectedDivision = null;
        selectedTopic = null;
      } else {
        selectedSubCategory = sub;
        selectedDivision = null;
        selectedTopic = null;
      }
    });
  }

  void _onDivisionSelected(Division div) {
    setState(() {
      if (selectedDivision?.id == div.id) {
        selectedDivision = null;
        selectedTopic = null;
      } else {
        selectedDivision = div;
        selectedTopic = null;
      }
    });
  }

  void _onTopicSelected(Topic top) {
    setState(() {
      if (selectedTopic?.id == top.id) {
        selectedTopic = null;
      } else {
        selectedTopic = top;
      }
    });
  }

  void _applyFilter() {
    final controller = Get.find<LiveStreamSearchScreenController>();
    if (selectedCategory == null) {
      controller.clearHierarchicalFilter();
    } else {
      final catIndex = categories.indexWhere((c) => c.id == selectedCategory!.id);
      controller.setHierarchicalFilter(
        categoryIndex: catIndex >= 0 ? catIndex + 1 : 0,
        subCategory: selectedSubCategory,
        division: selectedDivision,
        topic: selectedTopic,
      );
    }
    Get.back();
  }

  void _resetFilter() {
    setState(() {
      selectedCategory = null;
      selectedSubCategory = null;
      selectedDivision = null;
      selectedTopic = null;
    });
    final controller = Get.find<LiveStreamSearchScreenController>();
    controller.clearHierarchicalFilter();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const ShapeDecoration(
        color: Color(0xFF14141E),
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
            const BottomSheetTopView(title: 'Filter Classrooms'),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: ColorRes.primaryColor),
              )
            else if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'No categories available',
                  style: TextStyle(color: Colors.white38),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Categories section
                      _buildSectionHeader(
                        icon: Icons.category_rounded,
                        title: 'Categories',
                        badgeCount: categories.length,
                      ),
                      const SizedBox(height: 10),
                      _buildPills(
                        items: categories,
                        isSelected: (cat) => selectedCategory?.id == cat.id,
                        label: (cat) => cat.name ?? '',
                        onTap: (cat) => _onCategorySelected(cat),
                      ),

                      // 2. Sub Categories section (if category selected)
                      if (selectedCategory != null) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          icon: Icons.subdirectory_arrow_right_rounded,
                          title: 'Sub Categories',
                          badgeCount: (selectedCategory!.subCategories ?? []).length,
                        ),
                        const SizedBox(height: 10),
                        (selectedCategory!.subCategories ?? []).isEmpty
                            ? _buildEmptyText('No sub categories available')
                            : _buildPills(
                                items: selectedCategory!.subCategories!,
                                isSelected: (sub) => selectedSubCategory?.id == sub.id,
                                label: (sub) => sub.name ?? '',
                                onTap: (sub) => _onSubCategorySelected(sub),
                              ),
                      ],

                      // 3. Divisions section (if subcategory has divisions)
                      if (selectedSubCategory != null &&
                          (selectedSubCategory!.divisions ?? []).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          icon: Icons.layers_rounded,
                          title: 'Divisions',
                          badgeCount: (selectedSubCategory!.divisions ?? []).length,
                        ),
                        const SizedBox(height: 10),
                        _buildPills(
                          items: selectedSubCategory!.divisions!,
                          isSelected: (div) => selectedDivision?.id == div.id,
                          label: (div) => div.name ?? '',
                          onTap: (div) => _onDivisionSelected(div),
                        ),
                      ],

                      // 4. Topics section (if subcategory selected)
                      if (selectedSubCategory != null) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          icon: Icons.topic_rounded,
                          title: 'Topics',
                          badgeCount: _filteredTopics.length,
                        ),
                        const SizedBox(height: 10),
                        _filteredTopics.isEmpty
                            ? _buildEmptyText('No topics available')
                            : _buildPills(
                                items: _filteredTopics,
                                isSelected: (top) => selectedTopic?.id == top.id,
                                label: (top) => top.name ?? '',
                                onTap: (top) => _onTopicSelected(top),
                              ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            // Bottom Buttons (Clear & Apply)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF191924),
                border: Border(
                  top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _resetFilter,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Apply Filter',
                      onTap: _applyFilter,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Topic> get _filteredTopics {
    if (selectedSubCategory == null) return [];
    final allTopics = selectedSubCategory!.topics ?? [];
    if (selectedDivision == null) {
      return allTopics;
    }
    final divTopics = allTopics.where((t) => t.divisionId == selectedDivision!.id).toList();
    // Fall back to all subcategory topics if none explicitly tagged with division
    return divTopics.isNotEmpty ? divTopics : allTopics;
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int badgeCount,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF7A00)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$badgeCount',
            style: const TextStyle(
              color: Color(0xFFFF7A00),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white30, fontSize: 12),
      ),
    );
  }

  Widget _buildPills<T>({
    required List<T> items,
    required bool Function(T) isSelected,
    required String Function(T) label,
    required void Function(T) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final active = isSelected(item);
        final text = label(item);
        return GestureDetector(
          onTap: () => onTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFFFF7A00), Color(0xFFFF5252)],
                    )
                  : null,
              color: active ? null : const Color(0xFF222232),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (active) ...[
                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
