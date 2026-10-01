import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';

/// Category-based gift sheet for Video Live Room matching the Audio Call sheet design:
/// Shows tabs (All, Popular, Food, Gold, Farms), diamond balance, Recharge button,
/// and 1-tap direct send to host.
class VideoRoomGiftCategorySheet extends StatefulWidget {
  final LivestreamScreenController controller;

  const VideoRoomGiftCategorySheet({
    super.key,
    required this.controller,
  });

  static void show({
    required BuildContext context,
    required LivestreamScreenController controller,
  }) {
    controller.fetchDiamondBalanceIfNeeded();
    Get.bottomSheet(
      VideoRoomGiftCategorySheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  State<VideoRoomGiftCategorySheet> createState() =>
      _VideoRoomGiftCategorySheetState();
}

class _VideoRoomGiftCategorySheetState
    extends State<VideoRoomGiftCategorySheet> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All';
  }

  List<String> _extractCategories(List<Gift> gifts) {
    final List<String> categories = ['All'];

    void addCategory(String? raw) {
      if (raw == null) return;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      final formatted = trimmed[0].toUpperCase() + trimmed.substring(1);
      final alreadyExists =
          categories.any((c) => c.toLowerCase() == formatted.toLowerCase());
      if (!alreadyExists) {
        categories.add(formatted);
      }
    }

    final adminCats =
        SessionManager.instance.getSettings()?.giftCategories ?? [];
    for (final c in adminCats) {
      addCategory(c.name);
    }

    for (final g in gifts) {
      addCategory(g.categoryName);
    }

    for (final fallback in ['Food', 'Gold', 'Farms']) {
      addCategory(fallback);
    }

    return categories;
  }

  bool _giftMatchesCategory(Gift gift, String category) {
    if (category.toLowerCase().trim() == 'all') return true;
    final target = category.toLowerCase().trim();

    final catName = (gift.categoryName ?? '').toLowerCase().trim();
    if (catName.isNotEmpty &&
        (catName == target ||
            catName.contains(target) ||
            target.contains(catName))) {
      return true;
    }

    final adminCats =
        SessionManager.instance.getSettings()?.giftCategories ?? [];
    for (final c in adminCats) {
      final name = (c.name ?? '').toLowerCase().trim();
      final isMatch = name == target ||
          (target == 'farms' && name == 'farm') ||
          (target == 'farm' && name == 'farms') ||
          name.contains(target) ||
          target.contains(name);
      if (isMatch) {
        if (gift.giftCategoryId != null && gift.giftCategoryId == c.id) {
          return true;
        }
        if (gift.categoryId != null && gift.categoryId == c.id) return true;
      }
    }

    final String searchStr = [
      gift.title ?? '',
      gift.displayName,
      gift.image ?? '',
      gift.animationUrl ?? '',
    ].join(' ').toLowerCase();

    if (searchStr.contains(target)) return true;

    if (target == 'food' || target.contains('food')) {
      const foodKeywords = [
        'food', 'tikka', 'pizza', 'burger', 'sandwich', 'pasta', 'biryani',
        'chai', 'tea', 'coffee', 'drink', 'juice', 'cake', 'chocolate', 'candy',
        'sweet', 'cookie', 'donut', 'fruit', 'apple', 'snack'
      ];
      return foodKeywords.any((k) => searchStr.contains(k));
    } else if (target == 'gold' || target.contains('gold')) {
      const goldKeywords = [
        'gold', 'golden', 'jewel', 'ring', 'crown', 'diamond', 'gem',
        'luxury', 'castle', 'car', 'supercar', 'yacht', 'jet', 'watch'
      ];
      return goldKeywords.any((k) => searchStr.contains(k));
    } else if (target == 'farms' || target == 'farm' || target.contains('farm')) {
      const farmKeywords = [
        'farm', 'farms', 'tractor', 'horse', 'cow', 'sheep', 'hen',
        'harvest', 'crop', 'tree', 'wheat', 'field', 'flower', 'rose'
      ];
      return farmKeywords.any((k) => searchStr.contains(k));
    }

    return false;
  }

  List<Gift> _filterGifts(List<Gift> allGifts) {
    if (_selectedCategory.toLowerCase().trim() == 'all') return allGifts;
    final filtered =
        allGifts.where((g) => _giftMatchesCategory(g, _selectedCategory)).toList();
    return filtered.isNotEmpty ? filtered : allGifts;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allGifts = widget.controller.availableGifts.isNotEmpty
          ? widget.controller.availableGifts
          : (SessionManager.instance.getSettings()?.availableGifts ??
              SessionManager.instance.getSettings()?.gifts ??
              []);

      final bool isLocked = widget.controller.isGiftAnimating.value ||
          widget.controller.activeGifts.isNotEmpty;

      final categories = _extractCategories(allGifts);
      final filteredGifts = _filterGifts(allGifts);

      return Container(
        height: Get.height * 0.56,
        decoration: BoxDecoration(
          color: const Color(0xFF10131B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag indicator bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Top Bar: "Send Gifts" | Diamond Balance | "Recharge >"
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Send Gifts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    // Diamond Balance
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.controller.diamondBalance.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.diamond_rounded,
                          color: Color(0xFFBA68C8),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Recharge > button
                    InkWell(
                      onTap: () async {
                        await Get.to(() => StarStoreDiamondScreen(
                              onPurchaseCompleted: () {
                                Get.back();
                                widget.controller.fetchDiamondBalanceIfNeeded();
                              },
                            ));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A00), Color(0xFFFF5200)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5200)
                                  .withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Recharge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Pills Carousel
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory.toLowerCase().trim() ==
                        cat.toLowerCase().trim();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF7A19)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF7A19)
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Grid of Gifts
              Expanded(
                child: filteredGifts.isEmpty
                    ? const Center(
                        child: Text(
                          'No gifts in this category',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredGifts.length,
                        itemBuilder: (context, index) {
                          final gift = filteredGifts[index];
                          final price = gift.coinPrice ?? 0;
                          String priceStr = price >= 1000
                              ? '${(price / 1000).toStringAsFixed(1)}K'
                              : '$price';

                          return GestureDetector(
                            onTap: isLocked
                                ? null
                                : () {
                                    Get.back();
                                    widget.controller.sendGiftDirect(gift);
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  CustomImage(
                                    size: const Size(46, 46),
                                    image: gift.image?.addBaseURL(),
                                    fit: BoxFit.contain,
                                    radius: 6,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gift.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.diamond_rounded,
                                        color: Color(0xFFBA68C8),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        priceStr,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
