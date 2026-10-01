import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/extensions/list_extension.dart';
import 'package:geoedu/common/extensions/user_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/interest_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/recorded_video_player_screen.dart';
import 'package:geoedu/model/livestream/live_room_item.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/live_stream/go_live_setup_screen.dart';
import 'package:geoedu/screen/profile_screen/profile_screen.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:geoedu/utilities/firebase_const.dart';


class LiveStreamSearchScreenController extends BaseController {
  FirebaseFirestore db = FirebaseFirestore.instance;
  RxList<Livestream> livestreamList = <Livestream>[].obs;
  RxList<Livestream> livestreamFilterList = <Livestream>[].obs;
  StreamSubscription<QuerySnapshot<Livestream>>? livestreamListListener;

  final firebaseFirestoreController = Get.find<FirebaseFirestoreController>();

  Setting? get setting => SessionManager.instance.getSettings();

  List<DummyLive> get dummyLives => setting?.dummyLives ?? [];

  // Category filter state
  RxList<Category> filterCategories = <Category>[].obs;
  RxInt selectedCategoryIndex = 0.obs;
  Rxn<SubCategory> selectedSubCategory = Rxn<SubCategory>();
  Rxn<Division> selectedDivision = Rxn<Division>();
  Rxn<Topic> selectedTopic = Rxn<Topic>();

  // User interests (ids from tbl_interests) — used to auto-select category
  RxList<Interest> myInterests = <Interest>[].obs;
  RxList<Interest> interestCatalog = <Interest>[].obs;

  // Favorites
  RxSet<int> favoriteStreamIds = <int>{}.obs;

  // "Live Chatrooms" filter chips: All / Following / Audio / Love / New
  static const List<String> roomFilterLabels = ['All', 'Following', 'Audio', 'Love❤️', '🔥New'];
  RxInt selectedRoomFilterIndex = 0.obs;
  RxSet<int> followingHostIds = <int>{}.obs;
  static const Duration _newRoomWindow = Duration(minutes: 30);

  Future<void> fetchFollowingHostIds() async {
    try {
      final myId = SessionManager.instance.getUserID();
      final following = await UserService.instance.fetchMyFollowing(lastItemId: -1, userId: myId);
      followingHostIds.assignAll(following.map((f) => f.toUserId).whereType<int>());
    } catch (e) {
      Loggers.error('fetchFollowingHostIds error: $e');
    }
  }

  void onRoomFilterSelected(int index) => selectedRoomFilterIndex.value = index;

  // Recorded sessions — shown appended after the live ones in the same
  // Live Classrooms row, filtered by the same category selection.
  RxList<LiveHistory> recordedLives = <LiveHistory>[].obs;
  RxBool isRecordedLivesLoading = false.obs;

  bool _dummyUsersReady = false;

  /// Live video + live audio rooms only (no recordings), wrapped for the
  /// unified Home grid / Popular Hosts row. Recomputed on read — callers
  /// wrap this in their own `Obx` watching `livestreamFilterList` and
  /// `AudioCallListController.audioRooms` directly, so it always reflects
  /// current data without a separate cached Rx field to keep in sync.
  List<LiveRoomItem> _liveVideoAndAudioItems() {
    final items = <LiveRoomItem>[
      for (final stream in livestreamFilterList)
        LiveRoomItem.video(
          stream,
          onTap: () => onLiveUserTap(stream),
          coHostAvatars: stream
              .getCoHostUsers(firebaseFirestoreController.users)
              .map((user) => user.profile)
              .whereType<String>()
              .where((photo) => photo.isNotEmpty)
              .toList(),
        ),
    ];
    if (Get.isRegistered<AudioCallListController>()) {
      final audioController = Get.find<AudioCallListController>();
      for (final room in audioController.audioRooms) {
        items.add(LiveRoomItem.audio(room, onTap: () => audioController.joinAudioRoom(room)));
      }
    }
    return items;
  }

  /// Merged grid feed for Home/AllRooms: live video + live audio + recorded
  /// Merged grid feed for Home/AllRooms: live video + live audio + recorded
  /// sessions, prioritized by user interests when under "All", then most recent first.
  List<LiveRoomItem> get mergedRoomItems {
    final items = _liveVideoAndAudioItems();
    for (final recording in recordedLives) {
      items.add(LiveRoomItem.recorded(recording, onTap: () {
        final url = recording.videoUrl;
        if (url == null || url.isEmpty) return;
        Get.to(() => RecordedVideoPlayerScreen(videoUrl: url));
      }));
    }
    if (selectedCategoryIndex.value == 0 && myInterests.isNotEmpty) {
      final interestNames = myInterests
          .map((i) => i.name?.toLowerCase().trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      items.sort((a, b) {
        final aMatch = interestNames.contains(a.categoryName.toLowerCase().trim()) ? 1 : 0;
        final bMatch = interestNames.contains(b.categoryName.toLowerCase().trim()) ? 1 : 0;
        if (aMatch != bMatch) {
          return bMatch.compareTo(aMatch);
        }
        return b.sortTimestamp.compareTo(a.sortTimestamp);
      });
    } else {
      items.sort((a, b) => b.sortTimestamp.compareTo(a.sortTimestamp));
    }
    return items;
  }

  /// Home's "Live Chatrooms" grid applies the filter chip on top of
  /// [mergedRoomItems]. Recorded sessions have no live host/hashtag, so
  /// they only ever show under "All".
  List<LiveRoomItem> get filteredHomeRoomItems {
    final items = mergedRoomItems;
    switch (selectedRoomFilterIndex.value) {
      case 1: // Following
        return items.where((i) => followingHostIds.contains(i.hostUserId)).toList();
      case 2: // Audio
        return items.where((i) => i.variant == RoomCardVariant.audio).toList();
      case 3: // Love
        return items.where((i) => i.hashtagText.toLowerCase().contains('love') ||
            i.hashtagText.toLowerCase().contains('romance')).toList();
      case 4: // New — created within the last 30 minutes
        final cutoff = DateTime.now().subtract(_newRoomWindow).millisecondsSinceEpoch;
        return items.where((i) => i.variant != RoomCardVariant.recorded && i.sortTimestamp >= cutoff).toList();
      default:
        return items;
    }
  }

  /// "Popular Hosts" row: currently-live video/audio rooms, prioritized by
  /// user's selected interests, then ranked by viewer/listener count.
  List<LiveRoomItem> get popularLiveHosts {
    final items = _liveVideoAndAudioItems();
    if (myInterests.isNotEmpty) {
      final interestNames = myInterests
          .map((i) => i.name?.toLowerCase().trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      items.sort((a, b) {
        final aMatch = interestNames.contains(a.categoryName.toLowerCase().trim()) ? 1 : 0;
        final bMatch = interestNames.contains(b.categoryName.toLowerCase().trim()) ? 1 : 0;
        if (aMatch != bMatch) {
          return bMatch.compareTo(aMatch);
        }
        return b.subCount.compareTo(a.subCount);
      });
    } else {
      items.sort((a, b) => b.subCount.compareTo(a.subCount));
    }
    return items.take(10).toList();
  }

  @override
  void onReady() {
    super.onReady();
    _initLiveStreams();
  }

  Future<void> _initLiveStreams() async {
    // Start fetching favorites and categories immediately in parallel while
    // dummy users are being set up
    final favoritesFuture = fetchFavoriteUsers();
    final categoriesFuture = fetchFilterCategories();
    final followingFuture = fetchFollowingHostIds();
    final interestsFuture = fetchMyInterestsForHome();

    await addDummyUsers();
    _dummyUsersReady = true;

    await Future.wait({
      fetchLiveStreams(),
      favoritesFuture,
      categoriesFuture,
      followingFuture,
      interestsFuture,
    });

    // Reorder categories to show user's interests first, then auto-select
    _reorderCategoriesByInterests();
    _autoSelectCategoryFromInterests();

    fetchRecordedLives();
  }

  Future<void> fetchRecordedLives() async {
    isRecordedLivesLoading.value = true;
    try {
      int? categoryId;
      if (selectedCategoryIndex.value > 0 &&
          selectedCategoryIndex.value - 1 < filterCategories.length) {
        categoryId = filterCategories[selectedCategoryIndex.value - 1].id;
      }
      final response = await CommonService.instance.fetchRecordedLives(categoryId: categoryId);
      recordedLives.value = response.data ?? [];
    } catch (e) {
      Loggers.error('fetchRecordedLives error: $e');
    }
    isRecordedLivesLoading.value = false;
  }

  @override
  void onClose() {
    super.onClose();
    livestreamListListener?.cancel();
  }

  Future<void> fetchLiveStreams() async {
    isLoading.value = true;

    livestreamListListener = db
        .collection(FirebaseConst.liveStreams)
        .withConverter(
          fromFirestore: (snapshot, options) =>
              Livestream.fromJson(snapshot.data()!),
          toFirestore: (Livestream livestream, options) => livestream.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      final activeStreams = <Livestream>[];
      for (var doc in snapshot.docs) {
        final stream = doc.data();
        if (stream.roomID != null && stream.roomID!.isNotEmpty) {
          activeStreams.add(stream);
          if (stream.hostId != null && stream.hostId != -1) {
            firebaseFirestoreController.fetchUserIfNeeded(stream.hostId ?? -1);
          }
          for (var coHostId in (stream.coHostIds ?? [])) {
            firebaseFirestoreController.fetchUserIfNeeded(coHostId);
          }
        }
      }

      livestreamList.value = activeStreams;
      removeDummyLive();
      _applyFilter();
      _assignHostUsersToStreams();
      isLoading.value = false;
    });
  }

  void removeStreamLocally(String? roomId, int? hostId) {
    livestreamList.removeWhere((s) =>
        (roomId != null && s.roomID == roomId) ||
        (hostId != null && s.hostId == hostId));
    _applyFilter();
  }

  void _assignHostUsersToStreams() {
    final userMap = _userMapFromList(firebaseFirestoreController.users);
    for (var stream in livestreamList) {
      stream.hostUser = userMap[stream.hostId];
    }
  }

  Map<int, AppUser> _userMapFromList(List<AppUser> list) {
    return {
      for (var user in list)
        if (user.userId != null) user.userId!: user,
    };
  }

  void onLiveUserTap(Livestream stream) async {
    User? myUser = SessionManager.instance.getUser();
    if (stream.hostId == myUser?.id) {
      Get.to(() => LivestreamHostScreen(isHost: true, livestream: stream));
    } else {
      Get.to(() => LiveStreamAudienceScreen(isHost: false, livestream: stream));
    }
  }

  onSearchChange(String value) {
    livestreamFilterList.value = livestreamList.search(value, (p0) {
      return p0.hostUser?.username ?? '';
    }, (p1) => p1.description ?? '');
  }

  void toggleFavorite(Livestream stream) {
    final hostId = stream.hostId;
    if (hostId == null) return;
    if (favoriteStreamIds.contains(hostId)) {
      favoriteStreamIds.remove(hostId);
      UserService.instance.unFavoriteUser(userId: hostId);
    } else {
      favoriteStreamIds.add(hostId);
      UserService.instance.favoriteUser(userId: hostId);
    }
  }

  /// Pull-to-refresh on the Home page. Live streams and audio rooms are
  /// already realtime via Firestore listeners (always current), so this
  /// only needs to re-pull the plain REST-backed pieces: categories,
  /// favorites, recorded sessions, and interests.
  Future<void> onHomeRefresh() async {
    await Future.wait([
      fetchFilterCategories(),
      fetchFavoriteUsers(),
      fetchRecordedLives(),
      fetchMyInterestsForHome(),
    ]);
    _reorderCategoriesByInterests();
    _autoSelectCategoryFromInterests();
  }

  Future<void> fetchFavoriteUsers() async {
    try {
      final favorites = await UserService.instance.fetchMyFavoriteUsers();
      favoriteStreamIds.clear();
      for (var fav in favorites) {
        final userId = fav.toUserId;
        if (userId != null) {
          favoriteStreamIds.add(userId);
        }
      }
    } catch (e) {
      Loggers.error('fetchFavoriteUsers error: $e');
    }
  }

  Future<void> fetchMyInterestsForHome() async {
    try {
      final catalogResult = await CommonService.instance.fetchInterests();
      interestCatalog.value = catalogResult.data ?? [];

      final myResult = await UserService.instance.fetchMyInterests();
      myInterests.value = myResult.data ?? [];
    } catch (e) {
      Loggers.error('fetchMyInterestsForHome error: $e');
    }
  }

  /// Reorders [filterCategories] so that categories matching the user's
  /// selected interests are placed at the front of the list, right after "All".
  void _reorderCategoriesByInterests() {
    if (myInterests.isEmpty || filterCategories.isEmpty) return;
    final interestNames = myInterests
        .map((i) => i.name?.toLowerCase().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();
    final matching = <Category>[];
    final others = <Category>[];
    for (final cat in filterCategories) {
      final catName = cat.name?.toLowerCase().trim() ?? '';
      if (interestNames.contains(catName)) {
        matching.add(cat);
      } else {
        others.add(cat);
      }
    }
    filterCategories.value = [...matching, ...others];
  }

  /// After categories load, auto-select the first category that matches
  /// one of the user's interests (by name, case-insensitive).
  void _autoSelectCategoryFromInterests() {
    if (myInterests.isEmpty || filterCategories.isEmpty) return;
    final interestNames = myInterests.map((i) => i.name?.toLowerCase().trim() ?? '').toSet();
    for (int i = 0; i < filterCategories.length; i++) {
      final catName = filterCategories[i].name?.toLowerCase().trim() ?? '';
      if (interestNames.contains(catName)) {
        selectedCategoryIndex.value = i + 1; // +1 because index 0 is "All"
        _applyFilter();
        return;
      }
    }
  }

  /// Called from the ChangeInterestSheet after the user saves their interests.
  Future<void> onInterestsSaved(List<Interest> newInterests) async {
    myInterests.value = newInterests;
    _reorderCategoriesByInterests();
    _autoSelectCategoryFromInterests();
    fetchRecordedLives();
  }

  Future<void> fetchFilterCategories() async {
    try {
      final result = await CommonService.instance.fetchCategorySubCategoryTopic();
      filterCategories.value = result.data ?? [];
      // If the previously-selected category no longer exists in the fresh
      // list (e.g. re-fetched on pull-to-refresh with a different count),
      // fall back to "All" rather than leaving a dangling index around.
      if (selectedCategoryIndex.value > filterCategories.length) {
        selectedCategoryIndex.value = 0;
        _applyFilter();
      }
    } catch (e) {
      Loggers.error('fetchFilterCategories error: $e');
    }
  }

  void onCategorySelected(int index) {
    selectedCategoryIndex.value = index;
    selectedSubCategory.value = null;
    selectedDivision.value = null;
    selectedTopic.value = null;
    _applyFilter();
    fetchRecordedLives();
  }

  void setHierarchicalFilter({
    required int categoryIndex,
    SubCategory? subCategory,
    Division? division,
    Topic? topic,
  }) {
    selectedCategoryIndex.value = categoryIndex;
    selectedSubCategory.value = subCategory;
    selectedDivision.value = division;
    selectedTopic.value = topic;
    _applyFilter();
    fetchRecordedLives();
  }

  void clearHierarchicalFilter() {
    selectedCategoryIndex.value = 0;
    selectedSubCategory.value = null;
    selectedDivision.value = null;
    selectedTopic.value = null;
    _applyFilter();
    fetchRecordedLives();
  }

  void _applyFilter() {
    List<Livestream> filtered;

    // Guard against a stale selection left pointing past the end of a
    // freshly re-fetched (possibly shorter/reordered) category list — e.g.
    // pull-to-refresh re-downloading categories while a category far down
    // the list is selected. Falls back to "All" instead of crashing.
    if (selectedCategoryIndex.value > filterCategories.length) {
      selectedCategoryIndex.value = 0;
    }

    if (selectedCategoryIndex.value == 0) {
      // "All" selected — show everything, but prioritize user's interests first
      filtered = List.from(livestreamList);
      if (myInterests.isNotEmpty) {
        final interestNames = myInterests
            .map((i) => i.name?.toLowerCase().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet();
        filtered.sort((a, b) {
          final aCat = a.categoryName?.toLowerCase().trim() ?? '';
          final bCat = b.categoryName?.toLowerCase().trim() ?? '';
          final aMatch = interestNames.contains(aCat) ? 1 : 0;
          final bMatch = interestNames.contains(bCat) ? 1 : 0;
          if (aMatch != bMatch) {
            return bMatch.compareTo(aMatch); // matched first
          }
          return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
        });
      }
    } else {
      final selectedCat = filterCategories[selectedCategoryIndex.value - 1];
      final targetSubCat = selectedSubCategory.value;
      final targetDiv = selectedDivision.value;
      final targetTop = selectedTopic.value;

      filtered = livestreamList.where((s) {
        // Category check
        bool matchCategory = false;
        if (s.categoryId == selectedCat.id) {
          matchCategory = true;
        } else if (s.hostId != null) {
          final hostUser = firebaseFirestoreController.users
              .firstWhereOrNull((u) => u.userId == s.hostId);
          if (hostUser?.categoryId == selectedCat.id) matchCategory = true;
        }
        if (!matchCategory) return false;

        // SubCategory check if selected
        if (targetSubCat != null) {
          bool matchSub = (s.subCategoryId == targetSubCat.id);
          if (!matchSub && s.hostId != null) {
            final hostUser = firebaseFirestoreController.users
                .firstWhereOrNull((u) => u.userId == s.hostId);
            if (hostUser?.subCategoryId == targetSubCat.id) matchSub = true;
          }
          if (!matchSub) return false;
        }

        // Topic check if selected
        if (targetTop != null) {
          bool matchTopic = (s.topicId == targetTop.id);
          if (!matchTopic && s.hostId != null) {
            final hostUser = firebaseFirestoreController.users
                .firstWhereOrNull((u) => u.userId == s.hostId);
            if (hostUser?.topicId == targetTop.id) matchTopic = true;
          }
          if (!matchTopic) return false;
        }

        return true;
      }).toList();
    }

    // Filter by selected live room language
    // Streams without languageId set are always shown
    final liveRoomLangId = SessionManager.instance.storage.read<int>(SessionKeys.liveRoomLanguageId);
    if (liveRoomLangId != null) {
      filtered = filtered.where((s) => s.languageId == null || s.languageId == liveRoomLangId).toList();
    }

    filtered.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    livestreamFilterList.value = filtered;
  }

  Future<void> addDummyUsers() async {
    try {
      final settingDummyLives = setting?.dummyLives ?? [];
      Loggers.info('Total dummy lives from settings: ${settingDummyLives.length}');

      // Fetch existing livestreams from Firestore
      final livestreamList = await db
          .collection(FirebaseConst.liveStreams)
          .withConverter<Livestream>(
            fromFirestore: (snapshot, _) => Livestream.fromJson(snapshot.data()!),
            toFirestore: (livestream, _) => livestream.toJson(),
          )
          .get();

      // Collect existing stream IDs
      final existingIds = livestreamList.docs.map((doc) => doc.id).toSet();

      for (var dummy in settingDummyLives) {
        final dummyId = dummy.userId;

        // Skip invalid IDs
        if (dummyId == null || dummyId == -1) continue;

        final alreadyExists = existingIds.contains('$dummyId');
        if (dummy.status == 1) {
          // Create or update dummy livestream
          await createLiveStream(dummy);
          Loggers.info('${alreadyExists ? 'Updated' : 'Created'} dummy livestream: $dummyId');
        } else if (alreadyExists && dummy.status == 0) {
          // Delete if status is inactive
          await deleteStreamOnFirebase(dummyId);
          Loggers.info('Deleted inactive dummy livestream: $dummyId');
        } else {
          Loggers.info('No action for dummy: $dummyId (exists: $alreadyExists, status: ${dummy.status})');
        }
      }
    } catch (e, _) {
      Loggers.error('Error in addDummyUsers: $e');
    }
  }

  Future<void> createLiveStream(DummyLive? dummyLive) async {
    User? dummyUser = dummyLive?.user;
    if (dummyUser == null) {
      Loggers.error('Dummy User Not found');
      return;
    }
    int userId = dummyLive?.userId ?? -1;

    DocumentReference livestreamRef = db.collection(FirebaseConst.liveStreams).doc('$userId');

    int time = DateTime.now().millisecondsSinceEpoch;

    // Livestream model — use DummyLive fields first, fallback to user fields
    Livestream livestream = dummyUser.livestream(
        type: LivestreamType.dummy,
        time: time,
        dummyUserLink: dummyLive?.link,
        isDummyLive: 1,
        description: dummyLive?.title,
        categoryId: dummyLive?.categoryId ?? dummyUser.categoryId,
        categoryName: dummyLive?.categoryName ?? dummyUser.categoryName,
        languageId: dummyLive?.languageId ?? dummyUser.languageId,
        languageName: dummyLive?.languageName ?? dummyUser.languageName);

    // LivestreamUser model
    AppUser? livestreamUser = dummyUser.appUser;

    // LivestreamUserState model
    LivestreamUserState livestreamUserState = dummyUser.streamState(time: time, stateType: LivestreamUserType.host);

    try {
      DocumentReference usersRef = db.collection(FirebaseConst.appUsers).doc('$userId');
      DocumentReference userStateRef = livestreamRef.collection(FirebaseConst.userState).doc('$userId');

      WriteBatch batch = db.batch();

      bool isExist = (await livestreamRef.get()).exists;
      bool isUserExist = (await usersRef.get()).exists;

      if (isExist) {
        // Update existing documents
        batch.update(livestreamRef, livestream.toJson());
        batch.update(userStateRef, livestreamUserState.toJson());
      } else {
        // Create new documents
        batch.set(livestreamRef, livestream.toJson());
        batch.set(userStateRef, livestreamUserState.toJson());
      }
      if (isUserExist) {
        batch.update(usersRef, livestreamUser.toJson());
      } else {
        batch.set(usersRef, livestreamUser.toJson());
      }

      await batch.commit();
      Loggers.success(isExist ? 'Updated Dummy Live' : 'Created Dummy Live');
    } catch (e, stackTrace) {
      Loggers.error('Failed to create/update live stream: $e');
      Loggers.error('StackTrace: $stackTrace');
    }
  }

  Future<void> deleteStreamOnFirebase(int? dummyUserId) async {
    if (dummyUserId == null) return;

    final String roomId = dummyUserId.toString();

    final DocumentReference livestreamRef = db.collection(FirebaseConst.liveStreams).doc(roomId);

    final CollectionReference usersStateRef = livestreamRef.collection(FirebaseConst.userState);

    final CollectionReference commentsRef = livestreamRef.collection(FirebaseConst.comments);

    try {
      // Fetch both collections in parallel
      final results = await Future.wait([
        usersStateRef.get(),
        commentsRef.get(),
      ]);

      final QuerySnapshot usersSnapshot = results[0];
      final QuerySnapshot commentsSnapshot = results[1];

      final WriteBatch batch = db.batch();

      // Queue deletions for user states
      for (final doc in usersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      Loggers.info('Queued ${usersSnapshot.size} user state deletions.');

      // Queue deletions for comments
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      Loggers.info('Queued ${commentsSnapshot.size} comment deletions.');

      // Delete the livestream document
      batch.delete(livestreamRef);

      // Commit all deletions in one batch
      await batch.commit();
      Loggers.success('Deleted live stream, user states, and comments from Firestore.');
      Loggers.error('Live Stream Search Delete The Data');
    } catch (e, stackTrace) {
      Loggers.error('Failed to delete live stream: $e');
      Loggers.error('StackTrace: $stackTrace');
    }
  }

  void removeDummyLive() {
    // Don't remove dummy streams until addDummyUsers has finished
    if (!_dummyUsersReady) return;

    final dummyStream = livestreamList.where((e) => e.isDummyLive == 1).toList();
    if (dummyStream.isEmpty) return;

    final settingDummyLives = setting?.dummyLives ?? [];

    if (setting?.liveDummyShow == 0) {
      for (var element in dummyStream) {
        deleteStreamOnFirebase(element.hostId);
      }
    } else {
      for (var element in dummyStream) {
        final shouldDelete = settingDummyLives.isEmpty ||
            !settingDummyLives.any((e) => e.userId == element.hostId && e.status == 1);
        if (shouldDelete) {
          Loggers.info('Removing stale dummy live: ${element.hostId}');
          deleteStreamOnFirebase(element.hostId);
        }
      }
    }
  }

  Future<void> onGoLive() async {
    User? myUser = SessionManager.instance.getUser();

    if (myUser?.isHost != 1) {
      _showBecomeHostDialog();
      return;
    }

    bool isExist = livestreamList.any((element) => element.hostId == myUser?.id);
    if (myUser?.isDummy == 1 && isExist) {
      return showSnackBar(LKey.yourProfileIsAlreadyInUseForDummyEtc.tr);
    }

    if (myUser?.isDummy == 0 && isExist) {
      showLoader();
      await deleteStreamOnFirebase(myUser?.id);
      stopLoader();
    }

    Get.to(() => const GoLiveSetupScreen());
  }

  void _showBecomeHostDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Host Access Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You need to be a host to go live. Please request to become a host from your profile page.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              final user = SessionManager.instance.getUser();
              Get.to(() => ProfileScreen(
                    isDashBoard: false,
                    user: user,
                    isTopBarVisible: false,
                  ));
            },
            child: const Text('Go to Profile', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
