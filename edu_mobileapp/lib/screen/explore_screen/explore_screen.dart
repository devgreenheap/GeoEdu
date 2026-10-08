import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/common/widget/my_refresh_indicator.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/screen/explore_screen/explore_screen_controller.dart';
import 'package:geoedu/screen/explore_screen/model/interest_search_item.dart';
import 'package:geoedu/screen/notification_screen/notification_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExploreScreenController());

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            // Dismiss suggestions dropdown & unfocus when tapping outside
            if (controller.showSuggestions.value) {
              controller.showSuggestions.value = false;
            }
            controller.searchFocusNode.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. TOP HEADER: "Explore" + "Discover amazing posts" + Notification Bell
              _buildTopTitleBar(context, controller),

              const SizedBox(height: 14),

              // 2. SEARCH BAR & REAL-TIME TYPO-TOLERANT SUGGESTIONS DROPDOWN
              _buildSearchBarWithSuggestions(context, controller),

              // 3. ACTIVE FILTER CHIP (if an interest is selected)
              _buildActiveFilterIndicator(context, controller),

              const SizedBox(height: 8),

              // 4. 2-COLUMN STAGGERED POSTS GRID (All available videos by default)
              Expanded(
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  final isFilterLoading = controller.isFilterLoading.value;
                  final posts = controller.displayedPosts;

                  return MyRefreshIndicator(
                    onRefresh: controller.fetchExplorePageData,
                    child: (isLoading || isFilterLoading) && posts.isEmpty
                        ? _buildLoadingGrid()
                        : posts.isEmpty
                            ? _buildNoVideosFoundState(context, controller)
                            : MasonryGridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                padding:
                                    const EdgeInsets.fromLTRB(14, 4, 14, 20),
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
                  );
                }),
              ),
            ],
          ),
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

  /// In-place Search Bar with Real-time Typo-Tolerant Suggestions Dropdown
  Widget _buildSearchBarWithSuggestions(
      BuildContext context, ExploreScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Field
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF111520),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFFF9800),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    focusNode: controller.searchFocusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: const Color(0xFFFF9800),
                    textInputAction: TextInputAction.search,
                    onChanged: controller.onSearchChanged,
                    onSubmitted: controller.submitSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search topics, categories, interests...',
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Obx(() {
                  final text = controller.searchQuery.value;
                  if (text.isEmpty && controller.activeFilterItem.value == null) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: controller.clearFilter,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Real-Time Suggestions Dropdown
          Obx(() {
            final show = controller.showSuggestions.value;
            final suggestions = controller.suggestions;
            if (!show || suggestions.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141724),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Suggestions Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFFFB300),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SUGGESTIONS FROM INTERESTS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Suggestion Tiles
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final item = suggestions[index];
                        return _buildSuggestionTile(controller, item);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Individual item in the real-time suggestions dropdown
  Widget _buildSuggestionTile(
      ExploreScreenController controller, InterestSearchItem item) {
    return InkWell(
      onTap: () => controller.selectSuggestion(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getTypeColor(item.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(item.type),
                size: 17,
                color: _getTypeColor(item.type),
              ),
            ),
            const SizedBox(width: 12),

            // Name & Breadcrumbs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.hierarchyBreadcrumb.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.hierarchyBreadcrumb,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Type Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getTypeColor(item.type).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getTypeColor(item.type).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                item.typeLabel,
                style: TextStyle(
                  color: _getTypeColor(item.type),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active filter indicator shown when the feed is filtered by an interest
  Widget _buildActiveFilterIndicator(
      BuildContext context, ExploreScreenController controller) {
    return Obx(() {
      final active = controller.activeFilterItem.value;
      if (active == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF26180C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color: Color(0xFFFF9800),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${active.name} (${active.typeLabel})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: controller.clearFilter,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: controller.clearFilter,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Clean "No videos found" state when filter yields no results
  Widget _buildNoVideosFoundState(
      BuildContext context, ExploreScreenController controller) {
    final query = controller.activeFilterItem.value?.name ??
        controller.searchQuery.value;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Video / Search Icon Container
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9800).withValues(alpha: 0.25),
                    const Color(0xFF141724),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.videocam_off_rounded,
                  color: Color(0xFFFFB300),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'No videos found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              query.isNotEmpty
                  ? 'We couldn\'t find any videos related to "$query" under Interests.'
                  : 'No videos available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Show All Videos Button
            ElevatedButton.icon(
              onPressed: controller.clearFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text(
                'Show all videos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(InterestItemType type) {
    switch (type) {
      case InterestItemType.category:
        return const Color(0xFFFF9800); // Amber
      case InterestItemType.subCategory:
        return const Color(0xFF26A69A); // Teal
      case InterestItemType.division:
        return const Color(0xFF42A5F5); // Blue
      case InterestItemType.topic:
        return const Color(0xFFAB47BC); // Purple
      case InterestItemType.interest:
        return const Color(0xFF66BB6A); // Green
    }
  }

  IconData _getTypeIcon(InterestItemType type) {
    switch (type) {
      case InterestItemType.category:
        return Icons.category_rounded;
      case InterestItemType.subCategory:
        return Icons.subdirectory_arrow_right_rounded;
      case InterestItemType.division:
        return Icons.layers_rounded;
      case InterestItemType.topic:
        return Icons.tag_rounded;
      case InterestItemType.interest:
        return Icons.favorite_border_rounded;
    }
  }

  /// Individual Staggered Post Card with 3-dot Menu and Heart Like Button
  Widget _buildPostCard(BuildContext context,
      ExploreScreenController controller, Post post, int index) {
    final double cardHeight = (index % 4 == 0)
        ? 240.0
        : ((index % 4 == 1)
            ? 260.0
            : ((index % 4 == 2) ? 215.0 : 245.0));

    String? thumb = post.thumbnail;
    if (thumb == null || thumb.trim().isEmpty) {
      if (post.postType == PostType.image &&
          (post.images?.isNotEmpty ?? false)) {
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

            // Dark Gradient Overlay for text legibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Top-Right: Video/Reel indicator badge
            if (post.postType == PostType.reel ||
                post.postType == PostType.video)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.6,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 2),
                      Text(
                        'Reel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Info: Avatar, Username, Likes
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption / Description
                  if (post.description != null &&
                      post.description!.trim().isNotEmpty) ...[
                    Text(
                      post.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: post.user?.profilePhoto != null &&
                                post.user!.profilePhoto!.trim().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl:
                                    post.user!.profilePhoto!.addBaseURL(),
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _buildAvatarInitial(post.user?.fullname),
                              )
                            : _buildAvatarInitial(post.user?.fullname),
                      ),
                      const SizedBox(width: 6),

                      // User Full Name or Username
                      Expanded(
                        child: Text(
                          post.user?.fullname ?? post.user?.username ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Like Heart Button
                      GestureDetector(
                        onTap: () => controller.toggleLike(post),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isLiked
                                    ? const Color(0xFFFF3B30)
                                    : Colors.white70,
                                size: 15,
                              ),
                              if ((post.likes ?? 0) > 0) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '${post.likes}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarInitial(String? name) {
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim()[0].toUpperCase()
        : 'U';
    return Container(
      color: const Color(0xFF2C3140),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) {
        final double height = (index % 4 == 0)
            ? 240.0
            : ((index % 4 == 1)
                ? 260.0
                : ((index % 4 == 2) ? 215.0 : 245.0));
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF131722),
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }
}
