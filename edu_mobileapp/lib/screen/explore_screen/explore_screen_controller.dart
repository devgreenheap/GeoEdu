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

  @override
  void onInit() {
    super.onInit();
    fetchExplorePageData();
  }

  Future<void> fetchExplorePageData() async {
    isLoading.value = true;
    final data = await PostService.instance.fetchExplorePageData();
    List<HighPostHashtags> highHashtags = List.from(data?.highPostHashtags ?? []);

    // Keep only hashtags that have posts
    highHashtags.removeWhere((h) => h.postList == null || h.postList!.isEmpty);

    // Fallback if no hashtags with posts exist:
    // fetch discover reels & discover posts to populate the Explore grid
    if (highHashtags.isEmpty) {
      try {
        final discoverReels =
            await PostService.instance.fetchPostsDiscover(type: PostType.reels);
        final discoverPosts =
            await PostService.instance.fetchPostsDiscover(type: PostType.posts);
        final combined = <Post>[...discoverReels, ...discoverPosts];
        if (combined.isNotEmpty) {
          highHashtags.add(HighPostHashtags(
            id: 0,
            hashtag: 'Explore',
            postCount: combined.length,
            postList: combined,
          ));
        }
      } catch (e) {
        Loggers.error('Error fetching fallback discover posts: $e');
      }
    }

    explorePageData.value = ExplorePageData(
      hashtags: data?.hashtags ?? [],
      highPostHashtags: highHashtags,
    );
    isLoading.value = false;
  }

  void onExploreTap(String? hashtag) {
    Get.to(() => HashtagScreen(hashtag: hashtag ?? '', index: 0),
        preventDuplicates: false);
  }

  void onPostTap(Post post) {
    switch (post.postType) {
      case PostType.reel:
        Get.to(() => ReelsScreen(reels: [post].obs, position: 0));
        break;
      case PostType.image:
        Get.to(() => SinglePostScreen(post: post, isFromNotification: false));
        break;
      case PostType.video:
        Get.to(() => VideoPlayerScreen(post: post));
        break;
      case PostType.text:
        break;
      case PostType.none:
        Loggers.error('Post Type none');
        break;
    }
  }

  void onScanQrCode() {
    Get.to(() => const ScanQrCodeScreen());
  }
}
