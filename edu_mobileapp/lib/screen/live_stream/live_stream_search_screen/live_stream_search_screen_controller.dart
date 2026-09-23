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
  /// sessions, most recent first.
  List<LiveRoomItem> get mergedRoomItems {
    final items = _liveVideoAndAudioItems();
    for (final recording in recordedLives) {
      items.add(LiveRoomItem.recorded(recording, onTap: () {
        final url = recording.videoUrl;
        if (url == null || url.isEmpty) return;
        Get.to(() => RecordedVideoPlayerScreen(videoUrl: url));
      }));
    }
    items.sort((a, b) => b.sortTimestamp.compareTo(a.sortTimestamp));
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

  /// "Popular Hosts" row: currently-live video/audio rooms only, ranked by
  /// viewer/listener count — a client-side sort of data already fetched
  /// here, no new backend fields or calls.
  List<LiveRoomItem> get popularLiveHosts {
    final items = _liveVideoAndAudioItems();
    items.sort((a, b) => b.subCount.compareTo(a.subCount));
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

    await addDummyUsers();
    _dummyUsersReady = true;

    await Future.wait({
      fetchLiveStreams(),
      favoritesFuture,
      categoriesFuture,
      followingFuture,
    });

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

    // Using a map for faster access and modification
    final Map<String, Livestream> livestreamMap = {};

    livestreamListListener = db
        .collection(FirebaseConst.liveStreams)
        .withConverter(
          fromFirestore: (snapshot, options) => Livestream.fromJson(snapshot.data()!),
          toFirestore: (Livestream livestream, options) => livestream.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final Livestream? livestream = change.doc.data();
        String roomId = livestream?.roomID ?? '';
        if (livestream == null || roomId.isEmpty) continue;

        // Add, modify, or remove based on document change type
        switch (change.type) {
          case DocumentChangeType.added:
            livestreamMap[roomId] = livestream;
            if (livestream.hostId != null && livestream.hostId != -1) {
              firebaseFirestoreController.fetchUserIfNeeded(livestream.hostId ?? -1);
            }
            break;

          case DocumentChangeType.modified:
            // Update only if the livestream has changed
            livestreamMap[roomId] = livestream;
            for (var coHostId in (livestream.coHostIds ?? [])) {
              firebaseFirestoreController.fetchUserIfNeeded(coHostId);
            }
            break;

          case DocumentChangeType.removed:
            livestreamMap.remove(roomId);
            break;
        }
      }

      // Convert map back to lists
      livestreamList.value = List.from(livestreamMap.values);
      // Perform any additional cleanup or transformations
      removeDummyLive();
      // Apply current category filter
      _applyFilter();

      _assignHostUsersToStreams();
      isLoading.value = false; // Hide loader after initial fetch
    });
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
  /// favorites, and recorded sessions.
  Future<void> onHomeRefresh() async {
    await Future.wait([
      fetchFilterCategories(),
      fetchFavoriteUsers(),
      fetchRecordedLives(),
    ]);
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
      // "All" selected — show everything
      filtered = List.from(livestreamList);
    } else {
      final selectedCat = filterCategories[selectedCategoryIndex.value - 1];
      filtered = livestreamList.where((s) {
        if (s.categoryId == selectedCat.id) return true;
        if (s.hostId != null) {
          final hostUser = firebaseFirestoreController.users
              .firstWhereOrNull((u) => u.userId == s.hostId);
          if (hostUser?.categoryId == selectedCat.id) return true;
        }
        return false;
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
