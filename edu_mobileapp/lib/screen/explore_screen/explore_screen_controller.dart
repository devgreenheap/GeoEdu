import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/model/post_story/post/explore_page_model.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/screen/hashtag_screen/hashtag_screen.dart';
import 'package:geoedu/screen/post_screen/single_post_screen.dart';
import 'package:geoedu/screen/reels_screen/reels_screen.dart';
import 'package:geoedu/screen/scan_qr_code_screen/scan_qr_code_screen.dart';
import 'package:geoedu/screen/video_player_screen/video_player_screen.dart';

class ExploreScreenController extends BaseController {
  Rx<ExplorePageData?> explorePageData = Rx(null);
  RxList<Post> postsList = <Post>[].obs;
  RxList<Post> displayedPosts = <Post>[].obs;
  RxList<String> categories = <String>['All'].obs;
  RxString selectedCategory = 'All'.obs;
  RxString primaryHashtag = 'Explore'.obs;
  RxBool isFilterLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExplorePageData();
  }

  Future<void> fetchExplorePageData() async {
    isLoading.value = true;
    try {
      final data = await PostService.instance.fetchExplorePageData();
      List<HighPostHashtags> highHashtags = List.from(data?.highPostHashtags ?? []);

      // Keep only hashtags that have posts
      highHashtags.removeWhere((h) => h.postList == null || h.postList!.isEmpty);

      // Collect real-time categories from backend
      final Set<String> uniqueCategories = {'All'};

      // 1. From data.hashtags
      if (data?.hashtags != null) {
        for (final h in data!.hashtags!) {
          final tag = h.hashtag?.trim();
          if (tag != null && tag.isNotEmpty) {
            uniqueCategories.add(_capitalize(tag));
          }
        }
      }

      // 2. From highPostHashtags
      for (final h in highHashtags) {
        final tag = h.hashtag?.trim();
        if (tag != null && tag.isNotEmpty) {
          uniqueCategories.add(_capitalize(tag));
        }
      }

      // Fallback categories if backend has few
      if (uniqueCategories.length < 5) {
        uniqueCategories.addAll(['Travel', 'Tech', 'Nature', 'Food']);
      }
      categories.assignAll(uniqueCategories.toList());

      // Collect all posts from hashtags
      final List<Post> collectedPosts = [];
      final Set<int> seenIds = {};

      for (final h in highHashtags) {
        if (primaryHashtag.value == 'Explore' && h.hashtag != null && h.hashtag!.isNotEmpty) {
          primaryHashtag.value = h.hashtag!;
        }
        for (final p in (h.postList ?? [])) {
          if (p.id != null) {
            if (!seenIds.contains(p.id)) {
              seenIds.add(p.id!);
              collectedPosts.add(p);
            }
          } else {
            collectedPosts.add(p);
          }
        }
      }

      // If we don't have enough posts to fill a rich grid, supplement with discover reels & posts
      if (collectedPosts.length < 18) {
        try {
          final discoverReels =
              await PostService.instance.fetchPostsDiscover(type: PostType.reels);
          final discoverPosts =
              await PostService.instance.fetchPostsDiscover(type: PostType.posts);
          for (final p in [...discoverReels, ...discoverPosts]) {
            if (p.id != null) {
              if (!seenIds.contains(p.id)) {
                seenIds.add(p.id!);
                collectedPosts.add(p);
              }
            } else {
              collectedPosts.add(p);
            }
          }
        } catch (e) {
          Loggers.error('Error fetching fallback discover posts: $e');
        }
      }

      if (highHashtags.isEmpty && collectedPosts.isNotEmpty) {
        highHashtags.add(HighPostHashtags(
          id: 0,
          hashtag: 'Explore',
          postCount: collectedPosts.length,
          postList: collectedPosts,
        ));
      }

      postsList.assignAll(collectedPosts);
      explorePageData.value = ExplorePageData(
        hashtags: data?.hashtags ?? [],
        highPostHashtags: highHashtags,
      );

      // Apply initial filter
      filterByCategory(selectedCategory.value);
    } catch (e) {
      Loggers.error('fetchExplorePageData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    final cleaned = s.replaceAll('#', '').trim();
    if (cleaned.isEmpty) return s;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  Future<void> filterByCategory(String category) async {
    selectedCategory.value = category;
    if (category == 'All') {
      displayedPosts.assignAll(postsList);
      return;
    }

    final query = category.toLowerCase().replaceAll('#', '').trim();

    // 1. Check if highPostHashtags has exact match
    final matchedGroup = explorePageData.value?.highPostHashtags?.firstWhereOrNull(
      (h) => (h.hashtag ?? '').toLowerCase().trim() == query,
    );
    if (matchedGroup?.postList != null && matchedGroup!.postList!.isNotEmpty) {
      displayedPosts.assignAll(matchedGroup.postList!);
      return;
    }

    // 2. Filter from collected postsList
    final localMatches = postsList.where((p) {
      final desc = (p.description ?? '').toLowerCase();
      final hash = (p.hashtags ?? '').toLowerCase();
      return desc.contains(query) || hash.contains(query);
    }).toList();

    if (localMatches.isNotEmpty) {
      displayedPosts.assignAll(localMatches);
      return;
    }

    // 3. Real-time fetch from backend if local matches are empty
    isFilterLoading.value = true;
    try {
      final reelsData = await PostService.instance.fetchPostsByHashtag(
        type: PostType.reels,
        hashTag: query,
        lastItemId: null,
      );
      final postsData = await PostService.instance.fetchPostsByHashtag(
        type: PostType.posts,
        hashTag: query,
        lastItemId: null,
      );

      final List<Post> fetched = [
        ...(reelsData?.posts ?? []),
        ...(postsData?.posts ?? []),
      ];

      if (fetched.isNotEmpty) {
        displayedPosts.assignAll(fetched);
      } else {
        // Fallback to all posts if category is empty
        displayedPosts.assignAll(postsList);
      }
    } catch (e) {
      Loggers.error('Real-time filter fetch error: $e');
      displayedPosts.assignAll(postsList);
    } finally {
      isFilterLoading.value = false;
    }
  }

  Future<void> toggleLike(Post post) async {
    if (post.id == null) return;
    HapticFeedback.lightImpact();
    final wasLiked = post.isLiked ?? false;
    post.isLiked = !wasLiked;
    post.likes = (post.likes ?? 0) + (wasLiked ? -1 : 1);
    postsList.refresh();
    displayedPosts.refresh();
    try {
      if (wasLiked) {
        await PostService.instance.disLikePost(postId: post.id!);
      } else {
        await PostService.instance.likePost(postId: post.id!);
      }
    } catch (e) {
      Loggers.error('toggleLike error: $e');
    }
  }

  void onExploreTap(String? hashtag) {
    Get.to(
      () => HashtagScreen(
        hashtag: (hashtag != null && hashtag.isNotEmpty) ? hashtag : primaryHashtag.value,
        index: 0,
      ),
      preventDuplicates: false,
    );
  }

  void onPostTap(Post post) {
    switch (post.postType) {
      case PostType.reel:
        final allReels = displayedPosts.where((p) => p.postType == PostType.reel).toList();
        final initialIndex = allReels.indexOf(post);
        Get.to(() => ReelsScreen(
              reels: (allReels.isNotEmpty ? allReels : [post]).obs,
              position: initialIndex >= 0 ? initialIndex : 0,
            ));
        break;
      case PostType.image:
        Get.to(() => SinglePostScreen(post: post, isFromNotification: false));
        break;
      case PostType.video:
        Get.to(() => VideoPlayerScreen(post: post));
        break;
      case PostType.text:
      case PostType.none:
        Get.to(() => SinglePostScreen(post: post, isFromNotification: false));
        break;
    }
  }

  void onScanQrCode() {
    Get.to(() => const ScanQrCodeScreen());
  }
}
