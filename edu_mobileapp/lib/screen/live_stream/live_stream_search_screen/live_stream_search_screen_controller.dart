import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
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
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/livestream/live_room_item.dart';
import 'package:geoedu/screen/audio_call/audio_room_screen.dart';
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

  // Real-time audio rooms state
  RxList<AudioRoom> audioRoomsList = <AudioRoom>[].obs;
  RxList<AudioRoom> audioRoomsFilterList = <AudioRoom>[].obs;
  StreamSubscription? _audioRoomsSub;

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

  /// Live video + live audio rooms matching current category filter.
  List<LiveRoomItem> _filteredLiveVideoAndAudioItems() {
    return [
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
      for (final room in audioRoomsFilterList)
        LiveRoomItem.audio(
          room,
          onTap: () => onAudioRoomTap(room),
        ),
    ];
  }

  /// All currently active live video + live audio rooms (unfiltered by category).
  List<LiveRoomItem> _allLiveVideoAndAudioItems() {
    return [
      for (final stream in livestreamList)
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
      for (final room in audioRoomsList)
        LiveRoomItem.audio(
          room,
          onTap: () => onAudioRoomTap(room),
        ),
    ];
  }

  List<LiveRoomItem> _liveVideoAndAudioItems() => _filteredLiveVideoAndAudioItems();

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
    items.sort((a, b) {
      // 1. Actively LIVE rooms (video / audio) ALWAYS come before recorded videos!
      final aIsLive = a.variant != RoomCardVariant.recorded ? 1 : 0;
      final bIsLive = b.variant != RoomCardVariant.recorded ? 1 : 0;
      if (aIsLive != bIsLive) {
        return bIsLive.compareTo(aIsLive);
      }

      // 2. Prioritize matching user interests when in "All" tab
      if (selectedCategoryIndex.value == 0 && myInterests.isNotEmpty) {
        final interestNames = myInterests
            .map((i) => i.name?.toLowerCase().trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet();
        final aMatch = interestNames.contains(a.categoryName.toLowerCase().trim()) ? 1 : 0;
        final bMatch = interestNames.contains(b.categoryName.toLowerCase().trim()) ? 1 : 0;
        if (aMatch != bMatch) {
          return bMatch.compareTo(aMatch);
        }
      }

      // 3. Most recent first
      return b.sortTimestamp.compareTo(a.sortTimestamp);
    });
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
    final items = _allLiveVideoAndAudioItems();
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
      _listenAudioRooms(),
      favoritesFuture,
      categoriesFuture,
      followingFuture,
      interestsFuture,
    });

    // Reorder categories to show user's interests first right after All
    _reorderCategoriesByInterests();

    ever(firebaseFirestoreController.users, (_) => _assignHostUsersToStreams());

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
    livestreamListListener?.cancel();
    _audioRoomsSub?.cancel();
    super.onClose();
  }

  Future<void> fetchLiveStreams() async {
    isLoading.value = true;

    livestreamListListener = db
        .collection(FirebaseConst.liveStreams)
        .withConverter(
          fromFirestore: (snapshot, options) {
            try {
              final data = snapshot.data();
              if (data == null) return Livestream();
              return Livestream.fromJson(data);
            } catch (e) {
              Loggers.error('Error parsing livestream doc ${snapshot.id}: $e');
              return Livestream();
            }
          },
          toFirestore: (Livestream livestream, options) => livestream.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      final activeStreams = <Livestream>[];
      for (var doc in snapshot.docs) {
        final stream = doc.data();
        if (stream.roomID != null && stream.roomID!.isNotEmpty) {
          if (stream.isDummyLive == 1 ||
              stream.type == LivestreamType.dummy ||
              (stream.dummyUserLink != null && stream.dummyUserLink!.isNotEmpty)) {
            continue;
          }
          // If explicitly marked inactive, skip it
          if (stream.isActive == false) {
            continue;
          }
          // If the stream is older than 12 hours, treat as expired stale live
          final createdAt = stream.createdAt ?? 0;
          if (createdAt > 0 &&
              DateTime.now().millisecondsSinceEpoch - createdAt > 12 * 60 * 60 * 1000) {
            doc.reference.delete().catchError((_) {});
            continue;
          }
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
    }, onError: (e) {
      Loggers.error('LiveStreamSearch: listen live streams error: $e');
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
    livestreamList.refresh();
    livestreamFilterList.refresh();
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

  Future<void> _listenAudioRooms() async {
    _audioRoomsSub?.cancel();
    _audioRoomsSub = db
        .collection(FirebaseConst.audioRooms)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final activeRooms = <AudioRoom>[];
      for (var doc in snapshot.docs) {
        try {
          final room = AudioRoom.fromJson(doc.data());
          if (room.isActive == true && room.roomId != null && room.roomId!.isNotEmpty) {
            activeRooms.add(room);
            if (room.hostId != null && room.hostId != -1) {
              firebaseFirestoreController.fetchUserIfNeeded(room.hostId!);
            }
          }
        } catch (e) {
          Loggers.error('LiveStreamSearchScreenController: error parsing audio room doc: $e');
        }
      }
      audioRoomsList.value = activeRooms;
      _applyFilter();
    }, onError: (e) {
      Loggers.error('LiveStreamSearchScreenController: listen audio rooms error: $e');
    });
  }

  void onAudioRoomTap(AudioRoom room) async {
    final myUser = SessionManager.instance.getUser();
    if (myUser?.id == null) return;

    final isHost = room.hostId == myUser!.id;
    if (isHost) {
      Get.to(() => AudioRoomScreen(room: room, isHost: true));
      return;
    }

    final currentParticipants = room.participantIds ?? [];
    if (currentParticipants.contains(myUser.id)) {
      Get.to(() => AudioRoomScreen(room: room, isHost: false));
      return;
    }

    if (currentParticipants.length >= (room.maxParticipants ?? 8)) {
      showSnackBar('Room is full');
      return;
    }

    try {
      await db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .update({
        'participant_ids': FieldValue.arrayUnion([myUser.id]),
      });
    } catch (e) {
      Loggers.error('Error updating audio room participants: $e');
    }

    Get.to(() => AudioRoomScreen(room: room, isHost: false));
  }

  onSearchChange(String value) {
    if (value.trim().isEmpty) {
      _applyFilter();
      return;
    }
    final q = value.trim().toLowerCase();
    livestreamFilterList.value = livestreamList.where((s) {
      final hostName = (s.hostUser?.fullname ?? s.hostUser?.username ?? '').toLowerCase();
      final desc = (s.description ?? '').toLowerCase();
      final cat = (s.categoryName ?? '').toLowerCase();
      return hostName.contains(q) || desc.contains(q) || cat.contains(q);
    }).toList();

    audioRoomsFilterList.value = audioRoomsList.where((r) {
      final hostName = (r.hostName ?? '').toLowerCase();
      final roomName = (r.roomName ?? '').toLowerCase();
      final desc = (r.description ?? '').toLowerCase();
      final cat = (r.categoryName ?? '').toLowerCase();
      return hostName.contains(q) || roomName.contains(q) || desc.contains(q) || cat.contains(q);
    }).toList();
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
      SessionManager.instance.refreshUser(),
    ]);
    _reorderCategoriesByInterests();
    _applyFilter();
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
    if (matching.isNotEmpty) {
      filterCategories.value = [...matching, ...others];
    }
  }

  /// Selects a category and moves it to index 0 of [filterCategories]
  /// (which corresponds to index 1 right after "All" in the horizontal selector).
  /// All other categories remain in order behind it.
  void selectCategoryAndPrioritize(
    Category category, {
    SubCategory? subCategory,
    Division? division,
    Topic? topic,
  }) {
    final list = List<Category>.from(filterCategories);
    final existingIdx = list.indexWhere((c) => c.id == category.id);
    if (existingIdx >= 0) {
      final item = list.removeAt(existingIdx);
      list.insert(0, item);
    } else {
      list.insert(0, category);
    }
    filterCategories.value = list;

    // Index 1 corresponds to filterCategories[0], directly after "All" (index 0)
    selectedCategoryIndex.value = 1;
    selectedSubCategory.value = subCategory;
    selectedDivision.value = division;
    selectedTopic.value = topic;

    _applyFilter();
    fetchRecordedLives();
  }

  /// Called from ChangeInterestSheet after the user saves interests.
  Future<void> onInterestsSaved(List<Interest> newInterests) async {
    myInterests.value = newInterests;
    _reorderCategoriesByInterests();
    if (filterCategories.isNotEmpty) {
      selectedCategoryIndex.value = 1;
    }
    _applyFilter();
    fetchRecordedLives();
  }

  Future<void> fetchFilterCategories() async {
    try {
      final result = await CommonService.instance.fetchCategorySubCategoryTopic();
      filterCategories.value = result.data ?? [];
      if (selectedCategoryIndex.value > filterCategories.length) {
        selectedCategoryIndex.value = 0;
        _applyFilter();
      }
    } catch (e) {
      Loggers.error('fetchFilterCategories error: $e');
    }
  }

  void onCategorySelected(int index) {
    if (index == 0) {
      // User tapped "All" — keep categories ordering, select "All"
      selectedCategoryIndex.value = 0;
      selectedSubCategory.value = null;
      selectedDivision.value = null;
      selectedTopic.value = null;
      _applyFilter();
      fetchRecordedLives();
      return;
    }

    final catIndex = index - 1;
    if (catIndex >= 0 && catIndex < filterCategories.length) {
      final selectedCat = filterCategories[catIndex];
      if (catIndex != 0) {
        // Move the selected category to index 0 (immediately after "All")
        final list = List<Category>.from(filterCategories);
        list.removeAt(catIndex);
        list.insert(0, selectedCat);
        filterCategories.value = list;
      }

      selectedCategoryIndex.value = 1;
      selectedSubCategory.value = null;
      selectedDivision.value = null;
      selectedTopic.value = null;
      _applyFilter();
      fetchRecordedLives();
    }
  }

  void setHierarchicalFilter({
    required int categoryIndex,
    SubCategory? subCategory,
    Division? division,
    Topic? topic,
  }) {
    if (categoryIndex == 0) {
      clearHierarchicalFilter();
      return;
    }
    final catIdx = categoryIndex - 1;
    if (catIdx >= 0 && catIdx < filterCategories.length) {
      selectCategoryAndPrioritize(
        filterCategories[catIdx],
        subCategory: subCategory,
        division: division,
        topic: topic,
      );
    }
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
    if (selectedCategoryIndex.value > filterCategories.length) {
      selectedCategoryIndex.value = 0;
    }

    List<Livestream> filteredVideo;
    List<AudioRoom> filteredAudio;

    if (selectedCategoryIndex.value == 0) {
      // "All" selected — display all live video streams and audio rooms in real time
      filteredVideo = List.from(livestreamList);
      filteredAudio = List.from(audioRoomsList);

      if (myInterests.isNotEmpty) {
        final interestNames = myInterests
            .map((i) => i.name?.toLowerCase().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet();
        filteredVideo.sort((a, b) {
          final aCat = a.categoryName?.toLowerCase().trim() ?? '';
          final bCat = b.categoryName?.toLowerCase().trim() ?? '';
          final aMatch = interestNames.contains(aCat) ? 1 : 0;
          final bMatch = interestNames.contains(bCat) ? 1 : 0;
          if (aMatch != bMatch) {
            return bMatch.compareTo(aMatch);
          }
          return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
        });

        filteredAudio.sort((a, b) {
          final aCat = a.categoryName?.toLowerCase().trim() ?? '';
          final bCat = b.categoryName?.toLowerCase().trim() ?? '';
          final aMatch = interestNames.contains(aCat) ? 1 : 0;
          final bMatch = interestNames.contains(bCat) ? 1 : 0;
          if (aMatch != bMatch) {
            return bMatch.compareTo(aMatch);
          }
          return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
        });
      } else {
        filteredVideo.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
        filteredAudio.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
      }
    } else {
      final selectedCat = filterCategories[selectedCategoryIndex.value - 1];
      final targetSubCat = selectedSubCategory.value;
      final targetDiv = selectedDivision.value;
      final targetTop = selectedTopic.value;
      final selectedCatName = selectedCat.name?.toLowerCase().trim() ?? '';

      filteredVideo = livestreamList.where((s) {
        // Category check
        bool matchCategory = false;
        if (s.categoryId == selectedCat.id) {
          matchCategory = true;
        } else if (s.hostId != null) {
          final hostUser = firebaseFirestoreController.users
              .firstWhereOrNull((u) => u.userId == s.hostId);
          if (hostUser?.categoryId == selectedCat.id) matchCategory = true;
        }
        if (!matchCategory && s.categoryName != null && selectedCatName.isNotEmpty) {
          if (s.categoryName!.trim().toLowerCase() == selectedCatName) {
            matchCategory = true;
          }
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
          if (!matchSub && s.subCategoryName != null && targetSubCat.name != null) {
            if (s.subCategoryName!.trim().toLowerCase() == targetSubCat.name!.trim().toLowerCase()) {
              matchSub = true;
            }
          }
          if (!matchSub) return false;
        }

        // Division check if selected
        if (targetDiv != null) {
          final divTopicIds = targetSubCat?.topics
              ?.where((t) => t.divisionId == targetDiv.id)
              .map((t) => t.id)
              .toSet() ?? {};
          if (divTopicIds.isNotEmpty) {
            bool matchDiv = divTopicIds.contains(s.topicId);
            if (!matchDiv && s.hostId != null) {
              final hostUser = firebaseFirestoreController.users
                  .firstWhereOrNull((u) => u.userId == s.hostId);
              if (divTopicIds.contains(hostUser?.topicId)) matchDiv = true;
            }
            if (!matchDiv) return false;
          }
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

      filteredAudio = audioRoomsList.where((room) {
        bool matchCategory = false;
        if (room.categoryId == selectedCat.id) {
          matchCategory = true;
        } else if (room.hostId != null) {
          final hostUser = firebaseFirestoreController.users
              .firstWhereOrNull((u) => u.userId == room.hostId);
          if (hostUser?.categoryId == selectedCat.id) matchCategory = true;
        }
        if (!matchCategory && room.categoryName != null && selectedCatName.isNotEmpty) {
          if (room.categoryName!.trim().toLowerCase() == selectedCatName) {
            matchCategory = true;
          }
        }
        return matchCategory;
      }).toList();

      filteredVideo.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
      filteredAudio.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    }

    // Prioritize selected language without filtering out any live rooms from "All"
    final liveRoomLangId = SessionManager.instance.storage.read<int>(SessionKeys.liveRoomLanguageId);
    if (liveRoomLangId != null) {
      filteredVideo.sort((a, b) {
        final aMatch = (a.languageId == liveRoomLangId) ? 1 : 0;
        final bMatch = (b.languageId == liveRoomLangId) ? 1 : 0;
        if (aMatch != bMatch) return bMatch.compareTo(aMatch);
        return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
      });
      filteredAudio.sort((a, b) {
        final aMatch = (a.languageId == liveRoomLangId) ? 1 : 0;
        final bMatch = (b.languageId == liveRoomLangId) ? 1 : 0;
        if (aMatch != bMatch) return bMatch.compareTo(aMatch);
        return (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
      });
    }

    livestreamFilterList.value = filteredVideo;
    audioRoomsFilterList.value = filteredAudio;
  }

  Future<void> addDummyUsers() async {
    try {
      // Clean up any lingering dummy livestreams from Firestore so they never pollute real-time streams
      final livestreamList = await db
          .collection(FirebaseConst.liveStreams)
          .withConverter<Livestream>(
            fromFirestore: (snapshot, _) => Livestream.fromJson(snapshot.data()!),
            toFirestore: (livestream, _) => livestream.toJson(),
          )
          .get();

      for (var doc in livestreamList.docs) {
        final stream = doc.data();
        if (stream.isDummyLive == 1 ||
            stream.type == LivestreamType.dummy ||
            (stream.dummyUserLink != null && stream.dummyUserLink!.isNotEmpty)) {
          await deleteStreamOnFirebase(stream.hostId);
          Loggers.info('Deleted dummy livestream from Firestore: ${stream.hostId}');
        }
      }
    } catch (e) {
      Loggers.error('Error in cleaning dummy users: $e');
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
