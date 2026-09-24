import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/screenshot_prevention.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/extensions/user_extension.dart';
import 'package:geoedu/common/manager/firebase_notification_manager.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/api_service.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/service/api/notification_service.dart';
import 'package:geoedu/common/manager/gift_audio_player.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/entry_effects_widget.dart'
    show AnimatedSvgPlayer;
import 'package:geoedu/common/service/utils/params.dart';
import 'package:geoedu/common/service/utils/web_service.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_comment.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:geoedu/screen/live_stream/live_stream_end_screen/live_stream_end_screen.dart';
import 'package:geoedu/screen/live_stream/live_stream_end_screen/widget/livestream_summary.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/live_stream_join_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/host/widget/live_stream_host_top_view.dart';
import 'package:geoedu/screen/report_sheet/report_sheet.dart';
import 'package:geoedu/utilities/app_res.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../../common/extensions/string_extension.dart';
import '../../../model/livestream/entry_effects_model.dart';

class LivestreamScreenController extends BaseController {
  FirebaseFirestore db = FirebaseFirestore.instance;
  // ZegoExpressEngine zegoEngine = ZegoExpressEngine.instance;

  final firestoreController = Get.find<FirebaseFirestoreController>();

  Timer? timer;
  Timer? minViewerTimeoutTimer;
  Function? onLikeTap;

  Setting? get setting => SessionManager.instance.getSettings();

  int get minViewersThreshold => setting?.liveMinViewers ?? 0;

  int get timeoutMinutes => setting?.liveTimeout ?? 0;

  int get myUserId => SessionManager.instance.getUserID();

  RxBool isPlayerMute = false.obs;
  RxBool isMinViewerTimeout = false.obs;
  bool _isScreenshotPreventionActive = false;
  RxBool isTextEmpty = true.obs;
  bool isJoinSheetOpen = false;
  bool isFrontCamera = true;
  bool isHost;

  StreamSubscription<DocumentSnapshot<Livestream>>? liveStreamDocListener;
  StreamSubscription<QuerySnapshot<LivestreamUserState?>>?
      liveStreamUserStatesListener;
  StreamSubscription<QuerySnapshot<LivestreamComment?>>?
      liveStreamCommentsListener;

  TextEditingController textCommentController = TextEditingController();

  DocumentReference get liveStreamDocRef =>
      db.collection(FirebaseConst.liveStreams).doc(liveData.value.roomID);

  CollectionReference get liveStreamUsersRef =>
      db.collection(FirebaseConst.appUsers);

  CollectionReference get liveStreamUserStatesRef => db
      .collection(FirebaseConst.liveStreams)
      .doc(liveData.value.roomID)
      .collection(FirebaseConst.userState);

  CollectionReference get liveStreamCommentsRef => db
      .collection(FirebaseConst.liveStreams)
      .doc(liveData.value.roomID)
      .collection(FirebaseConst.comments);

  Widget? hostPreview;
  int? apiLiveStreamId;
  String? _recordingFilePath;
  bool _isRecording = false;
  Completer<void>? _recordingFinalizeCompleter;

  LivestreamScreenController(this.liveData, this.isHost, {this.hostPreview, this.apiLiveStreamId}) {
    // Preload all gifts audio and SVG animations for instant 0ms playback on tap
    final gifts = SessionManager.instance.getSettings()?.availableGifts ?? [];
    if (gifts.isNotEmpty) {
      GiftAudioPlayer.preloadAll(gifts);
      AnimatedSvgPlayer.preloadAll(gifts);
    }
    // Fetch latest settings from admin in background to ensure new gift sounds are immediately available
    CommonService.instance.fetchGlobalSettings().then((success) {
      if (success) {
        final freshGifts = SessionManager.instance.getSettings()?.availableGifts ?? [];
        if (freshGifts.isNotEmpty) {
          GiftAudioPlayer.preloadAll(freshGifts);
          AnimatedSvgPlayer.preloadAll(freshGifts);
        }
      }
    });
  }

  int totalBattleSecond = 0;

  RxInt remainingBattleSeconds = 0.obs;
  RxBool isViewVisible = true.obs;

  List<LivestreamUserState> memberList = <LivestreamUserState>[];

  List<Gift> get gifts => setting?.gifts ?? [];
  RxList<LivestreamUserState> requestList = <LivestreamUserState>[].obs;
  RxList<LivestreamUserState> audienceList = <LivestreamUserState>[].obs;
  RxList<LivestreamUserState> invitedList = <LivestreamUserState>[].obs;
  RxList<LivestreamUserState> coHostList = <LivestreamUserState>[].obs;
  RxList<LivestreamUserState> audienceMemberList = <LivestreamUserState>[].obs;
  RxList<StreamView> streamViews = <StreamView>[].obs;
  RxList<LivestreamComment> comments = <LivestreamComment>[].obs;
  RxList<LivestreamUserState> liveUsersStates = <LivestreamUserState>[].obs;

  Rx<AppUser?> selectedGiftUser = Rx(null);
  Rx<VideoPlayerController?> videoPlayerController = Rx(null);

  // Inline battle gift bar (EloTV-style tap-to-send row, replaces the old
  // full-screen gift sheet during a PK battle).
  RxBool isBattleGiftBarOpen = false.obs;
  Rx<BattleView> selectedBattleSide = BattleView.red.obs;
  RxInt diamondBalance = 0.obs;
  bool _diamondBalanceFetched = false;

  // Tap either side of the PK battle split screen to give it more space;
  // tap the same side again (or the other side) to change/clear the focus.
  Rx<int?> expandedBattleUserIndex = Rx<int?>(null);

  void toggleBattleFocus(int index) {
    expandedBattleUserIndex.value =
        expandedBattleUserIndex.value == index ? null : index;
  }

  Rx<User?> get myUser => SessionManager.instance.getUser().obs;
  Rx<Livestream> liveData;

  // Global (not per-instance) so it persists as a real user preference for
  // the whole session rather than resetting every time this screen rebuilds.
  static RxBool isGiftSoundOn = true.obs;

  // Host-set diamond goal for this session — host-local, not synced to
  // Firestore since only the host edits/sees it (matches the reference,
  // which shows this only on the host's own top bar).
  RxInt targetDiamonds = 0.obs;
  void setTargetDiamonds(int value) => targetDiamonds.value = value;

  LivestreamUserState? get hostUserState => liveUsersStates
      .firstWhereOrNull((e) => e.userId == liveData.value.hostId);

  /// Real count of gift comments the host has actually received this
  /// session — not a fabricated counter.
  int get hostGiftCount => comments
      .where((c) =>
          c.commentType == LivestreamCommentType.gift &&
          c.receiverId == liveData.value.hostId)
      .length;

  double get targetProgress {
    final target = targetDiamonds.value;
    if (target <= 0) return 0;
    return ((hostUserState?.totalCoin ?? 0) / target).clamp(0, 1).toDouble();
  }

  /// Highest-priced real gift from the catalog, used as the promo card.
  /// "New" is only shown when it was genuinely added recently — never a
  /// fabricated label.
  Gift? get featuredGift {
    if (gifts.isEmpty) return null;
    final sorted = List<Gift>.from(gifts)
      ..sort((a, b) => (b.coinPrice ?? 0).compareTo(a.coinPrice ?? 0));
    return sorted.first;
  }

  bool get featuredGiftIsNew {
    final createdAt = featuredGift?.createdAt;
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inDays <= 7;
  }

  AudioPlayer countdownPlayer = AudioPlayer();
  AudioPlayer battleStartPlayer = AudioPlayer();
  AudioPlayer winAudioPlayer = AudioPlayer();

  List<User> usersList = [];


  RxList<EntryEffect> entryEffects = <EntryEffect>[].obs;
  List<EntryEffect> entryQueue = [];
  bool isEntryAnimating = false;
  StreamSubscription? entryEffectListener;


  @override
  void onInit() {
    super.onInit();

    if (liveData.value.isDummyLive == 1) {
      initVideoPlayer();
    } else {
      totalBattleSecond =
          Duration(minutes: liveData.value.battleDuration).inSeconds;
      remainingBattleSeconds.value = totalBattleSecond;
      ZegoExpressEngine.instance.setAudioDeviceMode(ZegoAudioDeviceMode.General);
      loginRoom();
      startListenEvent();
      initAudioPlayer();
    }

    // Common listeners for all users
    listenLiveStreamData();
    listenUserState();
    fetchLiveStreamComments();
    listenEntryEffects();
    listenGifts();
    WakelockPlus.enable();
    FirebaseNotificationManager.instance
        .unsubscribeToTopic(topic: myUserId.toString());
    _checkScreenshotPrevention();
  }

  Future<void> _checkScreenshotPrevention() async {
    try {
      final screenshotDisabled = liveData.value.screenshotDisabled;
      Loggers.info('Screenshot check: screenshotDisabled=$screenshotDisabled, isHost=$isHost');
      if (screenshotDisabled == 1) {
        _isScreenshotPreventionActive = true;
        await ScreenshotPrevention.instance.enable();
        Loggers.info('Screenshot prevention ENABLED');
      }
    } catch (e) {
      Loggers.error('Screenshot prevention check failed: $e');
    }
  }



  void listenEntryEffects() {
    print("🔥 EntryEffect LISTENER STARTED");

    entryEffectListener = db
        .collection(FirebaseConst.liveStreams)
        .doc(liveData.value.roomID)
        .collection("entryEffects")
        .orderBy("timestamp")
        .snapshots()
        .listen((snapshot) {

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          EntryEffect effect = EntryEffect.fromJson(
              change.doc.data() as Map<String, dynamic>);
          print("📥 New Entry Effect: ${effect.username}");
          entryQueue.add(effect);
          processEntryQueue();
          change.doc.reference.delete();
        }
      }
    });
  }


  void processEntryQueue() async {
    /// already running → stop
    if (isEntryAnimating) return;
    /// no items → stop
    if (entryQueue.isEmpty) return;
    isEntryAnimating = true;
    /// get first effect
    EntryEffect effect = entryQueue.removeAt(0);
    print("🎬 Showing effect: ${effect.username}");
    /// show animation
    entryEffects.add(effect);
    /// wait 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    /// remove animation
    entryEffects.remove(effect);
    print("✅ Finished effect: ${effect.username}");
    isEntryAnimating = false;
    /// process next
    processEntryQueue();
  }

  Future<void> sendEntryEffect(AppUser user) async {
    print("🚀 Checking purchased entry effect for user: ${user.username}");
    try {
      final myEffects = await GiftWalletService.instance.fetchMyEntryEffects();
      // Find an active (non-expired) purchased effect
      final activeEffect = myEffects.where((e) => !e.isExpired).firstOrNull;

      if (activeEffect == null) {
        print("ℹ️ No active entry effect for user: ${user.username}");
        return;
      }

      // Use image field as SVGA path (could be in image or videoPath)
      final svgaUrl = activeEffect.videoPath.isNotEmpty
          ? activeEffect.videoPath
          : activeEffect.image;

      if (svgaUrl.isEmpty) return;

      await db
          .collection(FirebaseConst.liveStreams)
          .doc(liveData.value.roomID)
          .collection("entryEffects")
          .add({
        "id": activeEffect.id,
        "userId": user.userId,
        "username": user.username,
        "effectType": "purchased",
        "asset_url": svgaUrl,
        "effect_name": activeEffect.title,
        "audio": activeEffect.audio,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });

      print("✅ Entry effect sent: ${activeEffect.title}");
    } catch (e) {
      print("❌ sendEntryEffect error: $e");
    }
  }

  List<GiftEffect> giftQueue = [];
  bool isGiftAnimating = false;
  RxList<GiftEffect> activeGifts = <GiftEffect>[].obs;

  void listenGifts() {
    print("🔥 Gift LISTENER STARTED");
    db
        .collection(FirebaseConst.liveStreams)
        .doc(liveData.value.roomID)
        .collection("gifts")
        .orderBy("timestamp")
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          GiftEffect gift = GiftEffect.fromJson(
              change.doc.data() as Map<String, dynamic>);
          print("📥 New Gift: ${gift.username} sent ${gift.giftName}");
          giftQueue.add(gift);
          processGiftQueue();
          change.doc.reference.delete();
        }
      }
    });
  }

  void processGiftQueue() async {
    if (isGiftAnimating) return;
    if (giftQueue.isEmpty) return;

    isGiftAnimating = true;
    GiftEffect gift = giftQueue.removeAt(0);
    print("🎬 Showing gift: ${gift.username} sent ${gift.giftName}");
    activeGifts.add(gift);

    if (gift.audio != null && gift.audio!.isNotEmpty) {
      GiftAudioPlayer.play(gift.audio);
    }
    try {
      await Future.delayed(const Duration(seconds: 5));
    } finally {
      activeGifts.remove(gift);
      print("✅ Finished gift: ${gift.username} sent ${gift.giftName}");
      isGiftAnimating = false;
      processGiftQueue();
    }
  }

  Future<void> sendGift(AppUser user, String giftName, String assetUrl, String audioPath, {int? giftId, int? coinPrice}) async {
    print("🚀 Sending gift for user: ${user.username}");

    // The sender (buyer) is who the animation credits — not the gift's
    // receiver — since this plays for everyone watching the room.
    AppUser? sender = firestoreController.users
        .firstWhereOrNull((element) => element.userId == myUserId);

    await db
        .collection(FirebaseConst.liveStreams)
        .doc(liveData.value.roomID)
        .collection("gifts")
        .add({
      "userId": sender?.userId ?? myUserId,
      "username": sender?.username ?? '',
      "senderPhoto": sender?.profile ?? '',
      "giftName": giftName,
      "gift_id": giftId,
      "coin_price": coinPrice,
      "asset_url": assetUrl,
      "audio": audioPath,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    print("✅ Gift sent successfully: $giftName");
  }

  Future<void> fetchDiamondBalanceIfNeeded() async {
    if (_diamondBalanceFetched) return;
    _diamondBalanceFetched = true;
    final response = await GiftWalletService.instance.fetchMyDiamondWallet();
    diamondBalance.value = response.data?.diamondBalance ?? 0;
  }

  void openBattleGiftBar(BattleView side) {
    selectedBattleSide.value = side;
    isBattleGiftBarOpen.value = true;
    fetchDiamondBalanceIfNeeded();
  }

  Future<void> sendBattleGiftDirect(Gift gift, AppUser targetUser) async {
    final giftId = gift.id?.toInt();
    final coinPrice = gift.coinPrice?.toInt() ?? 0;
    final receiverId = targetUser.userId;
    if (giftId == null || receiverId == null || coinPrice <= 0) {
      return Loggers.error(
          'Invalid battle gift: giftId=$giftId receiver=$receiverId price=$coinPrice');
    }

    int effectiveGiftId = (giftId > 0) ? giftId : -1;
    if (effectiveGiftId <= 0) {
      final serverGifts = SessionManager.instance.getSettings()?.gifts ?? [];
      if (serverGifts.isNotEmpty) {
        final matchingServerGift = serverGifts.firstWhere(
          (g) => (g.coinPrice ?? 0) == coinPrice,
          orElse: () => serverGifts.first,
        );
        if (matchingServerGift.id != null && matchingServerGift.id! > 0) {
          effectiveGiftId = matchingServerGift.id!;
        }
      }
    }

    final response = await GiftWalletService.instance.spendDiamonds(
        diamonds: coinPrice,
        userId: receiverId,
        giftId: effectiveGiftId,
        source: 'video_gift',
        languageId: liveData.value.languageId);
    if (response.status != true) {
      return showSnackBar(response.message);
    }

    diamondBalance.value -= coinPrice;

    _sendCommentToFirestore(
        type: LivestreamCommentType.gift,
        giftId: giftId,
        receiverId: receiverId);
    updateUserStateToFirestore(
      receiverId,
      battleCoin: coinPrice,
      currentBattleCoin: coinPrice,
    );
    sendGift(
        targetUser,
        gift.displayName,
        gift.effectiveAssetUrl.addBaseURL(),
        (gift.soundUrl != null && gift.soundUrl!.trim().isNotEmpty)
            ? gift.soundUrl!.trim().addBaseURL()
            : 'assets/images/fairy-sparkle.mp3');
  }

  @override
  void onClose() {
    super.onClose();
    GiftAudioPlayer.stop();
    if (_isScreenshotPreventionActive) {
      ScreenshotPrevention.instance.disable();
    }
    entryEffectListener?.cancel();
    WakelockPlus.disable();
    timer?.cancel();
    minViewerTimeoutTimer?.cancel();
    videoPlayerController.value?.dispose();
    liveStreamUserStatesListener?.cancel();
    liveStreamCommentsListener?.cancel();
    liveStreamDocListener?.cancel();
    countdownPlayer.dispose();
    winAudioPlayer.dispose();
    stopListenEvent();
    logoutRoom();
  }

  Future<void> initVideoPlayer() async {
    final url = liveData.value.dummyUserLink ?? '';
    if (url.isEmpty) return;

    // Dispose old controller if exists to avoid memory leak
    await videoPlayerController.value?.dispose();

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    isPlayerMute.value = false;

    try {
      await controller.initialize();
      controller
        ..setLooping(true)
        ..play();

      videoPlayerController.value = controller;
      videoPlayerController.value?.setLooping(true);
    } on PlatformException catch (e) {
      showSnackBar(e.message);
      Loggers.error(e);
    }
  }

  void initAudioPlayer() {
    countdownPlayer.setAsset(AssetRes.endCountdown);
    battleStartPlayer.setAsset(AssetRes.battleStart);
    winAudioPlayer.setAsset(AssetRes.winSound);
  }

  Future<void> logoutRoom() async {
    if (isHost) {
      deleteStreamOnFirebase();
    }
    stopPreview();
    stopPublish();
    ZegoExpressEngine.instance.logoutRoom(liveData.value.roomID ?? '');
  }

  Future<ZegoRoomLoginResult> loginRoom() async {
    final roomID = liveData.value.roomID ?? '';
    final user = ZegoUser('$myUserId', myUser.value?.username ?? '');

    final roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;

    try {
      final result = await ZegoExpressEngine.instance.loginRoom(roomID, user, config: roomConfig);

      if (result.errorCode != 0) {
        if (result.errorCode == 1001005) {
          showSnackBar(
              'Please check AppSign is correct or not on ZEGO manage console');
        } else {
          showSnackBar('loginRoom failed: ${result.errorCode}');
        }
        Loggers.error('Login Error : ${result.errorCode}');
        return result;
      }

      if (isHost) {
        startHostPublish();
        return result;
      }

      // For Audience
      final userRef = liveStreamUsersRef.doc('$myUserId');
      final userStateRef = liveStreamUserStatesRef.doc('$myUserId');

      // Set user document if not exists
      if (!(await userRef.get()).exists) {
        final userModel = myUser.value?.appUser;
        if (userModel != null) await userRef.set(userModel.toJson());
      }

      // Fetch user state
      final stateSnap = await userStateRef
          .withConverter(
            fromFirestore: (snapshot, _) =>
                LivestreamUserState.fromJson(snapshot.data()!),
            toFirestore: (value, _) => value.toJson(),
          )
          .get();

      if (!stateSnap.exists) {
        User? myUser = this.myUser.value;
        if (myUser != null) {
          final initialState = myUser.streamState(time: 0);
          await userStateRef.set(initialState.toJson());
          _sendCommentToFirestore(type: LivestreamCommentType.joined);

          // 🔥 NEW: Send entry effect for current user
          if (myUser.appUser != null) {
            sendEntryEffect(myUser.appUser!);
          }
        } else {
          Loggers.error('User not found');
        }

      } else {
        final state = stateSnap.data();
        if (state != null) {
          updateUserStateToFirestore(myUserId,
              type: LivestreamUserType.audience,
              audioStatus: state.audioStatus,
              videoStatus: state.videoStatus);

          User? myUser = this.myUser.value;
          if (myUser?.appUser != null) {
            sendEntryEffect(myUser!.appUser!);
          }
        }
      }
      return result;
    } catch (e) {
      Loggers.error('Error in loginRoom: $e');
      showSnackBar('Something went wrong while joining the room.');
      rethrow;
    }
  }

  void startListenEvent() async {
    // Callback for updates on the status of other users in the room.
    // Users can only receive callbacks when the isUserStatusNotify property of ZegoRoomConfig is set to `true` when logging in to the room (loginRoom).
    ZegoExpressEngine.onRoomUserUpdate =
        (roomID, updateType, List<ZegoUser> userList) {
      // Check if multiple users are in the room
      if (userList.length > 1) {
        // Force audio to speaker
        ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      }
      if (isHost) {
        switch (updateType) {
          case ZegoUpdateType.Add:
            for (var _ in userList) {
              updateLiveStreamData(watchingCount: 1);
            }
            break;
          case ZegoUpdateType.Delete:
            Livestream stream = liveData.value;
            for (var element in userList) {
              if ((stream.watchingCount ?? 0) > 0) {
                updateLiveStreamData(
                    watchingCount: -1,
                    coHostId: FieldValue.arrayRemove([element.userID]));
              }
              int coHostId = int.parse(element.userID);
              bool isCoHostExist =
                  stream.coHostIds?.contains(coHostId) ?? false;
              if (isCoHostExist) {
                updateUserStateToFirestore(coHostId,
                    type: LivestreamUserType.audience,
                    audioStatus: VideoAudioStatus.on,
                    videoStatus: VideoAudioStatus.on);
                updateLiveStreamData(
                    coHostId: FieldValue.arrayRemove([coHostId]));
              }
            }
        }
      }
      Loggers.info(
          'onRoomUserUpdate: roomID: $roomID, updateType: ${updateType.name}, userList: ${userList.map((e) => e.userID)}');
    };
    // Callback for updates on the status of the streams in the room.
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, List<ZegoStream> streamList, extendedData) async {
      String priorityId = liveData.value.hostId.toString();

      streamList.sort((a, b) {
        if (a.streamID == priorityId) return -1; // a goes first
        if (b.streamID == priorityId) return 1; // b goes first
        return a.streamID.compareTo(b.streamID); // regular sorting
      });
      Loggers.info(
          'onRoomStreamUpdate: roomID: $roomID, updateType: $updateType, streamList: ${streamList.map((e) => e.streamID)}, extendedData: $extendedData');
      switch (updateType) {
        case ZegoUpdateType.Add:
          for (final stream in streamList) {
            startPlayStream(stream.streamID);
          }
          break;
        case ZegoUpdateType.Delete:
          for (final stream in streamList) {
            if (liveData.value.roomID == stream.streamID) {
              if (Get.isBottomSheetOpen == false) {
                Get.back();
              }
              for (var element in liveUsersStates) {
                if (element.type == LivestreamUserType.coHost) {
                  streamEnded();
                }
              }
              // Empty LiveData
              logoutRoom();
              stopListenEvent();
              liveData.value = Livestream();
            }
            streamViews.removeWhere((element) => element.streamId == stream.streamID);
            stopPlayStream(stream.streamID);
          }
          break;
      }
    };
    // Callback for updates on the current user's room connection status.
    ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
      Loggers.info(
          'onRoomStateUpdate: roomID: $roomID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };

    // Callback for updates on the current user's stream publishing changes.
    ZegoExpressEngine.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
      switch (state) {
        case ZegoPublisherState.NoPublish:
          streamViews.removeWhere((element) => element.streamId == streamID);
        case ZegoPublisherState.PublishRequesting:
        case ZegoPublisherState.Publishing:
      }
      debugPrint(
          'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
  }



  Future<void> startHostPublish() async {
    if ((liveData.value.roomID ?? '').isEmpty) {
      return Loggers.error('No ID FOUND');
    }
    String streamID = liveData.value.roomID ?? '';
    if (hostPreview == null) {
      deleteStreamOnFirebase();
      Get.back();
      return;
    }
    streamViews.add(StreamView(streamID, liveData.value.hostViewID ?? -1, hostPreview!, false));
    await ZegoExpressEngine.instance.enableCamera(true);
    await ZegoExpressEngine.instance.mutePublishStreamAudio(false); // Ensure audio is not muted
    startMinViewerTimeoutCheck(); //  Check time to Min. Viewers Required to continue live
    pushNotificationToFollowers(liveData.value);
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
    _startLocalRecording();
  }

  Future<void> _startLocalRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/live_${apiLiveStreamId ?? DateTime.now().millisecondsSinceEpoch}.mp4';
      // stopRecordingCapturedData() only signals the SDK to stop; the file
      // isn't safe to read until this callback reports a terminal state
      // (Success/NoRecord), otherwise the MP4 trailer isn't written yet.
      ZegoExpressEngine.onCapturedDataRecordStateUpdate =
          (state, errorCode, config, channel) {
        if (state == ZegoDataRecordState.Recording) return;
        if (_recordingFinalizeCompleter?.isCompleted == false) {
          _recordingFinalizeCompleter!.complete();
        }
      };
      await ZegoExpressEngine.instance.startRecordingCapturedData(
        ZegoDataRecordConfig(path, ZegoDataRecordType.AudioAndVideo),
      );
      _recordingFilePath = path;
      _isRecording = true;
    } catch (e) {
      Loggers.error('startRecordingCapturedData failed: $e');
    }
  }

  Future<void> _stopLocalRecordingAndUpload() async {
    if (!_isRecording) return;
    _isRecording = false;
    try {
      _recordingFinalizeCompleter = Completer<void>();
      await ZegoExpressEngine.instance.stopRecordingCapturedData();
      // Wait for the SDK to finish flushing the file to disk before touching
      // it — capped so a missed callback can't hang the end-stream flow.
      await _recordingFinalizeCompleter!.future
          .timeout(const Duration(seconds: 6), onTimeout: () {});
      final path = _recordingFilePath;
      final streamId = apiLiveStreamId;
      if (path == null || streamId == null) return;
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) return;
      await GiftWalletService.instance.uploadLiveStreamRecording(
        liveStreamId: streamId,
        videoFilePath: path,
      );
      await file.delete();
      Loggers.success('Live stream recording uploaded successfully');
    } catch (e) {
      // Recording/upload failure must never block the normal end-of-stream
      // flow — the session simply keeps video_url null, same as before.
      Loggers.error('stopRecordingCapturedData/upload failed: $e');
    } finally {
      ZegoExpressEngine.onCapturedDataRecordStateUpdate = null;
    }
  }


  Future<void> stopPublish() async {
    return ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> startPlayStream(String streamID) async {

    Loggers.info('Starting to play stream: $streamID');
    int streamViewId = -1;
    try {
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        Loggers.info('Created remote view with ID: $viewID');
        streamViewId = viewID;
        ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
        final config = ZegoPlayerConfig.defaultConfig()
          ..resourceMode = ZegoStreamResourceMode.Default;
         Loggers.info('StartPlayStream playback: StreamID: $streamID, ViewMode: ${canvas.viewMode}, ResourceMode: ${config.resourceMode}');
        ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas, config: config);
      }).then((canvasViewWidget) {
        if (canvasViewWidget != null) {
          streamViews.add(StreamView(streamID, streamViewId, canvasViewWidget, false));
        }
        Loggers.success('Stream playback started successfully for: $streamID');
      });
    } catch (e, stackTrace) {
      Loggers.error('Failed to start playing stream: $e');
      Loggers.error('StackTrace: $stackTrace');
    }
  }



  Future<void> stopPlayStream(String streamID) async {
    Loggers.info('Stopping playback for stream: $streamID');

    try {
      ZegoExpressEngine.instance.stopPlayingStream(streamID);
      Loggers.success('Stopped playing stream: $streamID');

      StreamView? stream = streamViews
          .firstWhereOrNull((element) => element.streamId == streamID);

      if (stream?.streamViewId != null) {
        Loggers.info('Destroying remote view with ID: ${stream?.streamViewId}');
        await ZegoExpressEngine.instance.destroyCanvasView(stream!.streamViewId);
        Loggers.success('Remote view destroyed successfully.');
      }
    } catch (e, stackTrace) {
      Loggers.error('Failed to stop playing stream: $e');
      Loggers.error('StackTrace: $stackTrace');
    }
  }

  Future<void> stopPreview({int? viewId}) async {
    int id = viewId ?? -1;
    ZegoExpressEngine.instance.stopPreview();
    if (id != -1) {
      await ZegoExpressEngine.instance.destroyCanvasView(id);
    }
  }

  Future<void> updateLiveStreamData({
    BattleType? battleType,
    LivestreamType? type,
    int? battleCreatedAt,
    int? battleDuration,
    int watchingCount = 0,
    FieldValue? coHostId,
    int? favouriteGiftId,
  }) async {
    bool isExist = (await liveStreamDocRef.get()).exists;
    if (!isExist) return;

    liveStreamDocRef.update({
      if (battleType != null) FirebaseConst.battleType: battleType.value,
      if (type != null) FirebaseConst.type: type.value,
      if (battleCreatedAt != null)
        FirebaseConst.battleCreatedAt: battleCreatedAt,
      if (battleDuration != null) FirebaseConst.battleDuration: battleDuration,
      if (watchingCount != 0)
        FirebaseConst.watchingCount: FieldValue.increment(watchingCount),
      if (coHostId != null) FirebaseConst.coHostIds: coHostId,
      if (favouriteGiftId != null)
        FirebaseConst.favouriteGiftId: favouriteGiftId,
    });
  }

  void setFavouriteGift(Gift gift) {
    if (gift.id == null) return;
    updateLiveStreamData(favouriteGiftId: gift.id);
  }

  void handleRequestResponse({
    required AppUser? user,
    required bool isRefused,
    LivestreamComment? comment,
  }) {
    final userId = user?.userId;
    if (userId == null) return;

    // Update user state based on refusal
    updateUserStateToFirestore(userId,
        type: isRefused
            ? LivestreamUserType.audience
            : LivestreamUserType.coHost);

    // Determine the comment to delete
    final commentToDelete = comment ??
        comments.firstWhereOrNull((element) =>
            element.senderId == userId &&
            element.commentType == LivestreamCommentType.request);

    if (commentToDelete != null) {
      liveStreamCommentsRef.doc(commentToDelete.id.toString()).delete();
    }
  }

  Future<void> deleteStreamOnFirebase() async {
    final String? roomId = liveData.value.roomID;

    if (roomId == null) {
      Loggers.error('Room ID is null. Cannot stop live stream.');
      return;
    }

    Loggers.info('Stopping live stream Room : $roomId');

    try {
      // Get all users in the livestream and delete them
      QuerySnapshot usersSnapshot = await liveStreamUserStatesRef.get();

      WriteBatch batch = db.batch();

      for (var doc in usersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      Loggers.info(
          'Deleted ${usersSnapshot.docs.length} livestream users_state.');

      // Get all Comments in the livestream and delete them
      QuerySnapshot commentsSnapshot = await liveStreamCommentsRef.get();

      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      Loggers.info(
          'Deleted ${commentsSnapshot.docs.length} livestream comments.');

      // Delete the main live stream document
      batch.delete(liveStreamDocRef);

      // Commit batch delete
      await batch.commit();
      Loggers.success(
          'livestream , users_states , comments  deleted from Firestore.');
    } catch (e, stackTrace) {
      Loggers.error('Failed to stop live stream: $e');
      Loggers.error('StackTrace: $stackTrace');
    }
  }

  void listenLiveStreamData() {
    int likeCount = liveData.value.likeCount ?? 0;
    // liveStreamDocListener?.cancel();
    liveStreamDocListener = liveStreamDocRef
        .withConverter<Livestream>(
          fromFirestore: (snapshot, _) {
            if (!snapshot.exists) {
              Loggers.error(
                  'Livestream document not found for Room ID: ${liveData.value.roomID}');
              return Livestream(); // default instance
            }
            return Livestream.fromJson(snapshot.data()!);
          },
          toFirestore: (value, _) => value.toJson(),
        )
        .snapshots()
        .listen(
      (event) async {
        final stream = event.data();
        if (stream == null) {
          Loggers.warning('Livestream data is null');
          return;
        }

        if (stream.battleType == BattleType.initiate) {
          timer?.cancel();
          remainingBattleSeconds.value =
              Duration(minutes: stream.battleDuration).inSeconds;
          countdownPlayer.pause();
        }

        if (stream.battleType == BattleType.waiting) {
          totalBattleSecond =
              Duration(minutes: stream.battleDuration).inSeconds;
        }

        // Update LiveData
        liveData.value = stream;

        // Trigger like animation if changed
        final newLikeCount = stream.likeCount ?? 0;
        if (likeCount != newLikeCount) {
          onLikeTap?.call();
          likeCount = newLikeCount;
        }
      },
      onError: (error) =>
          Loggers.error('Error listening to livestream: $error'),
    );
  }

  void listenUserState() {
    // Cancel any existing listener
    liveStreamUserStatesListener?.cancel();
    // Loggers.info('👂 Listening to live stream users state...');

    liveStreamUserStatesListener = liveStreamUserStatesRef
        .withConverter(
          fromFirestore: (snapshot, options) {
            if (!snapshot.exists) return null;
            return LivestreamUserState.fromJson(snapshot.data()!);
          },
          toFirestore: (value, options) {
            if (value == null) return {};
            return value.toJson();
          },
        )
        .snapshots()
        .listen((event) {
          // Loggers.info(
          //     '📦 Firestore snapshot received with ${event.docChanges.length} changes');

          for (var change in event.docChanges) {
            final state = change.doc.data();
            if (state == null) {
              // Loggers.warning('⚠️ Null state found in change, skipping...');
              continue;
            }

            switch (change.type) {
              case DocumentChangeType.added:
                _showJoinStreamSheet(state);
                liveUsersStates.add(state);
                // Loggers.info('➕ User added: ${state.userId}');

                break;

              case DocumentChangeType.modified:
                LivestreamUserState? oldState =
                    liveUsersStates.firstWhereOrNull(
                        (element) => element.userId == state.userId);

                updateStateAction(oldState, state);

                int index =
                    liveUsersStates.indexWhere((u) => u.userId == state.userId);
                if (index != -1) {
                  liveUsersStates[index] = state;
                } else {
                  liveUsersStates.add(state);
                }
                // Loggers.info('🔁 User modified: ${state.userId}');
                break;

              case DocumentChangeType.removed:
                liveUsersStates.removeWhere((u) => u.userId == state.userId);
                // Loggers.info('➖ User removed: ${state.userId}');
                break;
            }
          }
          requestList.value = liveUsersStates
              .where((element) => element.type == LivestreamUserType.requested)
              .toList();

          // "Auto Call" (set when the host went live) auto-accepts co-host
          // requests instead of the host approving each one manually —
          // mirrors AudioRoomController's proven auto-accept pattern.
          if (liveData.value.hostId == myUserId &&
              (liveData.value.isAutoMode ?? false) &&
              requestList.isNotEmpty &&
              coHostList.length < AppRes.maxVideoCoHosts) {
            final freeSeats = AppRes.maxVideoCoHosts - coHostList.length;
            for (final state in requestList.take(freeSeats)) {
              handleRequestResponse(
                user: state.getUser(firestoreController.users),
                isRefused: false,
              );
            }
          }

          audienceList.value = liveUsersStates
              .where((element) =>
                  element.type != LivestreamUserType.host &&
                  element.type != LivestreamUserType.left)
              .toList();
          invitedList.value = liveUsersStates
              .where((element) => element.type == LivestreamUserType.invited)
              .toList();
          coHostList.value = liveUsersStates
              .where((element) => element.type == LivestreamUserType.coHost)
              .toList();
          audienceMemberList.value = liveUsersStates
              .where((element) =>
                  element.type != LivestreamUserType.left &&
                  element.userId != myUserId)
              .toList();
        });
  }

  void fetchLiveStreamComments() {
    Loggers.info('Fetching live stream comments...');
    liveStreamCommentsListener?.cancel();
    liveStreamCommentsListener = liveStreamCommentsRef
        .withConverter(
          fromFirestore: (snapshot, options) {
            if (!snapshot.exists) {
              Loggers.error('No comments found in Firestore.');
              return null;
            }
            return LivestreamComment.fromJson(snapshot.data()!);
          },
          toFirestore: (value, options) => value?.toJson() ?? {},
        )
        .snapshots()
        .listen((querySnapshot) {
      // Loggers.info(
      //     'Received comment changes: ${querySnapshot.docChanges.length}');

      for (var change in querySnapshot.docChanges) {
        LivestreamComment? comment = change.doc.data();
        if (comment == null) {
          Loggers.error('Null comment received.');
          continue;
        }

        switch (change.type) {
          case DocumentChangeType.added:
            firestoreController.fetchUserIfNeeded(comment.senderId ?? -1);
            if (comment.commentType == LivestreamCommentType.request &&
                !isHost) {
              continue;
            }
            comments.add(comment);
            // Loggers.info('New comment added: ${comment.toJson()}');
            break;

          case DocumentChangeType.modified:
            if (comment.commentType == LivestreamCommentType.request &&
                !isHost) {
              return;
            }
            int index = comments.indexWhere((c) => c.id == comment.id);
            if (index != -1) {
              comments[index] = comment;
              // Loggers.info('Comment modified: ${comment.toJson()}');
            }
            break;

          case DocumentChangeType.removed:
            comments.removeWhere((c) => c.id == comment.id);
            // Loggers.info('Comment removed: ${comment.id}');
            break;
        }
      }

      // Assign sender and receiver users to comments
      for (var comment in comments) {
        comment.gift =
            gifts.firstWhereOrNull((gift) => gift.id == comment.giftId);
      }

      comments.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    });
  }

  void toggleCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera, channel: ZegoPublishChannel.Main);
  }

  void toggleFlipCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera, channel: ZegoPublishChannel.Main);
  }

  void toggleMic(LivestreamUserState? state) async {
    if (state?.audioStatus == VideoAudioStatus.offByHost) {
      return showSnackBar(LKey.theHostHasTurnedOffYourAudio);
    }

    bool isAudioOn = state?.audioStatus == VideoAudioStatus.on;

    if (isAudioOn) {
      updateUserStateToFirestore(myUserId,
          audioStatus: VideoAudioStatus.offByMe);
      ZegoExpressEngine.instance.muteMicrophone(true);
    } else {
      updateUserStateToFirestore(myUserId, audioStatus: VideoAudioStatus.on);
      ZegoExpressEngine.instance.muteMicrophone(false);
    }
  }

  // RxBool isVideoOn = true.obs;
  void toggleVideo(LivestreamUserState? state) async {
    if (state?.videoStatus == VideoAudioStatus.offByHost) {
      return showSnackBar(LKey.theHostHasTurnedOffYourVideo.tr);
    }
    bool isVideoOn = state?.videoStatus == VideoAudioStatus.on;
    Loggers.error(isVideoOn);
    if (isVideoOn) {
      updateUserStateToFirestore(myUserId,
          videoStatus: VideoAudioStatus.offByMe);
      await ZegoExpressEngine.instance.enableCamera(false);
      print('HELLO WOW');
    } else {
      updateUserStateToFirestore(myUserId, videoStatus: VideoAudioStatus.on);
      await ZegoExpressEngine.instance.enableCamera(true);
      print('HELLO NOTHING');
    }
  }

  void toggleStreamAudio(int? streamId) {
    StreamView? view = streamViews
        .firstWhereOrNull((element) => int.parse(element.streamId) == streamId);

    ZegoExpressEngine.instance.mutePlayStreamAudio(
        '$streamId', (view?.isMuted ?? false) ? false : true);
    view?.isMuted = view.isMuted ? false : true;
    if (view != null) {
      streamViews[streamViews.indexWhere(
          (element) => int.parse(element.streamId) == streamId)] = view;
      streamViews.refresh();
    }
  }

  void onLikeButtonTap() async {
    bool isExist = (await liveStreamDocRef.get()).exists;
    if (isExist) {
      HapticManager.shared.light();
      liveStreamDocRef
          .update({FirebaseConst.likeCount: FieldValue.increment(1)});
    }
  }

  void onTextCommentSend() {
    String comment = textCommentController.text.trim();
    textCommentController.clear();
    isTextEmpty.value = true;
    if (comment.isEmpty) return;
    _sendCommentToFirestore(type: LivestreamCommentType.text, comment: comment);
  }

  /// Host waving at a viewer who just joined — a real chat message, not a
  /// fake/local-only animation, so everyone in the room sees it too.
  void sendWave(AppUser? user) {
    if (user?.username == null) return;
    _sendCommentToFirestore(
        type: LivestreamCommentType.text,
        comment: '👋 waved at ${user!.username}');
  }

  void onGiftTap(GiftType type,
      {BattleView battleViewType = BattleView.red,
      List<AppUser> users = const []}) {
    users.removeWhere((element) => element.userId == myUserId);
    if (liveData.value.type == LivestreamType.battle &&
        liveData.value.battleType == BattleType.end) {
      return showSnackBar(LKey.battleEndedGiftNotSent.tr);
    }
    GiftManager.openGiftSheet(
        source: 'video_gift',
        onCompletion: (giftManager) {
          Gift gift = giftManager.gift;
          AppUser? user = giftManager.streamUser;

          int coinPrice = gift.coinPrice?.toInt() ?? 0;

          _sendCommentToFirestore(
              type: LivestreamCommentType.gift,
              giftId: gift.id,
              receiverId: user?.userId);
          updateUserStateToFirestore(
            user?.userId,
            battleCoin: type == GiftType.battle ? coinPrice : null,
            currentBattleCoin: type == GiftType.battle ? coinPrice : null,
            liveCoin: type == GiftType.livestream ? coinPrice : null,
          );

          if (user != null) {
            final sound = gift.effectiveSoundUrl.isNotEmpty
                ? gift.effectiveSoundUrl
                : 'assets/images/fairy-sparkle.mp3';
            sendGift(
                user,
                gift.displayName,
                gift.effectiveAssetUrl.addBaseURL(),
                sound,
                giftId: gift.id,
                coinPrice: coinPrice,
            );
          }

        },
        giftType: type,
        battleViewType: battleViewType,
        streamUsers: users);
  }

  _sendCommentToFirestore(
      {required LivestreamCommentType type,
      String? comment,
      int? giftId,
      int? receiverId}) async {
    int time = DateTime.now().millisecondsSinceEpoch;
    try {
      await _addUsersFirebaseFireStore();
      liveStreamCommentsRef.doc('$time').set(LivestreamComment(
              comment: comment,
              commentType: type,
              id: time,
              senderId: myUserId,
              receiverId: receiverId,
              giftId: giftId)
          .toJson());

      // GIFT comments feed the end-of-session "Premium Gifts"/"Stars Earned"
      // insight stats, so a dropped write here silently zeroes those out even
      // though the diamonds already left the sender's wallet. Await it and
      // retry once instead of firing-and-forgetting like other comment types.
      bool saved = await _saveCommentToApi(
        commentType: type,
        comment: comment,
        giftId: giftId,
        receiverId: receiverId,
      );
      if (!saved && type == LivestreamCommentType.gift) {
        await Future.delayed(const Duration(milliseconds: 800));
        saved = await _saveCommentToApi(
          commentType: type,
          comment: comment,
          giftId: giftId,
          receiverId: receiverId,
        );
        if (!saved) {
          Loggers.error(
              'Gift comment failed to save after retry: giftId=$giftId receiverId=$receiverId');
        }
      }
    } catch (e) {
      Loggers.error('Message Error : $e');
    }
  }

  Future<bool> _saveCommentToApi({
    required LivestreamCommentType commentType,
    String? comment,
    int? giftId,
    int? receiverId,
  }) async {
    try {
      StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.saveLiveStreamComment,
        param: {
          Params.liveStreamId: liveData.value.roomID,
          Params.senderId: myUserId,
          Params.commentType: commentType.value,
          Params.comment: comment,
          Params.receiverId: receiverId,
          Params.giftId: giftId,
        },
        fromJson: StatusModel.fromJson,
      );
      return response.status == true;
    } catch (e) {
      Loggers.error('saveLiveStreamComment error: $e');
      return false;
    }
  }

  Future<void> _addUsersFirebaseFireStore() async {
    DocumentReference myUserRef = liveStreamUsersRef.doc(myUserId.toString());

    DocumentSnapshot isMyUserExist = await myUserRef.get();
    if (myUser.value != null) {
      if (isMyUserExist.exists) {
        myUserRef.update(myUser.value!.appUser.toJson());
      } else {
        myUserRef.set(myUser.value?.appUser.toJson());
      }
    }
  }

  void onVideoRequestSend(Livestream liveData) {
    LivestreamUserState? state = liveUsersStates
        .firstWhereOrNull((element) => element.userId == myUserId);
    switch (state?.type) {
      case null:
        break;
      case LivestreamUserType.audience:
        updateUserStateToFirestore(myUserId,
            type: LivestreamUserType.requested);
        _sendCommentToFirestore(
            type: LivestreamCommentType.request, receiverId: liveData.hostId);
        showSnackBar(LKey.requestJoinToHost.tr);
        break;
      case LivestreamUserType.requested:
        showSnackBar(LKey.joinRequestSentDescription.tr);
        break;
      case LivestreamUserType.host:
      case LivestreamUserType.coHost:
      case LivestreamUserType.invited:
      case LivestreamUserType.left:
        break;
    }
  }

  Future<void> updateUserStateToFirestore(
    int? userId, {
    LivestreamUserType? type,
    VideoAudioStatus? audioStatus,
    VideoAudioStatus? videoStatus,
    int? battleCoin,
    int? liveCoin,
    bool? isFollow,
    int? joinTime,
    int? currentBattleCoin,
  }) async {
    if (userId == null) {
      Loggers.error('updateUserStateToFirestore: userId is null');
      return;
    }

    DocumentReference reference =
        liveStreamUserStatesRef.doc(userId.toString());
    bool isExist = (await reference.get()).exists;
    if (!isExist) {
      Loggers.error('updateUserStateToFirestore Not Found $userId');
      return;
    }

    try {
      final updateData = <String, dynamic>{
        if (type != null) FirebaseConst.type: type.value,
        if (audioStatus != null) FirebaseConst.audioStatus: audioStatus.value,
        if (videoStatus != null) FirebaseConst.videoStatus: videoStatus.value,
        if (battleCoin != null)
          FirebaseConst.totalBattleCoin:
              battleCoin == 0 ? 0 : FieldValue.increment(battleCoin),
        if (currentBattleCoin != null)
          FirebaseConst.currentBattleCoin: currentBattleCoin == 0
              ? 0
              : FieldValue.increment(currentBattleCoin),
        if (liveCoin != null)
          FirebaseConst.liveCoin:
              liveCoin == 0 ? 0 : FieldValue.increment(liveCoin),
        if (isFollow != null)
          FirebaseConst.followersGained: isFollow
              ? FieldValue.arrayUnion([myUserId])
              : FieldValue.arrayRemove([myUserId]),
        if (joinTime != null) FirebaseConst.joinStreamTime: joinTime,
      };
      if (battleCoin != null || liveCoin != null) {
        myUser.value?.coinEstimatedValue(
            battleCoin?.toDouble() ?? liveCoin?.toDouble());
        SessionManager.instance.setUser(myUser.value);
      }
      await liveStreamUserStatesRef.doc(userId.toString()).update(updateData);
      Loggers.success('User state updated for userId: $userId');
    } catch (e, stack) {
      Loggers.error('Failed to update user state: $e\n$stack');
    }
  }

  void onInvite(AppUser? user, {bool isInvited = false}) {
    updateUserStateToFirestore(user?.userId,
        type: isInvited
            ? LivestreamUserType.audience
            : LivestreamUserType.invited);
  }

  void _showJoinStreamSheet(LivestreamUserState state) {
    if (state.userId == myUserId && state.type == LivestreamUserType.invited) {
      AppUser? hostUser = liveData.value.getHostUser(firestoreController.users);
      isJoinSheetOpen = true;
      Get.bottomSheet(
              LiveStreamJoinSheet(
                  hostUser: hostUser,
                  myUser: myUser.value,
                  onJoined: () async {
                    LivestreamUserState? userState =
                        liveUsersStates.firstWhereOrNull(
                            (element) => element.userId == myUserId);
                    if (userState?.type == LivestreamUserType.invited) {
                      updateUserStateToFirestore(myUserId,
                          type: LivestreamUserType.coHost);
                    } else {
                      showSnackBar(LKey.joinCancelledDescription.tr);
                    }
                  },
                  onCancel: () {
                    updateUserStateToFirestore(myUserId,
                        type: LivestreamUserType.audience);
                  }),
              isScrollControlled: true,
              enableDrag: false,
              isDismissible: false)
          .then(
        (value) {
          isJoinSheetOpen = false;
        },
      );
    }
  }

  void publishCoHostStream(int streamId) async {
    bool isPermissionGranted = await requestPermission();
    if (isPermissionGranted) {
      int canvasViewID = -1;

      // ✅ Enable camera and microphone
      await ZegoExpressEngine.instance.enableCamera(true);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
      ZegoExpressEngine.instance.muteMicrophone(false);

      // ✅ Create preview canvas and start preview
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        canvasViewID = viewID;
        ZegoCanvas previewCanvas =
            ZegoCanvas(canvasViewID, viewMode: ZegoViewMode.AspectFill);
        ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
      }).then((canvasViewWidget) {
        if (canvasViewWidget != null) {
          streamViews.add(
            StreamView('$streamId', canvasViewID, canvasViewWidget, false),
          );
        }
      });

      // ✅ Publish the stream
      await ZegoExpressEngine.instance.startPublishingStream('$streamId');

      // ✅ Force audio output to speaker (after stream starts)
      Future.delayed(const Duration(milliseconds: 300), () {
        ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      });

      updateLiveStreamData(coHostId: FieldValue.arrayUnion([streamId]));
      _sendCommentToFirestore(type: LivestreamCommentType.joinedCoHost);
      updateUserStateToFirestore(myUserId,
          joinTime: DateTime.now().millisecondsSinceEpoch);
    } else {
      Get.bottomSheet(ConfirmationSheet(
        title: LKey.cameraMicrophonePermissionTitle.tr,
        description: LKey.cameraMicrophonePermissionDescription.tr,
        onTap: openAppSettings,
      ));
    }
  }

  void closeCoHostStream(int? streamId) {
    StreamView? view = streamViews
        .firstWhereOrNull((element) => element.streamId == '$streamId');
    if (view != null) {
      stopPreview(viewId: view.streamViewId);
      stopPublish();
      updateLiveStreamData(coHostId: FieldValue.arrayRemove([streamId]));
      LivestreamComment? comment = comments.firstWhereOrNull((element) =>
          element.senderId == myUserId &&
          element.commentType == LivestreamCommentType.joinedCoHost);
      if (comment != null) {
        liveStreamCommentsRef.doc(comment.id.toString()).delete();
      }
      updateUserStateToFirestore(streamId,
          type: LivestreamUserType.audience,
          audioStatus: VideoAudioStatus.offByMe,
          videoStatus: VideoAudioStatus.offByMe,
          battleCoin: 0,
          currentBattleCoin: 0);
      streamViews.removeWhere((element) => element.streamId == '$streamId');
      stopPlayStream(streamId.toString());
      streamEnded();
    }
  }

  Future<bool> requestPermission() async {
    Loggers.info("requestPermission...");
    try {
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        Loggers.error('Error: Microphone permission not granted!!!');
        return false;
      }
    } on Exception catch (error) {
      Loggers.error("[ERROR], request microphone permission exception, $error");
    }

    try {
      PermissionStatus cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        Loggers.error('Error: Camera permission not granted!!!');
        return false;
      }
    } on Exception catch (error) {
      Loggers.error("[ERROR], request camera permission exception, $error");
    }

    return true;
  }

  void coHostVideoToggle(LivestreamUserState state) {
    if (state.videoStatus == VideoAudioStatus.offByMe) {
      return showSnackBar(LKey.theCoHostHasTurnedOffTheirVideo);
    }

    updateUserStateToFirestore(state.userId,
        videoStatus: state.videoStatus == VideoAudioStatus.on
            ? VideoAudioStatus.offByHost
            : VideoAudioStatus.on);
  }

  void coHostAudioToggle(LivestreamUserState state) {
    if (state.audioStatus == VideoAudioStatus.offByMe) {
      return showSnackBar(LKey.theCoHostHasTurnedOffTheirAudio);
    }

    updateUserStateToFirestore(state.userId,
        audioStatus: state.audioStatus == VideoAudioStatus.on
            ? VideoAudioStatus.offByHost
            : VideoAudioStatus.on);
  }

  void updateStateAction(
      LivestreamUserState? oldState, LivestreamUserState newState) {
    if (newState.userId == myUserId) {
      Loggers.info('Updating state for userId: ${newState.toJson()}');
      if (newState.type == LivestreamUserType.coHost &&
          oldState?.type != LivestreamUserType.coHost) {
        publishCoHostStream(myUserId);
      }

      if (newState.type == LivestreamUserType.audience &&
          oldState?.type == LivestreamUserType.invited &&
          isJoinSheetOpen) {
        Get.back();
      }

      if (newState.type == LivestreamUserType.invited &&
          oldState?.type == LivestreamUserType.audience) {
        _showJoinStreamSheet(newState);
      }
      if (oldState?.type == LivestreamUserType.coHost &&
          newState.type == LivestreamUserType.audience) {
        closeCoHostStream(newState.userId);
      }
    }
  }

  void coHostDelete(LivestreamUserState state) {
    if (state.type == LivestreamUserType.coHost) {
      updateLiveStreamData(coHostId: FieldValue.arrayRemove([state.userId]));
      updateUserStateToFirestore(state.userId,
          type: LivestreamUserType.audience);
    }
  }

  void reportUser(int? userId) {
    Get.bottomSheet(ReportSheet(reportType: ReportType.user, id: userId),
        isScrollControlled: true);
  }

  void _timerStart(VoidCallback callBack) {
    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (t) {
        callBack.call();
        // if (t.tick >= totalBattleSecond) {
        //   timer?.cancel();
        // }
      },
    );
  }

  void onStopButtonTap() {
    bool isBattleOn = liveData.value.type == LivestreamType.battle;
    String title =
        !isBattleOn ? LKey.endStreamTitle.tr : LKey.stopBattleTitle.tr;
    String description =
        !isBattleOn ? LKey.endStreamMessage.tr : LKey.stopBattleDescription.tr;

    Get.bottomSheet(
        StopLiveStreamSheet(
            onTap: () {
              if (isBattleOn) {
                updateLiveStreamData(
                    battleType: BattleType.initiate,
                    type: LivestreamType.livestream);
                startMinViewerTimeoutCheck();
              } else {
                hostEndStream();
              }
            },
            title: title,
            description: description,
            positiveText: LKey.stop.tr),
        isScrollControlled: true);
  }

  Future<void> hostEndStream() async {
    // Snapshot the host's own gift/follower totals right now, before any
    // awaited work below runs. liveUsersStates is rebuilt from fresh
    // LivestreamUserState.fromJson() objects on every Firestore snapshot —
    // capturing this reference now means later snapshot churn (e.g. the
    // brief window while the recording uploads) can't null out or reset
    // the numbers the summary screen ends up showing.
    LivestreamUserState? endedUserState = liveUsersStates
        .firstWhereOrNull((element) => element.userId == myUserId);
    int endedViewers = liveUsersStates.length;

    _endLiveStreamApi();
    // Must finish before logoutRoom() stops the camera/mic capture that the
    // local recording is reading from, or the recorded file gets truncated.
    await _stopLocalRecordingAndUpload();
    streamEnded(capturedUserState: endedUserState, capturedViewers: endedViewers);
    logoutRoom();
  }

  Future<void> _endLiveStreamApi() async {
    if (apiLiveStreamId == null) return;
    try {
      await GiftWalletService.instance.endLiveStream(liveStreamId: apiLiveStreamId!);
      Loggers.success('endLiveStream API called successfully');
    } catch (e) {
      Loggers.error('endLiveStream API error: $e');
    }
  }

  void streamEnded({LivestreamUserState? capturedUserState, int? capturedViewers}) {
    LivestreamUserState? userState = capturedUserState ??
        liveUsersStates.firstWhereOrNull((element) => element.userId == myUserId);
    AppUser? user = firestoreController.users.firstWhereOrNull((element) => element.userId == myUserId);
    userState?.user = user;
    int viewers = capturedViewers ?? liveUsersStates.length;
    if (isHost) {
      Get.back();
      Get.off(() => LiveStreamEndScreen(
          userState: userState, isHost: isHost, viewers: viewers));
    } else {
      if (userState?.type == LivestreamUserType.coHost) {
        Get.bottomSheet(
                LiveStreamSummary(
                    userState: userState, isHost: isHost, viewers: viewers),
                isScrollControlled: true)
            .then((value) {
          updateUserStateToFirestore(myUserId,
              battleCoin: 0,
              liveCoin: 0,
              currentBattleCoin: 0,
              type: LivestreamUserType.audience);
          if ((liveData.value.roomID ?? '').isEmpty) {
            Get.back();
          }
        });
      }
    }
  }

  togglePlayerAudioToggle() {
    videoPlayerController.value?.setVolume(isPlayerMute.value ? 1 : 0);
    isPlayerMute.value = !isPlayerMute.value;
  }

  void toggleView() {
    isViewVisible.value = !isViewVisible.value;
  }

  void startBattle() {
    expandedBattleUserIndex.value = null;
    final duration = SessionManager.instance.getSettings()?.battleDurationMinutes ??
        AppRes.battleDurationInMinutes;
    updateLiveStreamData(
      battleType: BattleType.waiting,
      battleDuration: duration,
      battleCreatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void battleRunning() {
    Livestream stream = liveData.value;
    // Battle Start Timer Logic

    final startTime =
        DateTime.fromMillisecondsSinceEpoch(stream.battleCreatedAt ?? 0);
    final endTime = startTime
        .add(Duration(seconds: totalBattleSecond + AppRes.battleStartInSecond));

    Loggers.success('Battle Timer Started');

    _timerStart(() {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      remainingBattleSeconds.value = remaining.clamp(0, totalBattleSecond);

      if (remainingBattleSeconds.value <= 10) {
        if (!countdownPlayer.playing) {
          countdownPlayer
              .seek(Duration(seconds: 10 - remainingBattleSeconds.value));
          countdownPlayer.play();
        }
      }

      Loggers.info(
          '[BATTLE RUNNING] Battle end in ${remainingBattleSeconds.value} sec.');

      if (remainingBattleSeconds.value <= 0) {
        winAudioPlayer.seek(const Duration(seconds: 0));
        winAudioPlayer.play();
        timer?.cancel();
        _saveBattleResult();
        updateLiveStreamData(battleType: BattleType.end);
      }
    });
  }

  /// Only the host writes the row — both sides run this timer, and the
  /// backend resolves the winner from the coin totals.
  Future<void> _saveBattleResult() async {
    if (!isHost) return;
    final hostState =
        liveUsersStates.firstWhereOrNull((e) => e.userId == myUserId);
    final coHostState = coHostList.firstOrNull;
    final opponentId = coHostState?.userId;
    if (hostState == null || opponentId == null) return;

    try {
      await GiftWalletService.instance.saveBattleResult(
        mode: 'video',
        user1Id: myUserId,
        user2Id: opponentId,
        user1Coins: hostState.currentBattleCoin,
        user2Coins: coHostState!.currentBattleCoin,
        durationMinutes: liveData.value.battleDuration,
      );
    } catch (e) {
      Loggers.error('saveBattleResult error: $e');
    }
  }

  void startMinViewerTimeoutCheck() {
    if (minViewerTimeoutTimer?.isActive ?? false) return;
    Loggers.info(
        'Check Min. Viewers Required to continue live $timeoutMinutes Minutes');
    minViewerTimeoutTimer =
        Timer.periodic(Duration(minutes: timeoutMinutes), (_) {
      minViewerTimeoutTimer?.cancel();
      if ((liveData.value.watchingCount ?? 0) <= minViewersThreshold) {
        isMinViewerTimeout.value = true;
        Loggers.info('Close Stream Because of Min. Viewers');
      }
    });
  }

  void onCloseAudienceBtn() {
    HapticManager.shared.light();
    Get.bottomSheet(ConfirmationSheet(
        title: LKey.exitLiveStreamTitle.tr,
        description: LKey.exitLiveStreamDescription.tr,
        onTap: () async {
          Get.back();
          if (liveData.value.coHostIds?.contains(myUserId) ?? false) {
            closeCoHostStream(myUserId);
          }
          logoutRoom();
        }));
  }

  void pushNotificationToFollowers(Livestream liveData) {
    AppUser? hostUser = liveData.getHostUser([]);
    NotificationService.instance.pushNotification(
        type: NotificationType.liveStream,
        title: LKey.liveStreamNotificationTitle
            .trParams({'name': hostUser?.username ?? ''}),
        body: LKey.liveStreamNotificationBody.tr,
        deviceType: 1,
        topic: '${liveData.hostId}_ios',
        data: liveData.toJson());
    NotificationService.instance.pushNotification(
        type: NotificationType.liveStream,
        title: LKey.liveStreamNotificationTitle
            .trParams({'name': hostUser?.username ?? ''}),
        body: LKey.liveStreamNotificationBody.tr,
        deviceType: 0,
        topic: '${liveData.hostId}_android',
        data: liveData.toJson());
  }
}

class StreamView {
  String streamId;
  int streamViewId;
  Widget streamView;
  bool isMuted;

  StreamView(this.streamId, this.streamViewId, this.streamView, this.isMuted);
}
