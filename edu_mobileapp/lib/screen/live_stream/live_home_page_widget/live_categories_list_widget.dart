import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/live_room/category_tile.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/change_interest_sheet.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';

class LiveCategoriesListWidget extends StatefulWidget {
  const LiveCategoriesListWidget({super.key});

  @override
  State<LiveCategoriesListWidget> createState() => _LiveCategoriesListWidgetState();
}

class _LiveCategoriesListWidgetState extends State<LiveCategoriesListWidget> {
  final ScrollController _categoryScrollController = ScrollController();

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_categoryScrollController.hasClients) {
        _categoryScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveStreamSearchScreenController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Image.asset(AssetRes.liveStreamIcon, height: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live Classrooms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.bottomSheet(
                    const ChangeInterestSheet(),
                    isScrollControlled: true,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5246D).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC5246D).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 13, color: Color(0xFFE04A8B)),
                      SizedBox(width: 4),
                      Text(
                        'Change Interest',
                        style: TextStyle(
                          color: Color(0xFFE04A8B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: Obx(() {
            final categories = controller.filterCategories;
            final selectedIndex = controller.selectedCategoryIndex.value;
            final totalCount = categories.length + 1; // +1 for "All"

            return ListView.builder(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                final label = index == 0 ? 'All' : (categories[index - 1].name ?? '');
                final isSelected = selectedIndex == index;

                return CategoryTile(
                  label: label,
                  isSelected: isSelected,
                  onTap: () {
                    controller.onCategorySelected(index);
                    _scrollToStart();
                  },
                );
              },
            );
          }),
        ),
        Obx(() {
          final subCat = controller.selectedSubCategory.value;
          final div = controller.selectedDivision.value;
          final top = controller.selectedTopic.value;

          if (subCat == null && div == null && top == null) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 8, left: 14, right: 14),
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                if (subCat != null)
                  _buildActiveChip(
                    label: subCat.name ?? '',
                    icon: Icons.subdirectory_arrow_right_rounded,
                    onClear: () {
                      controller.selectedSubCategory.value = null;
                      controller.selectedDivision.value = null;
                      controller.selectedTopic.value = null;
                      controller.onCategorySelected(controller.selectedCategoryIndex.value);
                    },
                  ),
                if (div != null)
                  _buildActiveChip(
                    label: div.name ?? '',
                    icon: Icons.layers_rounded,
                    onClear: () {
                      controller.selectedDivision.value = null;
                      controller.selectedTopic.value = null;
                      controller.onCategorySelected(controller.selectedCategoryIndex.value);
                    },
                  ),
                if (top != null)
                  _buildActiveChip(
                    label: top.name ?? '',
                    icon: Icons.topic_rounded,
                    onClear: () {
                      controller.selectedTopic.value = null;
                      controller.onCategorySelected(controller.selectedCategoryIndex.value);
                    },
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActiveChip({
    required String label,
    required IconData icon,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF7A00).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFF7A00)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF7A00),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFFF7A00)),
          ),
        ],
      ),
    );
  }
}
