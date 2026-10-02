import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen_controller.dart';
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

  /// Strictly validates that the stream belongs to an actual real host
  /// who is currently broadcasting, and is NOT a dummy/sample stream.
  bool _isRealLiveStream(Livestream stream) {
    if (stream.isDummyLive == 1) return false;
    if (stream.type == LivestreamType.dummy) return false;
    if (stream.dummyUserLink != null && stream.dummyUserLink!.isNotEmpty) return false;
    final roomId = stream.roomID ?? '';
    if (roomId.isEmpty) return false;
    if (stream.hostId == null || stream.hostId! <= 0) return false;
    return true;
  }

  void _initStreams() {
    // Real-time Firestore stream listener on liveStreams collection
    _firestoreSub = _db
        .collection(FirebaseConst.liveStreams)
        .withConverter(
          fromFirestore: (snapshot, options) => Livestream.fromJson(snapshot.data()!),
          toFirestore: (Livestream stream, options) => stream.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      _streamMap.clear();
      for (var doc in snapshot.docs) {
        final stream = doc.data();
        if (_isRealLiveStream(stream)) {
          final roomId = stream.roomID!;
          _streamMap[roomId] = stream;
          if (stream.hostId != null && stream.hostId! > 0) {
            if (Get.isRegistered<FirebaseFirestoreController>()) {
              Get.find<FirebaseFirestoreController>().fetchUserIfNeeded(stream.hostId!);
            }
          }
        }
      }

      final list = List<Livestream>.from(_streamMap.values);
      _assignHostUsers(list);

      if (currentIndex.value >= list.length) {
        currentIndex.value = list.isNotEmpty ? list.length - 1 : 0;
      }

      liveStreams.assignAll(list);
      isLoading.value = false;
    }, onError: (e) {
      Loggers.error('LiveReels: firestore subscription error: $e');
      isLoading.value = false;
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
        if (_isRealLiveStream(stream)) {
          _streamMap[stream.roomID!] = stream;
        }
      }
      final list = List<Livestream>.from(_streamMap.values);
      _assignHostUsers(list);

      if (currentIndex.value >= list.length) {
        currentIndex.value = list.isNotEmpty ? list.length - 1 : 0;
      }

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

