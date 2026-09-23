import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/manager/firebase_notification_manager.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/restart_widget.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/chat/chat_thread.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/camera_screen/camera_screen.dart';
import 'package:geoedu/screen/feed_screen/feed_screen_controller.dart';
import 'package:geoedu/screen/gif_sheet/gif_sheet_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geoedu/common/service/online_presence_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class DashboardScreenController extends BaseController with GetSingleTickerProviderStateMixin {

  // Explore/Premium/Live have no themed SVG assets today (the old
  // Audio/Chat/Menu SVGs don't fit these new tabs), so the bottom nav uses
  // Material icons here instead of SvgPicture — see dashboard_screen.dart.
  List<IconData> bottomIcons = [
    Icons.home_rounded,
    Icons.explore_rounded,
    Icons.workspace_premium_rounded,
    Icons.live_tv_rounded,
  ];
  List<String> bottomNameList = [
    'Home',
    'Explore',
    'Premium',
    'Live',
  ];

  // List<String> bottomIconList = [
  //   AssetRes.icLiveStream,
  //   AssetRes.icReel,
  //   AssetRes.icPost,
  //   AssetRes.icSearch,
  //   AssetRes.icChat,
  //   AssetRes.icProfile
  // ];
  RxInt selectedPageIndex = 0.obs;
  RxDouble scaleValue = 1.0.obs;
  Function(int index)? onBottomIndexChanged;
  Rx<PostUploadingProgress> postProgress = Rx(PostUploadingProgress());
  Function(PostUploadingProgress progress) onProgress = (_) {};

  late AnimationController animationController;

  FirebaseFirestore db = FirebaseFirestore.instance;
  RxInt unReadCount = 0.obs;
  RxInt requestUnReadCount = 0.obs;

  final AudioPlayer _chatSoundPlayer = AudioPlayer();
  bool _isInitialLoad = true;

  late StreamSubscription _unReadCountSubscription;
  late Animation<double> scaleAnimation;
  User? user = SessionManager.instance.getUser();



  @override
  void onInit() {
    super.onInit();
    if (selectedPageIndex.value == 0) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark));
    }
    Get.put(GifSheetController());
    Get.put(FirebaseFirestoreController());
    // Registered here (not lazily inside AudioCallListScreen.build()) so the
    // Home tab, which builds first and reads this controller for the Live
    // Audio Rooms section, can safely Get.find() it on the very first frame.
    Get.put(AudioCallListController());

    animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    )..addListener(() {
        scaleValue.value = scaleAnimation.value; // Update reactive scale value
      });
    onProgress = (progress) {
      postProgress.value = progress;
    };
  }

  @override
  void onReady() async {
    super.onReady();
    _chatSoundPlayer.setAsset(AssetRes.chatNotification);

    // Run below in parallel
    _createZegoEngine();
    _fetchLanguageFromUser();
    _fetchUnReadCount();
    startCacheCleanupScheduler();
    _subscribeFollowUserIds();
    updateDummyUsers();

    // Go online for audio call presence
    if (user != null) {
      OnlinePresenceService.instance.goOnline(user!);
    }
  }

  void startCacheCleanupScheduler() {
    UserService.instance.updateLastUsedAt();
    Timer.periodic(const Duration(minutes: 15), (_) {
      UserService.instance.updateLastUsedAt();
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    _unReadCountSubscription.cancel();
    _chatSoundPlayer.dispose();
    if (user?.id != null) {
      OnlinePresenceService.instance.goOffline(user!.id!);
    }
    super.onClose();
  }

  onChanged(int index) {
    // Menu is no longer a tab (moved to a LiveTopBar icon), so index 3 is
    // now the real "Live" page like the other three.
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarBrightness: index == 0 || index == 1 ? Brightness.dark : Brightness.light));
    if (index == 1) {
      onFeedPostScrollDown(index);
    }
    if (selectedPageIndex.value == index) return;
    HapticFeedback.lightImpact();
    onBottomIndexChanged?.call(index);
    selectedPageIndex.value = index;
    animationController
      ..reset()
      ..forward();
  }

  onFeedPostScrollDown(int index) {
    if (selectedPageIndex.value != index) return;
    if (Get.isRegistered<FeedScreenController>()) {
      final controller = Get.find<FeedScreenController>();
      if (controller.posts.isNotEmpty && !controller.isLoading.value) {
        controller.postScrollController
            .animateTo(0.0, duration: const Duration(milliseconds: 150), curve: Curves.linear);
        controller.refreshKey.currentState?.show();
      }
    }
  }

  void _fetchUnReadCount() {
    _unReadCountSubscription = db
        .collection(FirebaseConst.users)
        .doc(user?.id.toString())
        .collection(FirebaseConst.usersList)
        .where(FirebaseConst.isDeleted, isEqualTo: false)
        .withConverter(
          fromFirestore: (snapshot, _) => ChatThread.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        )
        .snapshots()
        .listen((event) {
      // Calculate unread counts once per snapshot (not per docChange)
      final docs = event.docs.map((e) => e.data()).toList();

      final totalUnread = docs.where((e) => (e.msgCount ?? 0) > 0).length;

      final requestUnread = docs.where((e) => (e.msgCount ?? 0) > 0 && e.chatType == ChatType.request).length;

      // Play notification sound when new unread messages arrive
      if (_isInitialLoad) {
        _isInitialLoad = false;
      } else if (totalUnread > unReadCount.value) {
        _playChatNotificationSound();
      }

      unReadCount.value = totalUnread;
      requestUnReadCount.value = requestUnread;
    });
  }

  void _playChatNotificationSound() async {
    try {
      await _chatSoundPlayer.seek(Duration.zero);
      await _chatSoundPlayer.play();
    } catch (e) {
      Loggers.error('Chat notification sound error: $e');
    }
  }

  Future<void> _createZegoEngine() async {
    Setting? appSetting = SessionManager.instance.getSettings();
    int appId = int.parse(appSetting?.zegoAppId ?? '0');
    if (appId == 0) {
      return Loggers.info('The Zego App ID is not configured.');
    }
    try {
      await ZegoExpressEngine.createEngineWithProfile(
          ZegoEngineProfile(appId, ZegoScenario.Default, appSign: appSetting?.zegoAppSign));
    } on MissingPluginException catch (e) {
      Loggers.error('Create Zego Engine : ${e.message}');
    }
  }


  Future<void> _fetchLanguageFromUser() async {
    String savedLanguage = SessionManager.instance.getLang();
    String userLanguage = user?.appLanguage ?? 'en';
    if (userLanguage != savedLanguage) {
      SessionManager.instance.setLang(userLanguage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RestartWidget.restartApp(Get.context!);
      });
    }
  }

  void _subscribeFollowUserIds() async {
    Future.wait([addUserInFirebase()]);
    for (int id in (user?.followingIds ?? [])) {
      // Delay slightly to avoid overloading FCM
      await Future.delayed(const Duration(milliseconds: 100));
      Future.wait([FirebaseNotificationManager.instance.subscribeToTopic(topic: '$id')]);
    }
  }

  Future addUserInFirebase() async {
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      Get.find<FirebaseFirestoreController>().addUser(user);
    } else {
      Get.put(FirebaseFirestoreController()).addUser(user);
    }
  }

  void updateDummyUsers() {
    List<DummyLive> dummyLives = SessionManager.instance.getSettings()?.dummyLives ?? [];
    if (dummyLives.isNotEmpty) {
      final controller = Get.find<FirebaseFirestoreController>();
      for (var element in dummyLives) {
        controller.updateUser(element.user);
      }
    }
  }
}

class PostUploadingProgress {
  final CameraScreenType type;
  final UploadType uploadType;
  final double progress;

  PostUploadingProgress({this.type = CameraScreenType.post, this.progress = 0, this.uploadType = UploadType.none});
}

enum UploadType {
  none,
  finish,
  error,
  uploading;

  String title(CameraScreenType type) {
    switch (this) {
      case UploadType.none:
        return '';
      case UploadType.finish:
        return type == CameraScreenType.post ? LKey.postUploadSuccessfully.tr : LKey.storyUploadSuccess.tr;
      case UploadType.error:
        return LKey.uploadingFailed.tr;
      case UploadType.uploading:
        return type == CameraScreenType.post ? LKey.postIsBeginUploading.tr : LKey.storyIsBeginUploading.tr;
    }
  }
}
