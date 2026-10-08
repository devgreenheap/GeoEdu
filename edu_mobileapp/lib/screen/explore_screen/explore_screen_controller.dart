import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/common/service/api/search_service.dart';
import 'package:geoedu/model/post_story/post/explore_page_model.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/screen/explore_screen/model/interest_search_item.dart';
import 'package:geoedu/screen/explore_screen/util/fuzzy_search_util.dart';
import 'package:geoedu/screen/hashtag_screen/hashtag_screen.dart';
import 'package:geoedu/screen/post_screen/single_post_screen.dart';
import 'package:geoedu/screen/reels_screen/reels_screen.dart';
import 'package:geoedu/screen/scan_qr_code_screen/scan_qr_code_screen.dart';
import 'package:geoedu/screen/video_player_screen/video_player_screen.dart';

class ExploreScreenController extends BaseController {
  Rx<ExplorePageData?> explorePageData = Rx(null);
  RxList<Post> postsList = <Post>[].obs;
  RxList<Post> displayedPosts = <Post>[].obs;
  RxString primaryHashtag = 'Explore'.obs;
  RxBool isFilterLoading = false.obs;

  // Search & Real-Time Typo-Tolerant Interest Suggestions
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxString searchQuery = ''.obs;
  final RxList<InterestSearchItem> interestCatalog = <InterestSearchItem>[].obs;
  final RxList<InterestSearchItem> suggestions = <InterestSearchItem>[].obs;
  final Rxn<InterestSearchItem> activeFilterItem = Rxn<InterestSearchItem>();
  final RxBool showSuggestions = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInterestCatalog();
    fetchExplorePageData();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  /// Builds a comprehensive catalog of all Categories, SubCategories,
  /// Divisions, and Topics from Interests for real-time typo-tolerant search.
  Future<void> fetchInterestCatalog() async {
    final List<InterestSearchItem> items = [];
    final Set<String> registeredKeys = {};

    void addItem(InterestSearchItem item) {
      final key = '${item.name.toLowerCase().trim()}_${item.type.name}';
      if (!registeredKeys.contains(key)) {
        registeredKeys.add(key);
        items.add(item);
      }
    }

    try {
      // 1. Fetch Categories, SubCategories, Divisions, Topics hierarchy
      final tree = await CommonService.instance.fetchCategorySubCategoryTopic();
      for (final cat in (tree.data ?? [])) {
        final catName = cat.name?.trim();
        if (catName != null && catName.isNotEmpty) {
          final catKeywords = <String>{catName.toLowerCase()};
          for (final sub in (cat.subCategories ?? [])) {
            if (sub.name != null) catKeywords.add(sub.name!.toLowerCase().trim());
            for (final div in (sub.divisions ?? [])) {
              if (div.name != null) catKeywords.add(div.name!.toLowerCase().trim());
            }
            for (final top in (sub.topics ?? [])) {
              if (top.name != null) catKeywords.add(top.name!.toLowerCase().trim());
            }
          }
          addItem(InterestSearchItem(
            name: catName,
            type: InterestItemType.category,
            id: cat.id,
            relatedKeywords: catKeywords,
          ));
        }

        // Subcategories
        for (final sub in (cat.subCategories ?? [])) {
          final subName = sub.name?.trim();
          if (subName != null && subName.isNotEmpty) {
            final subKeywords = <String>{
              subName.toLowerCase(),
              if (catName != null) catName.toLowerCase(),
            };
            for (final div in (sub.divisions ?? [])) {
              if (div.name != null) subKeywords.add(div.name!.toLowerCase().trim());
            }
            for (final top in (sub.topics ?? [])) {
              if (top.name != null) subKeywords.add(top.name!.toLowerCase().trim());
            }
            addItem(InterestSearchItem(
              name: subName,
              type: InterestItemType.subCategory,
              id: sub.id,
              parentCategoryName: catName,
              relatedKeywords: subKeywords,
            ));
          }

          // Divisions
          for (final div in (sub.divisions ?? [])) {
            final divName = div.name?.trim();
            if (divName != null && divName.isNotEmpty) {
              final divKeywords = <String>{
                divName.toLowerCase(),
                if (subName != null) subName.toLowerCase(),
                if (catName != null) catName.toLowerCase(),
              };
              addItem(InterestSearchItem(
                name: divName,
                type: InterestItemType.division,
                id: div.id,
                parentCategoryName: catName,
                parentSubCategoryName: subName,
                relatedKeywords: divKeywords,
              ));
            }
          }

          // Topics
          for (final top in (sub.topics ?? [])) {
            final topName = top.name?.trim();
            if (topName != null && topName.isNotEmpty) {
              final topKeywords = <String>{
                topName.toLowerCase(),
                if (subName != null) subName.toLowerCase(),
                if (catName != null) catName.toLowerCase(),
              };
              addItem(InterestSearchItem(
                name: topName,
                type: InterestItemType.topic,
                id: top.id,
                parentCategoryName: catName,
                parentSubCategoryName: subName,
                relatedKeywords: topKeywords,
              ));
            }
          }
        }
      }

      // 2. Fetch Interests catalog
      final interestsModel = await CommonService.instance.fetchInterests();
      for (final interest in (interestsModel.data ?? [])) {
        final name = interest.name?.trim();
        if (name != null && name.isNotEmpty) {
          addItem(InterestSearchItem(
            name: name,
            type: InterestItemType.interest,
            id: interest.id,
            relatedKeywords: {name.toLowerCase()},
          ));
        }
      }
    } catch (e) {
      Loggers.error('fetchInterestCatalog error: $e');
    }

    // Seed baseline common education/explore topics if backend data is minimal
    final seedTopics = [
      'Science',
      'Technology',
      'Computer Science',
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Travel',
      'Nature',
      'History',
      'Geography',
      'Art & Design',
      'Music',
      'Coding',
      'Languages',
      'Literature',
      'General Knowledge',
      'Astronomy',
      'Economics',
      'Psychology',
      'Philosophy',
      'Fitness & Sports',
      'Food & Cooking',
    ];
    for (final seed in seedTopics) {
      addItem(InterestSearchItem(
        name: seed,
        type: InterestItemType.topic,
        relatedKeywords: {seed.toLowerCase()},
      ));
    }

    interestCatalog.assignAll(items);
  }

  /// Loads all available videos and reels for the Explore feed
  Future<void> fetchExplorePageData() async {
    isLoading.value = true;
    try {
      final data = await PostService.instance.fetchExplorePageData();
      List<HighPostHashtags> highHashtags =
          List.from(data?.highPostHashtags ?? []);

      highHashtags.removeWhere((h) => h.postList == null || h.postList!.isEmpty);

      final List<Post> collectedPosts = [];
      final Set<int> seenIds = {};

      for (final h in highHashtags) {
        if (primaryHashtag.value == 'Explore' &&
            h.hashtag != null &&
            h.hashtag!.isNotEmpty) {
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

      // Supplement with discover reels & posts to ensure full rich video catalog
      if (collectedPosts.length < 24) {
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
          Loggers.error('Error fetching discover posts: $e');
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

      // By default: display all available videos
      if (activeFilterItem.value == null && searchQuery.value.isEmpty) {
        displayedPosts.assignAll(collectedPosts);
      } else if (activeFilterItem.value != null) {
        filterByInterest(activeFilterItem.value!);
      }
    } catch (e) {
      Loggers.error('fetchExplorePageData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Real-time search handler with typo-tolerant suggestion generation
  void onSearchChanged(String text) {
    searchQuery.value = text;
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      suggestions.clear();
      showSuggestions.value = false;
      if (activeFilterItem.value != null) {
        clearFilter();
      }
      return;
    }

    // Dynamic typo-tolerant suggestions appearing from the very first letter
    final matches = FuzzySearchUtil.findSuggestions(
      trimmed,
      interestCatalog,
      maxResults: 7,
    );
    suggestions.assignAll(matches);
    showSuggestions.value = matches.isNotEmpty;
  }

  /// Selecting a suggestion immediately filters the feed for the chosen interest
  void selectSuggestion(InterestSearchItem item) {
    searchController.text = item.name;
    searchQuery.value = item.name;
    activeFilterItem.value = item;
    showSuggestions.value = false;
    searchFocusNode.unfocus();

    filterByInterest(item);
  }

  /// Submitting via keyboard search action
  void submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearFilter();
      return;
    }

    showSuggestions.value = false;
    searchFocusNode.unfocus();

    // Check if we have a top ranked suggestion
    final topMatch = suggestions.isNotEmpty ? suggestions.first : null;
    if (topMatch != null) {
      selectSuggestion(topMatch);
      return;
    }

    // Otherwise create ad-hoc query item
    final customItem = InterestSearchItem(
      name: trimmed,
      type: InterestItemType.topic,
      relatedKeywords: {trimmed.toLowerCase()},
    );
    activeFilterItem.value = customItem;
    filterByInterest(customItem);
  }

  /// Resets search filter and displays all available videos by default
  void clearFilter() {
    searchController.clear();
    searchQuery.value = '';
    activeFilterItem.value = null;
    showSuggestions.value = false;
    searchFocusNode.unfocus();
    displayedPosts.assignAll(postsList);
  }

  /// Filters and displays videos accurately mapped to the given interest
  Future<void> filterByInterest(InterestSearchItem item) async {
    isFilterLoading.value = true;
    final queryName = item.name.toLowerCase().trim();
    final allKeywords = item.relatedKeywords.map((k) => k.toLowerCase().trim()).toSet();
    allKeywords.add(queryName);

    try {
      // 1. Accurate local matching against video metadata, user category, and tags
      final List<Post> localMatches = [];
      final Set<int> addedIds = {};

      for (final post in postsList) {
        bool matches = false;

        // Check creator category, subcategory, topic configuration under Interests
        final userCat = post.user?.categoryName?.toLowerCase().trim();
        final userSub = post.user?.subCategoryName?.toLowerCase().trim();
        final userTopic = post.user?.topicName?.toLowerCase().trim();

        if (userCat != null && allKeywords.contains(userCat)) matches = true;
        if (userSub != null && allKeywords.contains(userSub)) matches = true;
        if (userTopic != null && allKeywords.contains(userTopic)) matches = true;

        // Check hashtags
        final hash = (post.hashtags ?? '').toLowerCase();
        for (final kw in allKeywords) {
          final cleanKw = kw.replaceAll(' ', '');
          if (hash.contains(cleanKw)) {
            matches = true;
            break;
          }
        }

        // Check post description with typo-tolerance or substring
        final desc = (post.description ?? '').toLowerCase();
        for (final kw in allKeywords) {
          if (desc.contains(kw)) {
            matches = true;
            break;
          }
        }

        if (matches && (post.id == null || !addedIds.contains(post.id))) {
          if (post.id != null) addedIds.add(post.id!);
          localMatches.add(post);
        }
      }

      // 2. Supplement from backend if local matches are limited
      if (localMatches.length < 8) {
        try {
          final cleanTag = queryName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          final hashtagReels = await PostService.instance.fetchPostsByHashtag(
            type: PostType.reels,
            hashTag: cleanTag,
            lastItemId: null,
          );
          final searchVideos = await SearchService.instance.searchPost(
            keyword: queryName,
            type: '1,3', // reels and videos
          );

          for (final p in [...(hashtagReels?.posts ?? []), ...searchVideos]) {
            if (p.id != null) {
              if (!addedIds.contains(p.id)) {
                addedIds.add(p.id!);
                localMatches.add(p);
              }
            } else {
              localMatches.add(p);
            }
          }
        } catch (e) {
          Loggers.error('Backend search fetch error: $e');
        }
      }

      displayedPosts.assignAll(localMatches);
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
        hashtag: (hashtag != null && hashtag.isNotEmpty)
            ? hashtag
            : primaryHashtag.value,
        index: 0,
      ),
      preventDuplicates: false,
    );
  }

  void onPostTap(Post post) {
    switch (post.postType) {
      case PostType.reel:
        final allReels =
            displayedPosts.where((p) => p.postType == PostType.reel).toList();
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
