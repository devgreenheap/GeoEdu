import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/extensions/user_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class LiveReelsFeedController extends BaseController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<Livestream> liveStreams = <Livestream>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isTabActive = false.obs;

  late final PageController pageController;

  StreamSubscription<QuerySnapshot<Livestream>>? _firestoreSub;
  Worker? _tabWorker;
  Worker? _searchCtrlWorker;

  final Map<String, Livestream> _streamMap = {};

  @override
  void onInit() {
    super.onInit();
    isLoading.value = true;
    pageController = PageController();

    _observeTabActivity();
    _initStreams();
  }

  void _observeTabActivity() {
    if (Get.isRegistered<DashboardScreenController>()) {
      final dashboardCtrl = Get.find<DashboardScreenController>();
      isTabActive.value = dashboardCtrl.selectedPageIndex.value == 3;
      _tabWorker = ever(dashboardCtrl.selectedPageIndex, (int pageIndex) {
        final active = pageIndex == 3;
        if (isTabActive.value != active) {
          isTabActive.value = active;
          if (!active) {
            try {
              ZegoExpressEngine.instance.muteAllPlayStreamAudio(true);
            } catch (_) {}
          }
          Loggers.info('LiveReels: Tab active state changed to: $active');
        }
      });
    } else {
      isTabActive.value = true;
    }
  }

  void _initStreams() {
    // 1. Instantly copy streams from search controller if already populated
    if (Get.isRegistered<LiveStreamSearchScreenController>()) {
      final searchCtrl = Get.find<LiveStreamSearchScreenController>();
      if (searchCtrl.livestreamList.isNotEmpty) {
        final initialList = List<Livestream>.from(searchCtrl.livestreamList);
        for (var s in initialList) {
          if (s.roomID != null && s.roomID!.isNotEmpty) {
            _streamMap[s.roomID!] = s;
          }
        }
        liveStreams.assignAll(initialList);
        isLoading.value = false;
      }

      // Also listen to search controller changes
      _searchCtrlWorker = ever(searchCtrl.livestreamList, (List<Livestream> list) {
        if (list.isNotEmpty) {
          for (var s in list) {
            if (s.roomID != null && s.roomID!.isNotEmpty) {
              _streamMap[s.roomID!] = s;
            }
          }
          final merged = List<Livestream>.from(_streamMap.values);
          _assignHostUsers(merged);
          liveStreams.assignAll(merged);
          isLoading.value = false;
        }
      });
    }

    // 2. Real-time Firestore stream listener on liveStreams collection
    _firestoreSub = _db
        .collection(FirebaseConst.liveStreams)
        .withConverter(
          fromFirestore: (snapshot, options) => Livestream.fromJson(snapshot.data()!),
          toFirestore: (Livestream stream, options) => stream.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final stream = change.doc.data();
        final roomId = stream?.roomID ?? '';
        if (stream == null || roomId.isEmpty) continue;

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            _streamMap[roomId] = stream;
            if (stream.hostId != null && stream.hostId != -1) {
              if (Get.isRegistered<FirebaseFirestoreController>()) {
                Get.find<FirebaseFirestoreController>().fetchUserIfNeeded(stream.hostId!);
              }
            }
            break;
          case DocumentChangeType.removed:
            _streamMap.remove(roomId);
            break;
        }
      }

      final list = List<Livestream>.from(_streamMap.values);
      _assignHostUsers(list);
      _populateDummyIfEmpty(list);

      liveStreams.assignAll(list);
      isLoading.value = false;
    }, onError: (e) {
      Loggers.error('LiveReels: firestore subscription error: $e');
      isLoading.value = false;
    });

    // Fallback if list still empty after initial tick
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (liveStreams.isEmpty) {
        final list = <Livestream>[];
        _populateDummyIfEmpty(list);
        if (list.isNotEmpty) {
          liveStreams.assignAll(list);
          isLoading.value = false;
        }
      }
    });
  }

  void _assignHostUsers(List<Livestream> list) {
    if (!Get.isRegistered<FirebaseFirestoreController>()) return;
    final firestoreCtrl = Get.find<FirebaseFirestoreController>();
    final userMap = {
      for (var u in firestoreCtrl.users)
        if (u.userId != null) u.userId!: u,
    };
    for (var stream in list) {
      if (stream.hostId != null && userMap.containsKey(stream.hostId)) {
        stream.hostUser = userMap[stream.hostId];
      }
    }
  }

  void _populateDummyIfEmpty(List<Livestream> list) {
    if (list.isNotEmpty) return;
    final Setting? setting = SessionManager.instance.getSettings();
    final dummyLives = setting?.dummyLives ?? [];
    if (dummyLives.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (var dummy in dummyLives) {
      if (dummy.status == 1 && dummy.user != null) {
        final User user = dummy.user!;
        final stream = user.livestream(
          time: now,
          type: LivestreamType.dummy,
          dummyUserLink: dummy.link,
          isDummyLive: 1,
          description: dummy.title,
          categoryId: dummy.categoryId ?? user.categoryId,
          categoryName: dummy.categoryName ?? user.categoryName,
          languageId: dummy.languageId ?? user.languageId,
          languageName: dummy.languageName ?? user.languageName,
        );
        stream.hostUser = user.appUser;
        list.add(stream);
      }
    }
  }

  void onPageChanged(int index) {
    if (currentIndex.value == index) return;
    Loggers.info('LiveReels: Switched to index $index (room: ${liveStreams.elementAtOrNull(index)?.roomID})');
    currentIndex.value = index;
  }

  Future<void> refreshStreams() async {
    isLoading.value = true;
    try {
      final snap = await _db
          .collection(FirebaseConst.liveStreams)
          .withConverter(
            fromFirestore: (snapshot, options) => Livestream.fromJson(snapshot.data()!),
            toFirestore: (Livestream stream, options) => stream.toJson(),
          )
          .get();

      _streamMap.clear();
      for (var doc in snap.docs) {
        final stream = doc.data();
        if (stream.roomID != null && stream.roomID!.isNotEmpty) {
          _streamMap[stream.roomID!] = stream;
        }
      }
      final list = List<Livestream>.from(_streamMap.values);
      _assignHostUsers(list);
      _populateDummyIfEmpty(list);
      liveStreams.assignAll(list);
    } catch (e) {
      Loggers.error('LiveReels: refresh error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _firestoreSub?.cancel();
    _tabWorker?.dispose();
    _searchCtrlWorker?.dispose();
    pageController.dispose();

    // Clean up any remaining LivestreamScreenController
    if (Get.isRegistered<LivestreamScreenController>()) {
      try {
        Get.delete<LivestreamScreenController>(force: true);
      } catch (_) {}
    }

    super.onClose();
  }
}
