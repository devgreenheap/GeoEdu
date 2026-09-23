import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/live_room/category_tile.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/all_rooms_screen.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

class LiveCategoriesListWidget extends StatelessWidget {
  const LiveCategoriesListWidget({super.key});

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
                onTap: () => Get.to(() => const AllRoomsScreen()),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: ColorRes.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                  onTap: () => controller.onCategorySelected(index),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
