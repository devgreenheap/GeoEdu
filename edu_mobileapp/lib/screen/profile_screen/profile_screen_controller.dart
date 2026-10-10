import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/controller/profile_controller.dart';
import 'package:geoedu/common/enum/chat_enum.dart';
import 'package:geoedu/common/extensions/list_extension.dart';
import 'package:geoedu/common/extensions/user_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/moderator_service.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/chat/chat_thread.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/model/post_story/story/story_model.dart';
import 'package:geoedu/model/post_story/user_post_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/blocked_user_screen/block_user_controller.dart';
import 'package:geoedu/screen/chat_screen/chat_screen.dart';
import 'package:geoedu/screen/create_feed_screen/create_feed_screen.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen.dart';
import 'package:geoedu/screen/post_screen/post_screen_controller.dart';
import 'package:geoedu/screen/reels_screen/reel/reel_page_controller.dart';
import 'package:geoedu/screen/report_sheet/report_sheet.dart';
import 'package:geoedu/screen/story_view_screen/story_view_screen.dart';
import 'package:geoedu/utilities/app_res.dart';

import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/model/star_score/star_score_model.dart';
import '../search_screen/search_screen_controller.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';

class ProfileScreenController extends BlockUserController
    with GetTickerProviderStateMixin {
  static const tag = 'PROFILE';
  RxInt selectedTabIndex = 0.obs;

  Rx<User?> userData;
  RxList<Post> reels = <Post>[].obs;
  RxList<Post> posts = <Post>[].obs;
  RxList<LiveHistory> myLives = <LiveHistory>[].obs;
  RxList<StarTransactionItem> gifterTransactions = <StarTransactionItem>[].obs;
  RxList<User> similarHosts = <User>[].obs;
  RxSet<int> liveHostUserIds = <int>{}.obs;
  RxMap<int, Livestream> liveStreamsByUserId = <int, Livestream>{}.obs;
  RxSet<int> similarHostFollowLoading = <int>{}.obs;
  StreamSubscription? _liveStreamsSub;

  RxBool isReelLoading = false.obs;
  RxBool isPostLoading = false.obs;
  RxBool isMyLivesLoading = false.obs;
  RxBool isGifterTransactionsLoading = false.obs;
  RxBool isSimilarHostsLoading = false.obs;
  final PageController pageController = PageController();
  RxBool isUserNotFound = false.obs;
  Setting? settingData = SessionManager.instance.getSettings();
  RxBool isFollowUnFollowInProcess = false.obs;
  late ProfileController profileController;
  final Function(User? user)? onUserUpdate;

  ProfileScreenController(this.userData, this.onUserUpdate);

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<ProfileController>(tag: '${userData.value?.id}')) {
      profileController =
          Get.find<ProfileController>(tag: '${userData.value?.id}');
      userData.value = profileController.user;
    } else {
      profileController = Get.put(ProfileController(userData.value),
          tag: '${userData.value?.id}');
    }
    userData.listen((p0) {
      onUserUpdate?.call(p0);
    });
    listenToRealTimeLiveHosts();
  }

  @override
  void onReady() {
    super.onReady();
    iniData();
  }

  @override
  void onClose() {
    _liveStreamsSub?.cancel();
    pageController.dispose();
    super.onClose();
  }

  void listenToRealTimeLiveHosts() {
    try {
      _liveStreamsSub = FirebaseFirestore.instance
          .collection(FirebaseConst.liveStreams)
          .withConverter(
            fromFirestore: (snapshot, options) => Livestream.fromJson(snapshot.data()!),
            toFirestore: (Livestream livestream, options) => livestream.toJson(),
          )
          .snapshots()
          .listen((snapshot) {
        final currentProfileId = userData.value?.id?.toInt();
        final myId = SessionManager.instance.getUserID();
        final Map<int, Livestream> map = {};
        final Set<int> ids = {};

        for (final doc in snapshot.docs) {
          final stream = doc.data();
          final hostId = stream.hostId?.toInt() ?? stream.hostUser?.userId?.toInt();
          if (hostId != null && hostId != currentProfileId && hostId != myId) {
            ids.add(hostId);
            map[hostId] = stream;
          }
        }

        liveHostUserIds.assignAll(ids);
        liveStreamsByUserId.assignAll(map);
      }, onError: (e) {
        Loggers.error('Error listening to liveStreams: $e');
      });
    } catch (e) {
      Loggers.error('listenToRealTimeLiveHosts error: $e');
    }
  }

  Future<void> fetchSimilarHosts() async {
    isSimilarHostsLoading.value = true;
    try {
      final currentProfileId = userData.value?.id?.toInt();
      final myId = SessionManager.instance.getUserID();
      final users = await UserService.instance.searchUsers(limit: 15, keyWord: '');
      similarHosts.assignAll(
        users.where((u) => u.id != currentProfileId && u.id != myId),
      );
    } catch (e) {
      Loggers.error('fetchSimilarHosts error: $e');
    } finally {
      isSimilarHostsLoading.value = false;
    }
  }

  Future<void> toggleFollowSimilarHost(User host) async {
    final hostId = host.id;
    if (hostId == null || similarHostFollowLoading.contains(hostId)) return;
    similarHostFollowLoading.add(hostId);

    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: hostId.toString())) {
      followController = Get.find<FollowController>(tag: hostId.toString());
      followController.updateUser(host);
    } else {
      followController = Get.put(FollowController(host.obs), tag: hostId.toString());
    }

    try {
      final updated = await followController.followUnFollowUser();
      if (updated != null) {
        final idx = similarHosts.indexWhere((u) => u.id == hostId);
        if (idx != -1) {
          similarHosts[idx] = updated;
          similarHosts.refresh();
        }
      }
    } catch (e) {
      Loggers.error('toggleFollowSimilarHost error: $e');
    } finally {
      similarHostFollowLoading.remove(hostId);
    }
  }

  void openLiveStreamForHost(User host) {
    final stream = liveStreamsByUserId[host.id];
    if (stream != null) {
      Get.to(() => LiveStreamAudienceScreen(livestream: stream, isHost: false));
    }
  }

  iniData() {
    final myId = SessionManager.instance.getUserID();
    final profileId = userData.value?.id?.toInt() ?? 0;
    final isMe = profileId == 0 || profileId == myId;
    final isHost = userData.value?.isHost == 1 ||
        (isMe && SessionManager.instance.getUser()?.isHost == 1);
    Future.wait([
      fetchUserDetail(),
      fetchReel(),
      fetchPost(),
      if (isHost || isMe) fetchMyLives(),
      fetchSimilarHosts(),
      fetchGifterTransactions(),
    ]);
  }

  void onTabChanged(int value) {
    selectedTabIndex.value = value;
    final myId = SessionManager.instance.getUserID();
    final profileId = userData.value?.id?.toInt() ?? 0;
    final isMe = profileId == 0 || profileId == myId;
    final isHost = userData.value?.isHost == 1 ||
        (isMe && SessionManager.instance.getUser()?.isHost == 1);
    if ((isHost || isMe) && (value == 0 || value == 1) && myLives.isEmpty && !isMyLivesLoading.value) {
      fetchMyLives();
    }
  }

  Future<void> fetchUserDetail() async {
    isLoading.value = true;
    User? user = await UserService.instance
        .fetchUserDetails(userId: userData.value?.id?.toInt());
    profileController.updateUser(user);
    isLoading.value = false;
    if (user != null) {
      userData.value = user;
      final myId = SessionManager.instance.getUserID();
      final isMe = (user.id?.toInt() ?? 0) == myId;
      final isHost = user.isHost == 1 ||
          (isMe && SessionManager.instance.getUser()?.isHost == 1);
      if (isHost || isMe) {
        fetchMyLives();
      }
    } else {
      isUserNotFound.value = true;
    }
  }

  Future<void> fetchReel({bool isEmpty = false}) async {
    if (isReelLoading.value) return;
    isReelLoading.value = true;
    try {
      UserPostData? items = await PostService.instance.fetchUserPosts(
          type: PostType.reels,
          userId: userData.value?.id?.toInt(),
          lastItemId: isEmpty ? null : reels.lastOrNull?.id?.toInt());
      if (isEmpty) reels.clear();

      if (reels.isEmpty) {
        reels.addAll(items?.pinnedPostList ?? []);
      }

      for (var post in (items?.posts ?? [])) {
        if (reels.firstWhereOrNull((element) => element.id == post.id) ==
            null) {
          reels.add(post);
        }
      }
    } catch (e) {
      Loggers.error('Fetch Reel Error : $e');
    } finally {
      isReelLoading.value = false;
    }
  }

  Future<void> fetchPost({bool isEmpty = false}) async {
    if (isPostLoading.value) return;
    isPostLoading.value = true;
    // Fetch user posts
    UserPostData? items = await PostService.instance.fetchUserPosts(
      type: PostType.posts,
      userId:
          userData.value?.id?.toInt() ?? SessionManager.instance.getUserID(),
      lastItemId: isEmpty ? null : posts.lastOrNull?.id?.toInt(),
    );

    if (isEmpty) {
      posts.clear();
    }
    if (posts.isEmpty) {
      posts.addAll(items?.pinnedPostList ?? []);
    }

    for (var post in (items?.posts ?? [])) {
      if (posts.firstWhereOrNull((element) => element.id == post.id) == null) {
        posts.add(post);
      }
    }
    isPostLoading.value = false;
    posts.refresh();
  }

  Future<void> fetchMyLives({bool reset = false}) async {
    if (isMyLivesLoading.value) return;
    isMyLivesLoading.value = true;
    try {
      final myId = SessionManager.instance.getUserID();
      final profileId = userData.value?.id?.toInt() ?? 0;
      final isMe = profileId == 0 || profileId == myId;

      // 1. Primary backend query:
      // When viewing own profile, pass null so backend authorizes via authtoken header ($authUser->id)
      // When viewing another user's profile, pass their profileId
      int? queryUserId = isMe ? null : (profileId > 0 ? profileId : null);

      LiveHistoryResponse response = await CommonService.instance.fetchMyLives(
        userId: queryUserId,
        lastItemId: reset ? null : myLives.lastOrNull?.id,
      );

      List<LiveHistory> fetchedList = response.data ?? [];

      // If viewing own profile and backend returned empty, try explicit fallback query with user ID
      if (fetchedList.isEmpty && isMe && (profileId > 0 || myId > 0)) {
        try {
          final fallbackId = profileId > 0 ? profileId : myId;
          final fallbackResponse = await CommonService.instance.fetchMyLives(
            userId: fallbackId,
            lastItemId: reset ? null : myLives.lastOrNull?.id,
          );
          if (fallbackResponse.data != null && fallbackResponse.data!.isNotEmpty) {
            fetchedList = fallbackResponse.data!;
          }
        } catch (_) {}
      }

      final targetUid = (profileId > 0) ? profileId : myId;
      final localSessions = LiveHistoryStorage.getLocalSessions(targetUid);

      // Merge backend items and local completed sessions
      final Map<int, LiveHistory> merged = {};
      for (var live in fetchedList) {
        if (live.id != null) {
          merged[live.id!] = live;
          // Cache server sessions to local storage so they load instantly on next open
          LiveHistoryStorage.saveLiveSession(live);
        }
      }
      for (var live in localSessions) {
        if (live.id != null && !merged.containsKey(live.id)) {
          merged[live.id!] = live;
        }
      }

      // Fallback: If both empty, try querying recorded lives for this user from server
      if (merged.isEmpty) {
        try {
          final recResponse = await CommonService.instance.fetchRecordedLives();
          final recordings = recResponse.data ?? [];
          final userRecordings = recordings.where((r) {
            if (targetUid > 0 && r.userId == targetUid) return true;
            if (myId > 0 && r.userId == myId) return true;
            if (userData.value?.username != null &&
                r.hostUsername == userData.value!.username) {
              return true;
            }
            return false;
          }).toList();
          for (var live in userRecordings) {
            if (live.id != null) {
              merged[live.id!] = live;
              LiveHistoryStorage.saveLiveSession(live);
            }
          }
        } catch (_) {}
      }

      final combined = merged.values.toList();
      combined.sort((a, b) {
        final dateA = a.sessionDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.sessionDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      if (reset) myLives.clear();
      myLives.assignAll(combined.isNotEmpty ? combined : fetchedList);
    } catch (e) {
      Loggers.error('fetchMyLives error: $e');
      final myId = SessionManager.instance.getUserID();
      final profileId = userData.value?.id?.toInt() ?? 0;
      final targetUid = (profileId > 0) ? profileId : myId;
      final localSessions = LiveHistoryStorage.getLocalSessions(targetUid);
      if (localSessions.isNotEmpty && myLives.isEmpty) {
        myLives.assignAll(localSessions);
      }
    } finally {
      isMyLivesLoading.value = false;
    }
  }

  Future<bool> deleteLive(LiveHistory live) async {
    if (live.id == null) return false;
    try {
      final myId = SessionManager.instance.getUserID();
      final uid = live.userId ?? myId;
      LiveHistoryStorage.removeSession(uid, live.id!);
      final result = await CommonService.instance.deleteLiveHistory(liveStreamId: live.id!);
      if (result.status == true) {
        myLives.removeWhere((element) => element.id == live.id);
        return true;
      }
      myLives.removeWhere((element) => element.id == live.id);
      return true;
    } catch (_) {
      myLives.removeWhere((element) => element.id == live.id);
      return true;
    }
  }

  Future<void> fetchGifterTransactions() async {
    isGifterTransactionsLoading.value = true;
    try {
      final res = await GiftWalletService.instance.fetchStarTransactions(type: 'all');
      gifterTransactions.assignAll(res.transactions ?? []);
    } catch (e) {
      Loggers.error('fetchGifterTransactions error: $e');
    } finally {
      isGifterTransactionsLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    final myId = SessionManager.instance.getUserID();
    final profileId = userData.value?.id?.toInt() ?? 0;
    final isMe = profileId == 0 || profileId == myId;
    final isHost = userData.value?.isHost == 1 ||
        (isMe && SessionManager.instance.getUser()?.isHost == 1);
    await Future.wait([
      fetchUserDetail(),
      fetchPost(isEmpty: true),
      fetchReel(isEmpty: true),
      if (isHost || isMe) fetchMyLives(reset: true),
      fetchSimilarHosts(),
      fetchGifterTransactions(),
    ]);
  }

  void onAddPost({Post? post, CreateFeedType? type}) {
    if (post == null) return; // Exit early if post is null

    // Determine the target list based on the type
    List<Post> targetList = type == CreateFeedType.feed ? posts : reels;

    // Find the position to insert the post after pinned posts
    int pinnedCount =
        targetList.where((element) => element.isPinned == 1).length;

    // Insert the post at the appropriate position
    targetList.insert(pinnedCount, post);
  }

  void onAddStory(Story? story) {
    if (story == null) return; // Exit early if story is null
    userData.update((val) {
      val?.stories?.add(story);
    });
  }

  Future<StatusModel> unpinPost(Post post) async {
    StatusModel response =
        await PostService.instance.unpinPost(postId: post.id?.toInt() ?? -1);
    return response;
  }

  Future<StatusModel> pinPost(Post post) async {
    StatusModel response =
        await PostService.instance.pinPost(postId: post.id?.toInt() ?? -1);
    return response;
  }

  onUpdateUser(User? user) {
    userData.value = user;
    userData.refresh();
  }

  void reportUser(User? user) {
    Get.bottomSheet(ReportSheet(id: user?.id, reportType: ReportType.user),
        isScrollControlled: true);
  }

  onPinUnpinReel(Post post) async {
    if (post.isPinned == 0) {
      List<Post> existingPinPost = [];

      for (var element in reels) {
        if (element.isPinned == 1) {
          existingPinPost.add(element);
        }
      }

      if ((settingData?.maxPostPins ?? AppRes.maxPinFeed) >
          existingPinPost.length) {
        StatusModel model = await pinPost(post);
        if (model.status == true) {
          reels.removeWhere((element) => element.id == post.id);
          post.isPinned = 1;
          reels.insert(0, post);
          reels.refresh();
        }
      } else {
        // showSnackBar('You can maximum ${settingData.value?.maxPostPins} pinned');
        showSnackBar(LKey.pinLimitExceeded.trParams({
          'pin_count':
              '${settingData?.maxPostPins ?? AppRes.maxPinFeed.toString()}'
        }));
      }
    } else {
      StatusModel response = await unpinPost(post);
      if (response.status == true) {
        fetchReel(isEmpty: true);
      }
    }
  }

  onDeleteReel(Post post, {required bool isModerator}) {
    Get.bottomSheet(
      ConfirmationSheet(
          title: LKey.deletePostTitle.tr,
          onTap: () async {
            showLoader();
            StatusModel model;
            if (isModerator) {
              model = await ModeratorService.instance
                  .moderatorDeletePost(postId: post.id?.toInt() ?? -1);
            } else {
              model = await PostService.instance
                  .deletePost(postId: post.id?.toInt() ?? -1);
            }
            if (model.status == true) {
              Get.delete<ReelController>(tag: '${post.id}');
              reels.removeWhere((element) => element.id == post.id);
              post = Post();
            }
            stopLoader();
          },
          description: LKey.deletePostMessage.tr),
    );
  }

  void toggleBlockUnblock(isBlock) {
    if (isBlock) {
      unblockUser(userData.value, () {
        userData.update((val) => val?.updateBlockStatus(false));
      });
    } else {
      blockUser(userData.value, () {
        userData.update(
          (val) {
            val?.updateBlockStatus(true);
          },
        );
      });
    }
  }

  updatePinPost(Post post) async {
    List<Post> existingPinPost = [];

    for (var element in posts) {
      if (element.isPinned == 1) {
        existingPinPost.add(element);
      }
    }

    if ((settingData?.maxPostPins ?? AppRes.maxPinFeed) >
        existingPinPost.length) {
      StatusModel response = await pinPost(post);
      if (response.status == true) {
        posts.removeWhere((element) => element.id == post.id);
        post.isPinned = 1;
        final controller = Get.find<PostScreenController>(tag: '${post.id}');
        controller.updatePost(post);
        posts.insert(0, post);
        posts.refresh();
      }
    } else {
      // showSnackBar('You can maximum ${settingData.value?.maxPostPins} pinned');
      showSnackBar(LKey.pinLimitExceeded.trParams({
        'pin_count':
            '${settingData?.maxPostPins ?? AppRes.maxPinFeed.toString()}'
      }));
    }
  }

  updateUnPinPost(Post post) async {
    StatusModel response = await unpinPost(post);
    if (response.status == true) {
      final controller = Get.find<PostScreenController>(tag: '${post.id}');
      post.isPinned = 0;
      controller.updatePost(post);
      fetchPost(isEmpty: true);
    }
  }

  Future<void> followUnFollowUser() async {
    int userId = userData.value?.id ?? -1;
    if (isFollowUnFollowInProcess.value) return;
    isFollowUnFollowInProcess.value = true;

    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: userId.toString())) {
      followController = Get.find<FollowController>(tag: userId.toString());
      followController.updateUser(userData.value);
    } else {
      followController = Get.put(FollowController(userData), tag: userId.toString());
    }

    User? user = await followController.followUnFollowUser();
    isFollowUnFollowInProcess.value = false;
    userData.update((val) {
      val?.isFollowing = user?.isFollowing;
      val?.followerCount = user?.followerCount;
      val?.followingCount = user?.followingCount;
    });
    profileController.updateUser(userData.value);

    if (Get.isRegistered<SearchScreenController>()) {
      final searchController = Get.find<SearchScreenController>();
      searchController.updateUserInList(userData.value);
    }
  }

  void handlePublishOrMessageBtn(bool isMe) {
    if (isMe) {
      // Get.bottomSheet(PostOptionsSheet(controller: this),
      //     isScrollControlled: true);
      Get.to(() => EditProfileScreen(onUpdateUser: onUpdateUser));
    } else {
      ChatThread conversation = ChatThread(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          lastMsg: '',
          msgCount: 0,
          isDeleted: false,
          deletedId: 0,
          iAmBlocked: false,
          iBlocked: userData.value?.isBlock ?? false,
          requestType: UserRequestAction.accept.title,
          chatType: ChatType.approved,
          conversationId: [
            SessionManager.instance.getUserID(),
            userData.value?.id
          ].conversationId,
          userId: userData.value?.id);
      conversation.chatUser = userData.value?.appUser;
      Get.to(() =>
          ChatScreen(conversationUser: conversation, user: userData.value));
    }
  }

  void onStoryTap(bool isStoryAvailable) {
    if (isStoryAvailable) {
      userData.value?.checkIsBlocked(() {
        Get.bottomSheet(
                StoryViewSheet(
                  stories: [userData.value!],
                  userIndex: 0,
                  onUpdateDeleteStory: (story) {
                    userData.update((val) => (val?.stories ?? [])
                        .removeWhere((element) => element.id == story?.id));
                  },
                ),
                isScrollControlled: true,
                ignoreSafeArea: false)
            .then((value) {
          // For check story view or not
          fetchUserDetail();
        });
      });
    }
  }

  void freezeUnfreezeUser(bool isFreeze) async {
    StatusModel result;
    showLoader();
    if (isFreeze) {
      result = await ModeratorService.instance
          .moderatorUnFreezeUser(userId: userData.value?.id);
    } else {
      result = await ModeratorService.instance
          .moderatorFreezeUser(userId: userData.value?.id);
    }
    stopLoader();

    if (result.status == true) {
      userData.update((val) => val?.isFreez = isFreeze ? 0 : 1);
    }
  }
}
