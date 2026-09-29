import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/common/widget/my_refresh_indicator.dart';
import 'package:geoedu/common/widget/no_data_widget.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/screen/explore_screen/explore_screen_controller.dart';
import 'package:geoedu/screen/notification_screen/notification_screen.dart';
import 'package:geoedu/screen/search_screen/search_screen.dart';
import 'package:share_plus/share_plus.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExploreScreenController());

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // 1. TOP HEADER: "Explore" + "Discover amazing posts" + Notification Bell
            _buildTopTitleBar(context, controller),

            const SizedBox(height: 16),

            // 2. SEARCH BAR (Full Width, NO filter icon in this row)
            _buildSearchBar(context, controller),

            const SizedBox(height: 14),

            // 3. REAL-TIME FILTER PILLS ROW UNDER SEARCH BAR (# All, ✈ Travel, 💻 Tech, 🍃 Nature, 🍴 Food, etc.)
            _buildRealtimeFilterPills(context, controller),

            const SizedBox(height: 12),

            // 4. 2-COLUMN STAGGERED POSTS GRID
            Expanded(
              child: Obx(() {
                final isLoading = controller.isLoading.value;
                final isFilterLoading = controller.isFilterLoading.value;
                final posts = controller.displayedPosts;

                return MyRefreshIndicator(
                  onRefresh: controller.fetchExplorePageData,
                  child: (isLoading || isFilterLoading) && posts.isEmpty
                      ? _buildLoadingGrid()
                      : NoDataView(
                          showShow: !isLoading && !isFilterLoading && posts.isEmpty,
                          title: LKey.searchPageEmptyTitle.tr,
                          description: LKey.searchPageEmptyDescription.tr,
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return _buildPostCard(
                                context,
                                controller,
                                posts[index],
                                index,
                              );
                            },
                          ),
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Row: Explore Title, Subtitle & Notification Bell
  Widget _buildTopTitleBar(
      BuildContext context, ExploreScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Title & Subtitle
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Discover amazing posts',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          // Right: Notification Bell Button
          GestureDetector(
            onTap: () => Get.to(() => const NotificationScreen()),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width Search Bar (Filter icon removed per user request)
  Widget _buildSearchBar(
      BuildContext context, ExploreScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => Get.to(() => const SearchScreen()),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF111520),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: Colors.white60,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Search posts, places, topics...',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Real-Time Filter Pills Row under the Search Bar
  Widget _buildRealtimeFilterPills(
      BuildContext context, ExploreScreenController controller) {
    return SizedBox(
      height: 40,
      child: Obx(() {
        final categories = controller.categories;
        final selected = controller.selectedCategory.value;

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final bool isSelected = selected.toLowerCase() == category.toLowerCase();

            return GestureDetector(
              onTap: () => controller.filterByCategory(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF331A08)
                      : const Color(0xFF141824),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6D00)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6D00).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoryIcon(category, isSelected),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Icon for categories matching reference screenshot (# All, ✈ Travel, 💻 Tech, 🍃 Nature, 🍴 Food)
  Widget _buildCategoryIcon(String category, bool isSelected) {
    final lower = category.toLowerCase().trim();
    final Color iconColor = isSelected ? const Color(0xFFFF7A00) : Colors.white70;

    if (lower == 'all') {
      return Text(
        '#',
        style: TextStyle(
          color: iconColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
        ),
      );
    } else if (lower.contains('travel') || lower.contains('trip') || lower.contains('tour')) {
      return Icon(Icons.flight_rounded, color: iconColor, size: 16);
    } else if (lower.contains('tech') || lower.contains('code') || lower.contains('computer') || lower.contains('dev')) {
      return Icon(Icons.laptop_chromebook_rounded, color: iconColor, size: 16);
    } else if (lower.contains('nature') || lower.contains('plant') || lower.contains('green')) {
      return Icon(Icons.eco_rounded, color: iconColor, size: 16);
    } else if (lower.contains('food') || lower.contains('cook') || lower.contains('restaurant')) {
      return Icon(Icons.restaurant_rounded, color: iconColor, size: 16);
    } else if (lower.contains('music') || lower.contains('song')) {
      return Icon(Icons.music_note_rounded, color: iconColor, size: 16);
    } else if (lower.contains('fitness') || lower.contains('gym') || lower.contains('sport')) {
      return Icon(Icons.fitness_center_rounded, color: iconColor, size: 16);
    } else {
      return Text(
        '#',
        style: TextStyle(
          color: iconColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
    }
  }

  /// Individual Staggered Post Card with 3-dot Menu and Heart Like Button
  Widget _buildPostCard(BuildContext context, ExploreScreenController controller,
      Post post, int index) {
    final double cardHeight = (index % 4 == 0)
        ? 240.0
        : ((index % 4 == 1)
            ? 260.0
            : ((index % 4 == 2) ? 215.0 : 245.0));

    String? thumb = post.thumbnail;
    if (thumb == null || thumb.trim().isEmpty) {
      if (post.postType == PostType.image && (post.images?.isNotEmpty ?? false)) {
        thumb = post.images!.first.image;
      } else if (post.user?.profilePhoto != null &&
          post.user!.profilePhoto!.trim().isNotEmpty) {
        thumb = post.user!.profilePhoto;
      }
    }
    final imageUrl = thumb?.addBaseURL();
    final bool isLiked = post.isLiked ?? false;

    return GestureDetector(
      onTap: () => controller.onPostTap(post),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF161922),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media Image
            imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFF161922),
                      child: Center(
                        child: Icon(
                          post.postType == PostType.reel
                              ? Icons.play_circle_outline_rounded
                              : Icons.image_outlined,
                          color: Colors.white24,
                          size: 32,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF161922),
                      child: Center(
                        child: Icon(
                          post.postType == PostType.reel
                              ? Icons.play_circle_outline_rounded
                              : Icons.image_outlined,
                          color: Colors.white24,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF161922),
                    child: Center(
                      child: Icon(
                        post.postType == PostType.reel
                            ? Icons.play_circle_outline_rounded
                            : Icons.image_outlined,
                        color: Colors.white24,
                        size: 32,
                      ),
                    ),
                  ),

            // Top Vignette Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Vignette Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top-Right Three-Dot Menu Button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showPostOptions(context, post),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Bottom-Right Heart Like Button
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => controller.toggleLike(post),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? const Color(0xFFFF3B30) : Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer loading grid placeholder
  Widget _buildLoadingGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        final double cardHeight = (index % 2 == 0) ? 240.0 : 210.0;
        return Container(
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF131620),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Post Options Bottom Sheet (Share, Copy, Report)
  void _showPostOptions(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF151822),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: Colors.white),
                  title: const Text('Share Post', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    final url = post.thumbnail?.addBaseURL() ?? '';
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Check out this post on GeoEdu: $url',
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: Colors.white),
                  title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    final url = post.thumbnail?.addBaseURL() ?? '';
                    Clipboard.setData(ClipboardData(text: url));
                    Get.snackbar(
                      'Link Copied',
                      'Post link copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                  title: const Text('Report Post', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Reported',
                      'Thank you for reporting. We will review this post.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
