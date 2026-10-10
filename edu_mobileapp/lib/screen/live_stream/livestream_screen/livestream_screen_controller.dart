import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/screenshot_prevention.dart';
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
import 'package:geoedu/screen/live_stream/livestream_screen/audience/widget/live_stream_join_sheet.dart';
import 'package:geoedu/common/widget/live_summary_dialog.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/screen/live_stream/live_stream_end_screen/widget/livestream_summary.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/screen/report_sheet/report_sheet.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:geoedu/utilities/app_res.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requested_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requests_sheet.dart';
import 'package:geoedu/common/widget/live_room/favourite_gift_sheet.dart';
import 'package:geoedu/common/widget/live_room/target_achieved_dialog.dart';
import 'package:geoedu/common/widget/live_room/set_live_target_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/pk_battle_duration_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/pk_battle_result_dialog.dart';

import '../../../common/extensions/string_extension.dart';
import '../../../model/livestream/entry_effects_model.dart';

class LivestreamScreenController extends BaseController {
  FirebaseFirestore db = FirebaseFirestore.instance;
  // ZegoExpressEngine zegoEngine = ZegoExpressEngine.instance;

  final firestoreController = Get.find<FirebaseFirestoreController>();

  Timer? timer;
  Timer? minViewerTimeoutTimer;
  Timer? _dummyChatTimer;
  Timer? _dummyLikeTimer;
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

  RxString pinnedComment = ''.obs;
  TextEditingController pinCommentController = TextEditingController();
  RxBool isPinInputOpen = false.obs;

  RxString topGifterName = ''.obs;
  RxInt topGifterCoins = 0.obs;

  List<Gift> get availableGifts =>
      setting?.availableGifts ?? setting?.gifts ?? [];

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

    // Sync targetDiamonds and favouriteGiftTarget from liveData
    if (liveData.value.targetDiamonds != null && liveData.value.targetDiamonds! > 0) {
      targetDiamonds.value = liveData.value.targetDiamonds!;
    }
    if (liveData.value.favouriteGiftTarget != null && liveData.value.favouriteGiftTarget! > 0) {
      favouriteGiftTarget.value = liveData.value.favouriteGiftTarget!;
    }
    liveData.listen((stream) {
      if (stream.targetDiamonds != null) {
        targetDiamonds.value = stream.targetDiamonds!;
      }
      if (stream.favouriteGiftTarget != null) {
        favouriteGiftTarget.value = stream.favouriteGiftTarget!;
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
  RxBool hasDismissedJoinCallBanner = false.obs;

  // Inline battle gift bar (EloTV-style tap-to-send row, replaces the old
  // full-screen gift sheet during a PK battle).
  RxBool isBattleGiftBarOpen = false.obs;
  Rx<BattleView> selectedBattleSide = BattleView.red.obs;
  RxInt diamondBalance = 0.obs;
  bool _diamondBalanceFetched = false;

  int get maxCallSeats =>
      (liveData.value.maxParticipants != null && liveData.value.maxParticipants! > 0)
          ? liveData.value.maxParticipants!
          : 7;
  static const int defaultMaxCallSeats = 7;

  // Tap either side of the PK battle split screen to give it more space;
  // tap the same side again (or the other side) to change/clear the focus.
  Rx<int?> expandedBattleUserIndex = Rx<int?>(null);

  // PK Battle invitation & opponent tracking
  RxList<int> pkInvitedUserIds = <int>[].obs;
  Rx<int?> pkOpponentId = Rx<int?>(null);
  Rx<AppUser?> pkOpponentUser = Rx<AppUser?>(null);
  bool isPkInviteDialogOpen = false;
  void Function(int hostId, String hostName)? onCallParticipantPkInviteReceived;

  // PK Battle Duration & State
  RxInt selectedBattleDuration = 2.obs;
  bool _isRoundFinalizing = false;
  bool isPkResultPopupShowing = false;

  // Viewer-Side Host Selection & Live Switching
  Rx<int?> selectedBattleHostId = Rx<int?>(null);
  RxBool isSwitchingHost = false.obs;
  Rx<AppUser?> switchingTargetUser = Rx<AppUser?>(null);

  AppUser? get effectiveSelectedBattleHost {
    final targetId = selectedBattleHostId.value ?? liveData.value.hostId;
    if (targetId == null) return null;
    return firestoreController.users.firstWhereOrNull((u) => u.userId == targetId) ??
        liveUsersStates.firstWhereOrNull((u) => u.userId == targetId)?.getUser(firestoreController.users) ??
        (targetId == liveData.value.hostId ? liveData.value.hostUser : null);
  }

  Future<void> switchBattleHost(int targetHostId) async {
    if (selectedBattleHostId.value == targetHostId) return;
    HapticManager.shared.medium();
    final targetUser = firestoreController.users.firstWhereOrNull((u) => u.userId == targetHostId) ??
        liveUsersStates.firstWhereOrNull((u) => u.userId == targetHostId)?.getUser(firestoreController.users);
    switchingTargetUser.value = targetUser;
    isSwitchingHost.value = true;
    await Future.delayed(const Duration(milliseconds: 750));
    selectedBattleHostId.value = targetHostId;
    selectedGiftUser.value = targetUser;
    if (targetHostId == liveData.value.hostId) {
      selectedBattleSide.value = BattleView.red;
    } else {
      selectedBattleSide.value = BattleView.blue;
    }
    isSwitchingHost.value = false;
  }

  void toggleBattleFocus(int index) {
    expandedBattleUserIndex.value =
        expandedBattleUserIndex.value == index ? null : index;
  }

  Set<int> _previousCoHostIds = <int>{};
  bool _initialLiveDocLoaded = false;
  final Set<int> _recentlyNotifiedLeft = <int>{};

  void notifyCoHostLeft(int? userId) {
    if (userId == null ||
        userId == myUserId ||
        userId == liveData.value.hostId) {
      return;
    }

    // Safety check: is the user still actually active on the call?
    final bool isStillOnCall = liveUsersStates.any(
            (u) => u.userId == userId && u.type == LivestreamUserType.coHost) ||
        streamViews.any((s) => s.streamId == '$userId') ||
        (liveData.value.coHostIds?.contains(userId) ?? false);
    if (isStillOnCall) {
      return;
    }

    if (_recentlyNotifiedLeft.contains(userId)) return;
    _recentlyNotifiedLeft.add(userId);
    Future.delayed(const Duration(seconds: 4), () {
      _recentlyNotifiedLeft.remove(userId);
    });

    // Lookup user display name
    AppUser? user = firestoreController.users
        .firstWhereOrNull((u) => u.userId == userId);
    user ??= liveUsersStates
        .firstWhereOrNull((u) => u.userId == userId)
        ?.getUser(firestoreController.users);

    final name = user?.fullname ?? user?.username ?? 'Co-host';

    HapticManager.shared.medium();

    if (isHost) {
      showSnackBar('$name has left the call', second: 3);
    }

    // Post to Firestore comments: use the departed user's userId & user object!
    _sendCommentToFirestore(
      type: LivestreamCommentType.leftCoHost,
      comment: '$name left the call',
      senderId: userId,
      senderUser: user,
    );
  }

  void leaveCoHostCall() {
    closeCoHostStream(myUserId);
    showSnackBar('You have left the video call');
  }

  Rx<User?> get myUser => SessionManager.instance.getUser().obs;
  Rx<Livestream> liveData;

  // Global (not per-instance) so it persists as a real user preference for
  // the whole session rather than resetting every time this screen rebuilds.
  static RxBool isGiftSoundOn = true.obs;

  // Host-set diamond goal for this session — synced to Firestore so viewers
  // also see the target and live progress.
  RxInt targetDiamonds = 0.obs;
  void setTargetDiamonds(int value) async {
    targetDiamonds.value = value;
    checkTargets();
    if (isHost && liveData.value.roomID != null) {
      try {
        await liveStreamDocRef.update({'target_diamonds': value});
      } catch (e) {
        Loggers.error('setTargetDiamonds error: $e');
      }
    }
  }

  // Track which co-host card is currently enlarged (host-only focus/preview mode)
  final RxnInt enlargedCoHostUserId = RxnInt();

  // Favorite / Mission Gift target count (defaults to 3, can be increased)
  RxInt favouriteGiftTarget = 3.obs;
  void setFavouriteGiftTarget(int value) async {
    favouriteGiftTarget.value = value;
    checkTargets();
    if (isHost && liveData.value.roomID != null) {
      try {
        await liveStreamDocRef.update({'favourite_gift_target': value});
      } catch (e) {
        Loggers.error('setFavouriteGiftTarget error: $e');
      }
    }
  }

  int get favouriteGiftReceivedCount {
    final favId = liveData.value.favouriteGiftId ?? featuredGift?.id;
    final favName = featuredGift?.displayName ?? featuredGift?.title;
    if (favId == null && favName == null) return 0;
    return comments
        .where((c) =>
            c.commentType == LivestreamCommentType.gift &&
            (c.receiverId == null || c.receiverId == liveData.value.hostId) &&
            ((favId != null && c.giftId == favId) ||
                (favName != null &&
                    c.gift?.displayName.toLowerCase() == favName.toLowerCase())))
        .length;
  }

  int _lastAchievedDiamondTarget = 0;
  int _lastAchievedFavGiftTarget = 0;
  bool _isTargetDialogShowing = false;

  void checkTargets() {
    if (!isHost) return;

    // 1. Check Diamond Target
    final currentCoins = (hostUserState?.totalCoin ?? 0).toInt();
    final diamondTarget = targetDiamonds.value;
    if (diamondTarget > 0 &&
        currentCoins >= diamondTarget &&
        _lastAchievedDiamondTarget != diamondTarget) {
      _lastAchievedDiamondTarget = diamondTarget;
      _showDiamondTargetAchieved(currentCoins, diamondTarget);
      return;
    }

    // 2. Check Favorite Gift Target
    final favCount = favouriteGiftReceivedCount;
    final favTarget = favouriteGiftTarget.value;
    if (favTarget > 0 &&
        favCount >= favTarget &&
        _lastAchievedFavGiftTarget != favTarget) {
      _lastAchievedFavGiftTarget = favTarget;
      _showFavGiftTargetAchieved(favCount, favTarget);
    }
  }

  void _showDiamondTargetAchieved(int currentCoins, int diamondTarget) {
    if (_isTargetDialogShowing) return;
    _isTargetDialogShowing = true;
    TargetAchievedDialog.show(
      isDiamond: true,
      targetValue: diamondTarget,
      currentValue: currentCoins,
      onIncreaseTarget: () {
        _isTargetDialogShowing = false;
        final ctx = Get.context;
        if (ctx != null) {
          SetLiveTargetSheet.show(
            ctx,
            initialValue: diamondTarget + 50,
            onTargetSet: (val) {
              setTargetDiamonds(val);
            },
          );
        }
      },
      onOkay: () {
        _isTargetDialogShowing = false;
      },
    );
  }

  void _showFavGiftTargetAchieved(int favCount, int favTarget) {
    if (_isTargetDialogShowing) return;
    _isTargetDialogShowing = true;
    final gift = featuredGift;
    TargetAchievedDialog.show(
      isDiamond: false,
      targetValue: favTarget,
      currentValue: favCount,
      gift: gift,
      onIncreaseTarget: () {
        _isTargetDialogShowing = false;
        final ctx = Get.context;
        if (ctx != null) {
          SetFavoriteGiftTargetSheet.show(
            ctx,
            gift: gift,
            currentTarget: favTarget,
            currentCount: favCount,
            onTargetSet: (newTarget) {
              setFavouriteGiftTarget(newTarget);
            },
            onChangeGift: () {
              showFavouriteGiftSheet(ctx);
            },
          );
        }
      },
      onOkay: () {
        _isTargetDialogShowing = false;
      },
    );
  }

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
  /// Featured gift: host's favourite gift if set, else highest-priced catalog gift.
  Gift? get featuredGift {
    if (liveData.value.favouriteGiftId != null && gifts.isNotEmpty) {
      final fav = gifts.firstWhereOrNull((g) => g.id == liveData.value.favouriteGiftId);
      if (fav != null) return fav;
    }
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

  // Incoming join request notification & toast (matches Audio Call)
  final AudioPlayer _requestAlertPlayer = AudioPlayer();
  final Rx<AppUser?> latestRequestUser = Rx<AppUser?>(null);
  final RxBool showRequestToast = false.obs;
  Timer? _requestToastTimer;
  Set<int> _seenRequestUserIds = {};
  bool _initialUsersStateLoaded = false;
  int _lastNotifiedUserId = -1;
  int _lastNotifiedTime = 0;

  Future<void> _handleIncomingRequest(int userId) async {
    if (!isHost) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastNotifiedUserId == userId && now - _lastNotifiedTime < 3000) {
      return;
    }
    _lastNotifiedUserId = userId;
    _lastNotifiedTime = now;

    // 1. Play alert sound (matches Audio Call alert notification)
    try {
      await _requestAlertPlayer.stop();
      await _requestAlertPlayer.setAsset(AssetRes.chatNotification);
      await _requestAlertPlayer.play();
    } catch (_) {
      try {
        await _requestAlertPlayer.setAsset('assets/audios/ring audio.mp3');
        await _requestAlertPlayer.play();
      } catch (_) {}
    }
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    } catch (_) {}

    // 2. Resolve requesting user details for toast notification
    AppUser? user = firestoreController.users
        .firstWhereOrNull((p) => p.userId == userId);
    if (user == null || user.fullname == null || user.fullname!.isEmpty) {
      try {
        final doc =
            await db.collection(FirebaseConst.users).doc(userId.toString()).get();
        if (doc.exists) {
          final data = doc.data();
          user = AppUser(
            userId: userId,
            fullname: data?['fullname'] ?? data?['name'] ?? 'User $userId',
            username: data?['username'],
            profile: data?['profile_photo'] ?? data?['photo'],
          );
        }
      } catch (_) {}
    }

    latestRequestUser.value =
        user ?? AppUser(userId: userId, fullname: 'User $userId');
    showRequestToast.value = true;
    _requestToastTimer?.cancel();
    _requestToastTimer = Timer(const Duration(seconds: 6), () {
      showRequestToast.value = false;
    });
  }

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
      startListenEvent();
      loginRoom();
      initAudioPlayer();
    }

    // Common listeners for all users
    pinnedComment.value = liveData.value.pinnedComment ?? '';
    listenLiveStreamData();
    listenUserState();
    fetchLiveStreamComments();
    listenEntryEffects();
    listenGifts();
    liveUsersStates.listen((_) => checkTargets());
    comments.listen((_) => checkTargets());
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
  final RxBool isGiftAnimating = false.obs;
  RxList<GiftEffect> activeGifts = <GiftEffect>[].obs;

  int _roomEnteredAt = 0;

  void listenGifts() {
    print("🔥 Gift LISTENER STARTED");
    _roomEnteredAt = DateTime.now().millisecondsSinceEpoch - 2000;
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
          change.doc.reference.delete();

          // If the gift was sent before this user entered the live stream, skip it
          if (gift.timestamp < _roomEnteredAt) {
            print("⏳ Skipping old gift sent before entering: ${gift.giftName}");
            continue;
          }

          print("📥 New Gift: ${gift.username} sent ${gift.giftName}");
          giftQueue.add(gift);
          processGiftQueue();
        }
      }
    });
  }

  void processGiftQueue() async {
    if (activeGifts.isNotEmpty) return;
    if (giftQueue.isEmpty) {
      isGiftAnimating.value = false;
      return;
    }

    isGiftAnimating.value = true;
    GiftEffect gift = giftQueue.removeAt(0);
    print("🎬 Showing gift: ${gift.username} sent ${gift.giftName}");
    activeGifts.add(gift);

    // Audio is handled by GiftEffectWidget to avoid duplicate audio triggers

    try {
      int waited = 0;
      while (activeGifts.contains(gift) && waited < 4500) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
    } finally {
      activeGifts.remove(gift);
      GiftAudioPlayer.stop();
      print("✅ Finished gift: ${gift.username} sent ${gift.giftName}");
      if (giftQueue.isNotEmpty) {
        processGiftQueue();
      } else {
        isGiftAnimating.value = false;
      }
    }
  }

  Future<void> sendGift(AppUser user, String giftName, String assetUrl, String audioPath, {int? giftId, int? coinPrice, String? thumbnailUrl}) async {
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
      "thumbnail_url": thumbnailUrl ?? '',
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
    if (isHost) {
      showSnackBar('Hosts cannot send gifts');
      return;
    }
    selectedBattleSide.value = side;
    isBattleGiftBarOpen.value = true;
    fetchDiamondBalanceIfNeeded();
  }

  Future<void> sendBattleGiftDirect(Gift gift, AppUser targetUser) async {
    if (isGiftAnimating.value || activeGifts.isNotEmpty) {
      return;
    }
    if (liveData.value.type == LivestreamType.battle &&
        liveData.value.battleType == BattleType.end) {
      showSnackBar('This PK round has ended');
      return;
    }
    final effectiveTarget = effectiveSelectedBattleHost ?? targetUser;
    final giftId = gift.id?.toInt();
    final coinPrice = gift.coinPrice?.toInt() ?? 0;
    final receiverId = effectiveTarget.userId;
    if (isHost || receiverId == myUserId) {
      showSnackBar('You cannot send gifts to yourself');
      return;
    }
    if (receiverId == null || coinPrice <= 0) {
      return Loggers.error(
          'Invalid battle gift: giftId=$giftId receiver=$receiverId price=$coinPrice');
    }

    isGiftAnimating.value = true;

    int effectiveGiftId = (giftId != null && giftId > 0) ? giftId : -1;
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
      isGiftAnimating.value = false;
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
    final sound = gift.effectiveSoundUrl.isNotEmpty
        ? gift.effectiveSoundUrl
        : (gift.soundUrl != null && gift.soundUrl!.trim().isNotEmpty
            ? gift.soundUrl!.trim().addBaseURL()
            : 'assets/images/fairy-sparkle.mp3');
    GiftAudioPlayer.play(sound);
    sendGift(
        effectiveTarget,
        gift.displayName,
        gift.effectiveAssetUrl.addBaseURL(),
        sound,
        giftId: gift.id,
        coinPrice: gift.coinPrice,
        thumbnailUrl: gift.image?.addBaseURL());
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
    _dummyChatTimer?.cancel();
    _dummyLikeTimer?.cancel();

    // Immediately silence and dispose video player
    try {
      videoPlayerController.value?.setVolume(0.0);
      videoPlayerController.value?.pause();
      videoPlayerController.value?.dispose();
      videoPlayerController.value = null;
    } catch (_) {}

    liveStreamUserStatesListener?.cancel();
    liveStreamCommentsListener?.cancel();
    liveStreamDocListener?.cancel();
    try {
      _requestToastTimer?.cancel();
      _requestAlertPlayer.stop();
      _requestAlertPlayer.dispose();
      countdownPlayer.stop();
      countdownPlayer.dispose();
      winAudioPlayer.stop();
      winAudioPlayer.dispose();
      battleStartPlayer.stop();
      battleStartPlayer.dispose();
    } catch (_) {}
    stopListenEvent();
    logoutRoom();
    if (isHost) {
      deleteStreamOnFirebase();
    }
  }

  Future<void> initVideoPlayer() async {
    final rawUrl = liveData.value.dummyUserLink ?? '';
    if (rawUrl.isEmpty) {
      Loggers.warning('initVideoPlayer: dummyUserLink is empty');
      _startDummyInteraction();
      return;
    }

    final url = rawUrl.addBaseURL();
    Loggers.info('initVideoPlayer: loading video from $url (raw: $rawUrl)');

    // Dispose old controller if exists to avoid memory leak
    try {
      await videoPlayerController.value?.dispose();
    } catch (_) {}
    videoPlayerController.value = null;

    VideoPlayerController controller;
    if (url.startsWith('assets/')) {
      controller = VideoPlayerController.asset(url);
    } else {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        Loggers.error('initVideoPlayer: invalid URI: $url');
        _startDummyInteraction();
        return;
      }
      controller = VideoPlayerController.networkUrl(uri);
    }

    isPlayerMute.value = false;

    try {
      await controller.initialize();
      controller
        ..setLooping(true)
        ..play();

      videoPlayerController.value = controller;
      videoPlayerController.value?.setLooping(true);
    } catch (e) {
      Loggers.error('initVideoPlayer error: $e');
      // Graceful fallback: do NOT pop raw ExoPlayer crash snackbar to end user
    }

    _startDummyInteraction();
  }

  void _startDummyInteraction() {
    _dummyChatTimer?.cancel();
    _dummyLikeTimer?.cancel();

    // Realistic initial watching count
    if ((liveData.value.watchingCount ?? 0) <= 0) {
      liveData.value.watchingCount = 22 + Random().nextInt(16);
      liveData.refresh();
    }

    // Seed welcoming classroom chat if comments are currently empty
    if (comments.isEmpty) {
      final initialSeed = [
        LivestreamComment(
          id: DateTime.now().millisecondsSinceEpoch - 12000,
          senderId: -101,
          comment: 'Hello everyone! Excited for today’s session 📚',
          commentType: LivestreamCommentType.text,
        )..senderUserRx.value = AppUser(
            userId: -101,
            username: 'sarah_m',
            fullname: 'Sarah Miller',
            profile: 'assets/images/profile-1.jpg',
            level: 2,
          ),
        LivestreamComment(
          id: DateTime.now().millisecondsSinceEpoch - 6000,
          senderId: -102,
          comment: 'Great stream! Greetings to the host 🍁',
          commentType: LivestreamCommentType.text,
        )..senderUserRx.value = AppUser(
            userId: -102,
            username: 'alex_geo',
            fullname: 'Alexandre Roy',
            profile: 'assets/images/profile-2.jpg',
            level: 4,
          ),
      ];
      comments.assignAll(initialSeed);
    }

    final dummyPool = [
      {'user': 'david_k', 'name': 'David Kim', 'text': 'Very clear explanation, thank you! 👍', 'avatar': 'assets/images/profile-3.jpg', 'level': 3},
      {'user': 'elena_v', 'name': 'Elena Vance', 'text': 'Taking detailed notes 📝', 'avatar': 'assets/images/profile-4.jpg', 'level': 5},
      {'user': 'lucas_b', 'name': 'Lucas Brown', 'text': 'Love this lesson! Super helpful ✨', 'avatar': 'assets/images/profile-5.jpg', 'level': 1},
      {'user': 'sophia_l', 'name': 'Sophia Liu', 'text': 'Can you explain the previous point again?', 'avatar': 'assets/images/profile-6.jpg', 'level': 2},
      {'user': 'marcus_w', 'name': 'Marcus Wright', 'text': 'Following now! Great stream 👏', 'avatar': 'assets/images/profile-7.jpg', 'level': 6},
    ];

    int dummyIndex = 0;
    _dummyChatTimer = Timer.periodic(const Duration(seconds: 8), (t) {
      if (isClosed || liveData.value.isDummyLive != 1) {
        t.cancel();
        return;
      }
      final item = dummyPool[dummyIndex % dummyPool.length];
      dummyIndex++;

      final newComment = LivestreamComment(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: -200 - dummyIndex,
        comment: item['text'] as String,
        commentType: LivestreamCommentType.text,
      )..senderUserRx.value = AppUser(
          userId: -200 - dummyIndex,
          username: item['user'] as String,
          fullname: item['name'] as String,
          profile: item['avatar'] as String,
          level: item['level'] as int,
        );

      comments.insert(0, newComment);
      if (comments.length > 50) comments.removeLast();
      comments.refresh();

      // Fluctuate viewer count naturally
      final delta = Random().nextBool() ? 1 : -1;
      final currentViewers = liveData.value.watchingCount ?? 22;
      liveData.value.watchingCount = (currentViewers + delta).clamp(15, 99);
      liveData.refresh();
    });

    _dummyLikeTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (isClosed || liveData.value.isDummyLive != 1) {
        t.cancel();
        return;
      }
      if (Random().nextDouble() < 0.60) {
        onLikeTap?.call();
        liveData.value.likeCount = (liveData.value.likeCount ?? 0) + 1;
        liveData.refresh();
      }
    });
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

    // Stop and destroy all remote stream views to guarantee audio cutoff
    for (var stream in List<StreamView>.from(streamViews)) {
      try {
        ZegoExpressEngine.instance.stopPlayingStream(stream.streamId);
        if (stream.streamViewId != -1) {
          ZegoExpressEngine.instance.destroyCanvasView(stream.streamViewId);
        }
      } catch (e) {
        Loggers.error('Error stopping stream playback: $e');
      }
    }
    streamViews.clear();

    try {
      ZegoExpressEngine.instance.muteAllPlayStreamAudio(true);
      ZegoExpressEngine.instance.muteAllPlayStreamVideo(true);
    } catch (_) {}

    ZegoExpressEngine.instance.logoutRoom(liveData.value.roomID ?? '');
  }

  Future<ZegoRoomLoginResult> loginRoom() async {
    final roomID = liveData.value.roomID ?? '';
    final user = ZegoUser('$myUserId', myUser.value?.username ?? '');

    final roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;

    try {
      // Ensure playback audio is unmuted when joining room
      try {
        ZegoExpressEngine.instance.muteAllPlayStreamAudio(false);
        ZegoExpressEngine.instance.muteAllPlayStreamVideo(false);
      } catch (_) {}

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

      // If streams are already active or announced, onRoomStreamUpdate plays them.
      // As a safety fallback for audience, if no stream view is playing after a brief delay,
      // trigger playback for host stream.
      final hostStreamId = liveData.value.roomID ?? '';
      if (hostStreamId.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          final alreadyPlaying = streamViews.any((s) =>
              s.streamId == hostStreamId ||
              s.streamId == liveData.value.hostId.toString());
          if (!alreadyPlaying) {
            Loggers.info('Fallback starting host stream playback: $hostStreamId');
            startPlayStream(hostStreamId);
          }
        });
      }

      // For Audience user tracking
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
          sendEntryEffect(myUser.appUser);
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
          if (myUser != null) {
            sendEntryEffect(myUser.appUser);
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
                updateLiveStreamData(watchingCount: -1);
              }
              int? coHostId = int.tryParse(element.userID);
              if (coHostId != null &&
                  coHostId != myUserId &&
                  coHostId != stream.hostId) {
                bool isCoHostExist =
                    stream.coHostIds?.contains(coHostId) ?? false;
                if (isCoHostExist) {
                  closeCoHostStream(coHostId);
                }
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
            // Never play our own stream locally from remote (already in local preview)
            if (stream.streamID == myUserId.toString()) {
              continue;
            }
            // Host never plays their own host stream (already in local host preview)
            if (isHost &&
                (stream.streamID == liveData.value.roomID ||
                    stream.streamID == liveData.value.hostId.toString())) {
              continue;
            }
            // If already playing this stream, don't duplicate
            if (streamViews.any((s) => s.streamId == stream.streamID)) {
              continue;
            }
            startPlayStream(stream.streamID);
          }
          break;
        case ZegoUpdateType.Delete:
          for (final stream in streamList) {
            if (liveData.value.roomID == stream.streamID ||
                liveData.value.hostId.toString() == stream.streamID) {
              if (!isHost) {
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
              continue;
            }
            // Host should never remove their own preview or stop own stream
            if (isHost &&
                (stream.streamID == liveData.value.roomID ||
                    stream.streamID == liveData.value.hostId.toString() ||
                    stream.streamID == myUserId.toString())) {
              continue;
            }
            streamViews.removeWhere((element) => element.streamId == stream.streamID);
            streamViews.refresh();
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
      debugPrint(
          'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
      if (state == ZegoPublisherState.NoPublish && errorCode != 0) {
        Loggers.error('Publisher error $errorCode for stream: $streamID');
      }
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

    // Ensure camera, mic, and hardware capture devices are enabled and unmuted
    await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
    await ZegoExpressEngine.instance.enableCamera(true);
    await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
    await ZegoExpressEngine.instance.mutePublishStreamVideo(false);
    ZegoExpressEngine.instance.muteMicrophone(false);
    await ZegoExpressEngine.instance.setCaptureVolume(100);

    // Create a fresh dedicated preview canvas for the host on this screen
    int canvasViewID = -1;
    Widget? activePreviewWidget;
    try {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        canvasViewID = viewID;
        ZegoCanvas previewCanvas =
            ZegoCanvas(canvasViewID, viewMode: ZegoViewMode.AspectFill);
        ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
      }).then((canvasViewWidget) {
        activePreviewWidget = canvasViewWidget;
      });
    } catch (e) {
      Loggers.error('createCanvasView on host screen error: $e');
    }

    final previewToUse = activePreviewWidget ?? hostPreview;
    if (previewToUse == null) {
      deleteStreamOnFirebase();
      Get.back();
      return;
    }

    // Host must always be at index 0 of streamViews
    streamViews.removeWhere((element) => element.streamId == streamID);
    streamViews.insert(
      0,
      StreamView(
        streamID,
        canvasViewID != -1 ? canvasViewID : (liveData.value.hostViewID ?? -1),
        previewToUse,
        false,
      ),
    );
    streamViews.refresh();

    startMinViewerTimeoutCheck(); // Check time to Min. Viewers Required to continue live
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
      }).then((canvasViewWidget) async {
        if (canvasViewWidget != null) {
          final isHostStream = streamID == liveData.value.roomID ||
              streamID == liveData.value.hostId.toString();
          streamViews.removeWhere((s) => s.streamId == streamID);
          if (isHostStream) {
            streamViews.insert(0, StreamView(streamID, streamViewId, canvasViewWidget, false));
          } else {
            streamViews.add(StreamView(streamID, streamViewId, canvasViewWidget, false));
          }
          streamViews.refresh();
        }
        try {
          await ZegoExpressEngine.instance.muteAllPlayStreamAudio(false);
          await ZegoExpressEngine.instance.mutePlayStreamAudio(streamID, false);
          await ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, false);
          await ZegoExpressEngine.instance.setPlayVolume(streamID, 100);
          await ZegoExpressEngine.instance.setAllPlayStreamVolume(100);
          await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
        } catch (_) {}
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

  void removeFavouriteGift() {
    liveStreamDocRef.update({
      FirebaseConst.favouriteGiftId: FieldValue.delete(),
    });
  }

  void showFavouriteGiftSheet(BuildContext context) {
    final availableGifts = setting?.allGiftsWithPen.isNotEmpty == true
        ? setting!.allGiftsWithPen
        : (setting?.gifts ?? []);

    FavouriteGiftSheet.show(
      context: context,
      currentFavGiftId: liveData.value.favouriteGiftId,
      availableGifts: availableGifts,
      onSetGift: (gift) => setFavouriteGift(gift),
      onRemoveGift: () => removeFavouriteGift(),
    );
  }

  void handleRequestResponse({
    required AppUser? user,
    required bool isRefused,
    LivestreamComment? comment,
  }) {
    final userId = user?.userId;
    if (userId == null) return;

    if (!isRefused && coHostList.length >= maxCallSeats) {
      showSnackBar('Join Call seats are full ($maxCallSeats seats max)');
      return;
    }

    // Update user state based on refusal
    updateUserStateToFirestore(userId,
        type: isRefused
            ? LivestreamUserType.audience
            : LivestreamUserType.coHost,
        audioStatus: isRefused ? VideoAudioStatus.offByMe : VideoAudioStatus.on,
        videoStatus: isRefused ? VideoAudioStatus.offByMe : VideoAudioStatus.on);

    // Update coHostIds in Firestore so all room listeners sync immediately
    updateLiveStreamData(
      coHostId: isRefused
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    );

    // Immediately update local coHostIds for zero-latency UI reaction
    final currentList = List<int>.from(liveData.value.coHostIds ?? []);
    if (isRefused) {
      currentList.remove(userId);
    } else {
      if (!currentList.contains(userId)) {
        currentList.add(userId);
      }
    }
    liveData.value.coHostIds = currentList;
    liveData.refresh();

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

    // 1. Immediately mark inactive and delete the main live stream document(s) directly
    // This MUST be done first and without waiting on subcollections or batches, so Firestore
    // listeners remove the live stream card from the feed in real-time.
    try {
      await db.collection(FirebaseConst.liveStreams).doc(roomId).update({'is_active': false});
    } catch (_) {}
    try {
      await db.collection(FirebaseConst.liveStreams).doc(roomId).delete();
      Loggers.success('Main live stream document $roomId deleted from Firestore.');
    } catch (e) {
      Loggers.error('Failed to delete live stream doc $roomId: $e');
    }

    // Also delete by host userId if different from roomId
    if ('$myUserId' != roomId) {
      try {
        await db.collection(FirebaseConst.liveStreams).doc('$myUserId').update({'is_active': false});
      } catch (_) {}
      try {
        await db.collection(FirebaseConst.liveStreams).doc('$myUserId').delete();
      } catch (_) {}
    }

    // 2. Best-effort subcollection cleanup in the background
    _cleanupSubcollectionsInBackground(roomId);
  }

  void _cleanupSubcollectionsInBackground(String roomId) async {
    try {
      final usersSnapshot = await liveStreamUserStatesRef.get();
      for (var doc in usersSnapshot.docs) {
        doc.reference.delete().catchError((_) {});
      }
    } catch (_) {}

    try {
      final commentsSnapshot = await liveStreamCommentsRef.get();
      for (var doc in commentsSnapshot.docs) {
        doc.reference.delete().catchError((_) {});
      }
    } catch (_) {}
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

        if (stream.battleDuration > 0) {
          selectedBattleDuration.value = stream.battleDuration;
        }

        if (stream.battleType == BattleType.initiate) {
          timer?.cancel();
          remainingBattleSeconds.value =
              Duration(minutes: stream.battleDuration > 0 ? stream.battleDuration : 2).inSeconds;
          countdownPlayer.pause();
          isPkResultPopupShowing = false;
        }

        if (stream.battleType == BattleType.waiting) {
          totalBattleSecond =
              Duration(minutes: stream.battleDuration > 0 ? stream.battleDuration : 2).inSeconds;
          isPkResultPopupShowing = false;
        }

        if (stream.battleType == BattleType.running) {
          totalBattleSecond =
              Duration(minutes: stream.battleDuration > 0 ? stream.battleDuration : 2).inSeconds;
          isPkResultPopupShowing = false;
        }

        if (stream.battleType == BattleType.end && stream.lastRoundResult != null) {
          timer?.cancel();
          countdownPlayer.pause();
          checkAndShowPkResultDialog(stream.lastRoundResult!);
        }

        if (selectedBattleHostId.value == null && stream.hostId != null) {
          selectedBattleHostId.value = stream.hostId;
        }

        // Update LiveData and detect co-host departures
        final currentCoHostIds = Set<int>.from(stream.coHostIds ?? []);
        if (isHost && _initialLiveDocLoaded) {
          final departed = _previousCoHostIds.difference(currentCoHostIds);
          for (final depId in departed) {
            if (depId != myUserId && depId != stream.hostId) {
              closeCoHostStream(depId);
            }
          }
        }
        _previousCoHostIds = currentCoHostIds;
        _initialLiveDocLoaded = true;

        // Ensure remote audio/video playback is active for all connected co-hosts
        for (final cId in currentCoHostIds) {
          if (cId != myUserId && cId != stream.hostId) {
            if (!streamViews.any((s) => s.streamId == '$cId')) {
              startPlayStream('$cId');
            }
          }
        }

        liveData.value = stream;
        if (stream.pinnedComment != null) {
          pinnedComment.value = stream.pinnedComment!;
        }

        // PK Battle state & invitation sync
        pkOpponentId.value = stream.pkOpponentId;
        pkInvitedUserIds.value = List<int>.from(stream.pkInvitedUserIds ?? []);

        if (stream.pkOpponentId != null) {
          pkOpponentUser.value = firestoreController.users
                  .firstWhereOrNull((u) => u.userId == stream.pkOpponentId) ??
              liveUsersStates
                  .firstWhereOrNull((u) => u.userId == stream.pkOpponentId)
                  ?.getUser(firestoreController.users);
        } else {
          pkOpponentUser.value = null;
        }

        // Check if this co-host received a PK invitation from the host
        if (!isHost &&
            pkInvitedUserIds.contains(myUserId) &&
            stream.pkOpponentId == null &&
            stream.type != LivestreamType.battle &&
            stream.battleType != BattleType.waiting &&
            stream.battleType != BattleType.running &&
            !isPkInviteDialogOpen) {
          isPkInviteDialogOpen = true;
          final hostName = stream.hostUser?.fullname ??
              stream.hostUser?.username ??
              'Host';
          onCallParticipantPkInviteReceived?.call(
              stream.hostId ?? 0, hostName);
        }

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
                if (state.userId == liveData.value.hostId && state.user != null) {
                  liveData.value.hostUser = state.user;
                }
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
                if (state.userId == liveData.value.hostId && state.user != null) {
                  liveData.value.hostUser = state.user;
                }
                liveUsersStates.refresh();
                // Loggers.info('🔁 User modified: ${state.userId}');
                break;

              case DocumentChangeType.removed:
                if (state.type == LivestreamUserType.coHost) {
                  if (isHost) {
                    notifyCoHostLeft(state.userId);
                  }
                  closeCoHostStream(state.userId);
                }
                liveUsersStates.removeWhere((u) => u.userId == state.userId);
                // Loggers.info('➖ User removed: ${state.userId}');
                break;
            }
          }
          final newRequestStates = liveUsersStates
              .where((element) => element.type == LivestreamUserType.requested)
              .toList();
          requestList.value = newRequestStates;

          final newRequestUserIds = newRequestStates
              .map((e) => e.userId)
              .whereType<int>()
              .toList();

          if (isHost) {
            if (_initialUsersStateLoaded) {
              final newlyAdded = newRequestUserIds
                  .where((id) => !_seenRequestUserIds.contains(id))
                  .toList();
              if (newlyAdded.isNotEmpty) {
                _handleIncomingRequest(newlyAdded.first);
              }
            }
            _seenRequestUserIds = Set<int>.from(newRequestUserIds);
            _initialUsersStateLoaded = true;
          }

          // "Auto Call" (set when the host went live) auto-accepts co-host
          // requests instead of the host approving each one manually —
          // mirrors AudioRoomController's proven auto-accept pattern.
          if (liveData.value.hostId == myUserId &&
              (liveData.value.isAutoMode ?? false) &&
              requestList.isNotEmpty &&
              coHostList.length < maxCallSeats) {
            final freeSeats = maxCallSeats - coHostList.length;
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
            if (comment.id != null && liveData.value.createdAt != null) {
              final liveCreated = int.tryParse(liveData.value.createdAt?.toString() ?? '') ?? 0;
              if (liveCreated > 0 && comment.id! < liveCreated - 3000) {
                continue;
              }
            }
            firestoreController.fetchUserIfNeeded(comment.senderId ?? -1);
            if (comment.commentType == LivestreamCommentType.request) {
              if (!isHost) {
                continue;
              }
              if (comment.senderId != null) {
                _handleIncomingRequest(comment.senderId!);
              }
            }
            if (!comments.any((c) => c.id == comment.id)) {
              comments.add(comment);
            }
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
      _updateTopGifter();
    });
  }

  void toggleCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera, channel: ZegoPublishChannel.Main);
  }

  RxBool isAudioOn = true.obs;
  RxBool isVideoOn = true.obs;

  void toggleAutoCall(bool value) {
    liveData.value.isAutoMode = value;
    liveData.refresh();
    liveStreamDocRef.update({FirebaseConst.isAutoMode: value}).catchError((e) {
      Loggers.error('Failed to update is_auto_mode on Firestore: $e');
    });
    if (value && requestList.isNotEmpty && coHostList.length < maxCallSeats) {
      final freeSeats = maxCallSeats - coHostList.length;
      for (final state in requestList.take(freeSeats)) {
        handleRequestResponse(
          user: state.getUser(firestoreController.users),
          isRefused: false,
        );
      }
    }
  }

  void toggleFlipCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera, channel: ZegoPublishChannel.Main);
  }

  void toggleMic(LivestreamUserState? state) async {
    state ??= liveUsersStates
        .firstWhereOrNull((element) => element.userId == myUserId);

    if (state?.audioStatus == VideoAudioStatus.offByHost) {
      return showSnackBar(LKey.theHostHasTurnedOffYourAudio);
    }

    bool audioCurrentlyOn = state != null
        ? state.audioStatus == VideoAudioStatus.on
        : isAudioOn.value;

    if (audioCurrentlyOn) {
      isAudioOn.value = false;
      if (state != null) {
        state.audioStatus = VideoAudioStatus.offByMe;
        liveUsersStates.refresh();
      }
      updateUserStateToFirestore(myUserId,
          audioStatus: VideoAudioStatus.offByMe);
      await ZegoExpressEngine.instance.muteMicrophone(true);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(true);
    } else {
      isAudioOn.value = true;
      if (state != null) {
        state.audioStatus = VideoAudioStatus.on;
        liveUsersStates.refresh();
      }
      updateUserStateToFirestore(myUserId, audioStatus: VideoAudioStatus.on);
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
    }
  }

  void toggleVideo(LivestreamUserState? state) async {
    state ??= liveUsersStates
        .firstWhereOrNull((element) => element.userId == myUserId);

    if (state?.videoStatus == VideoAudioStatus.offByHost) {
      return showSnackBar(LKey.theHostHasTurnedOffYourVideo.tr);
    }
    bool videoCurrentlyOn = state != null
        ? state.videoStatus == VideoAudioStatus.on
        : isVideoOn.value;
    Loggers.error(videoCurrentlyOn);
    if (videoCurrentlyOn) {
      isVideoOn.value = false;
      if (state != null) {
        state.videoStatus = VideoAudioStatus.offByMe;
        liveUsersStates.refresh();
      }
      updateUserStateToFirestore(myUserId,
          videoStatus: VideoAudioStatus.offByMe);
      await ZegoExpressEngine.instance.enableCamera(false);
      await ZegoExpressEngine.instance.mutePublishStreamVideo(true);
    } else {
      isVideoOn.value = true;
      if (state != null) {
        state.videoStatus = VideoAudioStatus.on;
        liveUsersStates.refresh();
      }
      updateUserStateToFirestore(myUserId, videoStatus: VideoAudioStatus.on);
      await ZegoExpressEngine.instance.enableCamera(true);
      await ZegoExpressEngine.instance.mutePublishStreamVideo(false);
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

  void onLikeButtonTap() {
    HapticManager.shared.light();
    onLikeTap?.call(); // Instant floating heart reaction!
    final currentLikes = liveData.value.likeCount ?? 0;
    liveData.value.likeCount = currentLikes + 1;
    liveData.refresh();

    // Async sync to Firestore in background
    liveStreamDocRef.get().then((doc) {
      if (doc.exists) {
        liveStreamDocRef.update({FirebaseConst.likeCount: FieldValue.increment(1)});
      } else {
        liveStreamDocRef.set({
          ...liveData.value.toJson(),
          FirebaseConst.likeCount: currentLikes + 1,
        }, SetOptions(merge: true));
      }
    }).catchError((e) {
      Loggers.error('onLikeButtonTap error: $e');
    });
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

  void sendWaveTo(String username) {
    if (username.trim().isEmpty) return;
    _sendCommentToFirestore(
        type: LivestreamCommentType.text,
        comment: '👋 waved at $username');
  }

  Future<void> submitPinnedComment() async {
    final text = pinCommentController.text.trim();
    if (text.isEmpty) return;
    try {
      await liveStreamDocRef.update({'pinned_comment': text});
      pinnedComment.value = text;
      liveData.value.pinnedComment = text;
      liveData.refresh();
      pinCommentController.clear();
      isPinInputOpen.value = false;
    } catch (e) {
      Loggers.error('submitPinnedComment error: $e');
    }
  }

  Future<void> clearPinnedComment() async {
    try {
      await liveStreamDocRef.update({'pinned_comment': ''});
      pinnedComment.value = '';
      liveData.value.pinnedComment = '';
      liveData.refresh();
    } catch (e) {
      Loggers.error('clearPinnedComment error: $e');
    }
  }

  void _updateTopGifter() {
    final giftComments =
        comments.where((c) => c.commentType == LivestreamCommentType.gift);
    if (giftComments.isEmpty) {
      topGifterName.value = '';
      topGifterCoins.value = 0;
      return;
    }
    final Map<int, int> userTotals = {};
    final Map<int, String> userNames = {};
    for (var c in giftComments) {
      final uid = c.senderId ?? 0;
      if (uid <= 0) continue;
      final name = c.senderUser?.username ?? c.senderUser?.fullname;
      if (name != null && name.trim().isNotEmpty) {
        userNames[uid] = name.trim();
      }
      final coins = (c.gift?.coinPrice?.toInt() ?? 0);
      userTotals[uid] = (userTotals[uid] ?? 0) + coins;
    }
    if (userTotals.isNotEmpty) {
      var topEntry =
          userTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final bestName = userNames[topEntry.key] ??
          firestoreController.users
              .firstWhereOrNull((u) => u.userId == topEntry.key)
              ?.username ??
          firestoreController.users
              .firstWhereOrNull((u) => u.userId == topEntry.key)
              ?.fullname ??
          '';
      if (bestName.isNotEmpty) {
        topGifterName.value = bestName;
        topGifterCoins.value = topEntry.value;
      }
    } else {
      topGifterName.value = '';
      topGifterCoins.value = 0;
    }
  }

  AppUser? get effectiveHostUser {
    if (liveData.value.hostUser != null) {
      return liveData.value.hostUser;
    }

    final hostId = liveData.value.hostId ??
        int.tryParse(liveData.value.roomID ?? '');

    // 1. From hostUserState
    final stateUser = hostUserState?.user ??
        (hostId != null
            ? liveUsersStates.firstWhereOrNull((s) => s.userId == hostId)?.user
            : null);
    if (stateUser != null) {
      liveData.value.hostUser = stateUser;
      return stateUser;
    }

    // 2. From firestoreController.users
    if (hostId != null) {
      final user = firestoreController.users
          .firstWhereOrNull((u) => u.userId == hostId);
      if (user != null) {
        liveData.value.hostUser = user;
        return user;
      }
    }



    // 4. Construct fallback with hostId
    if (hostId != null && hostId > 0) {
      final fallback = AppUser(
        userId: hostId,
        username: hostUserState?.user?.username ?? 'Host',
        fullname: hostUserState?.user?.fullname ?? 'Host',
        profile: hostUserState?.user?.profile,
      );
      liveData.value.hostUser = fallback;
      return fallback;
    }

    return null;
  }

  Future<void> sendGiftDirect(Gift gift) async {
    if (isHost) {
      showSnackBar('Hosts cannot send gifts to themselves');
      return;
    }
    AppUser? hostUser = effectiveHostUser;
    if (hostUser == null) {
      final hostId = liveData.value.hostId ??
          int.tryParse(liveData.value.roomID ?? '');
      if (hostId != null && hostId > 0) {
        hostUser = AppUser(
          userId: hostId,
          username: 'Host',
          fullname: 'Host',
        );
        liveData.value.hostUser = hostUser;
      }
    }

    if (hostUser == null) {
      showSnackBar('Host details not found');
      return;
    }
    await sendBattleGiftDirect(gift, hostUser);
  }

  void onGiftTap(GiftType type,
      {BattleView battleViewType = BattleView.red,
      List<AppUser> users = const []}) {
    if (isHost) {
      showSnackBar('Hosts cannot send gifts to themselves');
      return;
    }
    final targetUsers = List<AppUser>.from(users);
    targetUsers.removeWhere((element) => element.userId == myUserId);
    if (liveData.value.type == LivestreamType.battle &&
        liveData.value.battleType == BattleType.end) {
      return showSnackBar(LKey.battleEndedGiftNotSent.tr);
    }

    final effectiveTargetId = selectedBattleHostId.value ?? liveData.value.hostId ?? effectiveHostUser?.userId;
    final effectiveStreamUsers = targetUsers.isNotEmpty
        ? targetUsers
        : (effectiveSelectedBattleHost != null
            ? [effectiveSelectedBattleHost!]
            : (effectiveHostUser != null ? [effectiveHostUser!] : <AppUser>[]));

    GiftManager.openGiftSheet(
        userId: effectiveTargetId,
        giftType: type,
        battleViewType: battleViewType,
        streamUsers: effectiveStreamUsers,
        source: 'video_gift',
        onCompletion: (giftManager) {
          Gift gift = giftManager.gift;
          AppUser? user = giftManager.streamUser;

          int coinPrice = gift.coinPrice?.toInt() ?? 0;
          final targetUserId = user?.userId ?? effectiveTargetId;

          _sendCommentToFirestore(
              type: LivestreamCommentType.gift,
              giftId: gift.id,
              receiverId: targetUserId);
          updateUserStateToFirestore(
            targetUserId,
            battleCoin: type == GiftType.battle ? coinPrice : null,
            currentBattleCoin: type == GiftType.battle ? coinPrice : null,
            liveCoin: type == GiftType.livestream ? coinPrice : null,
          );

          AppUser effectiveUser = user ??
              effectiveHostUser ??
              AppUser(
                userId: liveData.value.hostId ?? 0,
                username: 'Host',
                fullname: 'Host',
              );

          final sound = gift.effectiveSoundUrl.isNotEmpty
              ? gift.effectiveSoundUrl
              : (gift.soundUrl != null && gift.soundUrl!.trim().isNotEmpty
                  ? gift.soundUrl!.trim().addBaseURL()
                  : 'assets/images/fairy-sparkle.mp3');

          // Instantly play audio for sender with 0ms delay!
          GiftAudioPlayer.play(sound);

          sendGift(
            effectiveUser,
            gift.displayName,
            gift.effectiveAssetUrl.addBaseURL(),
            sound,
            giftId: gift.id,
            coinPrice: coinPrice,
            thumbnailUrl: gift.image?.addBaseURL(),
          );

        });
  }

  _sendCommentToFirestore({
    required LivestreamCommentType type,
    String? comment,
    int? giftId,
    int? receiverId,
    int? senderId,
    AppUser? senderUser,
  }) async {
    // Host can NEVER leave their own live broadcast!
    if (type == LivestreamCommentType.leftCoHost) {
      final targetSenderId = senderId ?? myUserId;
      if (targetSenderId == liveData.value.hostId || (isHost && targetSenderId == myUserId)) {
        Loggers.warning('Blocked posting leftCoHost comment for host ($targetSenderId)');
        return;
      }
    }

    int time = DateTime.now().millisecondsSinceEpoch;
    final effectiveSenderId = senderId ?? myUserId;

    // 1. Immediately create comment model
    final newComment = LivestreamComment(
      comment: comment,
      commentType: type,
      id: time,
      senderId: effectiveSenderId,
      receiverId: receiverId,
      giftId: giftId,
    );

    // Bind sender user immediately so avatar, username & level render without delay
    final currentUser = SessionManager.instance.getUser();
    newComment.senderUserRx.value = senderUser ??
        (effectiveSenderId == myUserId
            ? (myUser.value?.appUser ??
                (currentUser != null
                    ? AppUser(
                        userId: myUserId,
                        username: currentUser.username ?? 'You',
                        fullname: currentUser.fullname ?? 'You',
                        profile: currentUser.profilePhoto,
                        level: SessionManager.instance.myUserLevel.value,
                        isVerify: currentUser.isVerify,
                      )
                    : null))
            : firestoreController.users
                .firstWhereOrNull((u) => u.userId == effectiveSenderId));

    if (giftId != null) {
      newComment.gift = gifts.firstWhereOrNull((g) => g.id == giftId);
    }

    // 2. Insert into local comments list immediately
    if (!comments.any((c) => c.id == time)) {
      comments.insert(0, newComment);
      comments.refresh();
    }

    // 3. Persist to Firestore and API asynchronously
    try {
      _addUsersFirebaseFireStore().catchError((e) {
        Loggers.error('addUsersFirebaseFireStore error: $e');
      });

      await liveStreamCommentsRef.doc('$time').set(newComment.toJson());

      bool saved = await _saveCommentToApi(
        commentType: type,
        comment: comment,
        giftId: giftId,
        receiverId: receiverId,
      );
      if (saved) {
        SessionManager.instance.refreshUser();
      } else if (type == LivestreamCommentType.gift) {
        await Future.delayed(const Duration(milliseconds: 800));
        bool retrySaved = await _saveCommentToApi(
          commentType: type,
          comment: comment,
          giftId: giftId,
          receiverId: receiverId,
        );
        if (retrySaved) {
          SessionManager.instance.refreshUser();
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
    if (coHostList.length >= maxCallSeats) {
      showSnackBar('Join Call seats are full ($maxCallSeats seats max)');
      return;
    }
    LivestreamUserState? state = liveUsersStates
        .firstWhereOrNull((element) => element.userId == myUserId);
    switch (state?.type) {
      case null:
      case LivestreamUserType.audience:
        updateUserStateToFirestore(myUserId,
            type: LivestreamUserType.requested);
        _sendCommentToFirestore(
            type: LivestreamCommentType.request,
            comment: '📹 requested to Join Call',
            receiverId: liveData.hostId);
        if (Get.context != null) {
          CallRequestedSheet.show(Get.context!);
        } else {
          showSnackBar(LKey.requestJoinToHost.tr);
        }
        break;
      case LivestreamUserType.requested:
        if (Get.context != null) {
          CallRequestedSheet.show(Get.context!);
        } else {
          showSnackBar(LKey.joinRequestSentDescription.tr);
        }
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
      await reference.set(updateData, SetOptions(merge: true));
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
                      isAudioOn.value = true;
                      isVideoOn.value = true;
                      updateUserStateToFirestore(myUserId,
                          type: LivestreamUserType.coHost,
                          audioStatus: VideoAudioStatus.on,
                          videoStatus: VideoAudioStatus.on);
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
      await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
      await ZegoExpressEngine.instance.enableCamera(true);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
      ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.setCaptureVolume(100);

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
          streamViews.refresh();
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
      isAudioOn.value = true;
      isVideoOn.value = true;
      updateUserStateToFirestore(myUserId,
          audioStatus: VideoAudioStatus.on,
          videoStatus: VideoAudioStatus.on,
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
    if (streamId == null || streamId == liveData.value.hostId) return;

    if (streamId == myUserId) {
      if (isHost) {
        // Host must NEVER end their own live broadcast from closeCoHostStream
        return;
      }
      hasDismissedJoinCallBanner.value = false;
      StreamView? view = streamViews
          .firstWhereOrNull((element) => element.streamId == '$streamId');
      if (view != null) {
        stopPreview(viewId: view.streamViewId);
      }
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
      _sendCommentToFirestore(
        type: LivestreamCommentType.leftCoHost,
        comment: 'Left the call',
        senderId: myUserId,
        senderUser: myUser.value?.appUser,
      );
      streamViews.removeWhere((element) => element.streamId == '$streamId');
      streamViews.refresh();
      // The participant was kicked or left: revert to audience without closing room
    } else {
      stopPlayStream(streamId.toString());
      streamViews.removeWhere((element) => element.streamId == '$streamId');
      streamViews.refresh();
      if (isHost) {
        isMinViewerTimeout.value = false;
        bool isBattleOn = liveData.value.type == LivestreamType.battle;
        updateLiveStreamData(
          coHostId: FieldValue.arrayRemove([streamId]),
          type: isBattleOn ? LivestreamType.livestream : null,
          battleType: isBattleOn ? BattleType.initiate : null,
        );
        liveStreamDocRef.update({
          'pk_invited_user_ids': FieldValue.arrayRemove([streamId]),
          if (liveData.value.pkOpponentId == streamId) 'pk_opponent_id': null,
        }).catchError((_) {});
        updateUserStateToFirestore(streamId,
            type: LivestreamUserType.audience,
            audioStatus: VideoAudioStatus.offByMe,
            videoStatus: VideoAudioStatus.offByMe,
            battleCoin: 0,
            currentBattleCoin: 0);
        notifyCoHostLeft(streamId);
      }
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
      LivestreamUserState? oldState, LivestreamUserState newState) async {
    if (newState.userId == myUserId) {
      Loggers.info('Updating state for userId: ${newState.toJson()}');
      if (newState.type == LivestreamUserType.coHost &&
          oldState?.type != LivestreamUserType.coHost) {
        hasDismissedJoinCallBanner.value = false;
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
          (newState.type == LivestreamUserType.audience ||
              newState.type == LivestreamUserType.left)) {
        if (isHost) {
          notifyCoHostLeft(newState.userId);
        }
        closeCoHostStream(newState.userId);
      }

      // Handle host muting / unmuting this user
      if (newState.audioStatus == VideoAudioStatus.offByHost &&
          oldState?.audioStatus != VideoAudioStatus.offByHost) {
        isAudioOn.value = false;
        await ZegoExpressEngine.instance.muteMicrophone(true);
        await ZegoExpressEngine.instance.mutePublishStreamAudio(true);
        showSnackBar(LKey.theHostHasTurnedOffYourAudio.tr);
      } else if (newState.audioStatus == VideoAudioStatus.on &&
          oldState?.audioStatus == VideoAudioStatus.offByHost) {
        isAudioOn.value = true;
        await ZegoExpressEngine.instance.muteMicrophone(false);
        await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
        showSnackBar('Host unmuted your microphone');
      }

      // Handle host disabling / enabling this user's video
      if (newState.videoStatus == VideoAudioStatus.offByHost &&
          oldState?.videoStatus != VideoAudioStatus.offByHost) {
        isVideoOn.value = false;
        await ZegoExpressEngine.instance.enableCamera(false);
        await ZegoExpressEngine.instance.mutePublishStreamVideo(true);
        showSnackBar(LKey.theHostHasTurnedOffYourVideo.tr);
      } else if (newState.videoStatus == VideoAudioStatus.on &&
          oldState?.videoStatus == VideoAudioStatus.offByHost) {
        isVideoOn.value = true;
        await ZegoExpressEngine.instance.enableCamera(true);
        await ZegoExpressEngine.instance.mutePublishStreamVideo(false);
        showSnackBar('Host enabled your camera');
      }
    }
  }

  void hostMuteUser(int userId, bool shouldMute) {
    if (!isHost) return;
    updateUserStateToFirestore(
      userId,
      audioStatus: shouldMute ? VideoAudioStatus.offByHost : VideoAudioStatus.on,
    );
  }

  void hostToggleUserVideo(int userId, bool shouldTurnOff) {
    if (!isHost) return;
    updateUserStateToFirestore(
      userId,
      videoStatus: shouldTurnOff ? VideoAudioStatus.offByHost : VideoAudioStatus.on,
    );
  }

  void hostKickUser(int userId) {
    if (!isHost) return;
    if (userId == myUserId || userId == liveData.value.hostId) return;
    closeCoHostStream(userId);
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
    if (isBattleOn) {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E212B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'End Session',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined, color: Colors.orangeAccent),
                  title: const Text('End PK Battle only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Stay live in standard mode', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  onTap: () {
                    Get.back();
                    updateLiveStreamData(
                      battleType: BattleType.initiate,
                      type: LivestreamType.livestream,
                    );
                    liveStreamDocRef.update({
                      'pk_opponent_id': null,
                      'pk_invited_user_ids': [],
                    }).catchError((_) {});
                    startMinViewerTimeoutCheck();
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
                  title: const Text('End Live Stream', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: const Text('End the live stream completely', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  onTap: () {
                    Get.back();
                    hostEndStream();
                  },
                ),
              ],
            ),
          ),
        ),
        isScrollControlled: true,
      );
    } else {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1E212B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorRes.liveRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: ColorRes.liveRed,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'End Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to end this live?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorRes.liveRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                          hostEndStream();
                        },
                        child: const Text(
                          'End Live',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> hostEndStream() async {
    // 0. Snapshot real-time metrics before cleaning up state
    LivestreamUserState? endedUserState = liveUsersStates
        .firstWhereOrNull((element) => element.userId == myUserId);
    int endedViewers = liveUsersStates.length;
    final int liveWatchCount = liveData.value.watchingCount ?? 0;
    final int peakViewers = max(
        liveWatchCount, max(endedViewers, audienceList.length));

    final int joinTimeMs = (endedUserState?.joinStreamTime != null &&
            endedUserState!.joinStreamTime > 0)
        ? endedUserState.joinStreamTime
        : (liveData.value.createdAt ?? DateTime.now().millisecondsSinceEpoch);
    final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(joinTimeMs);
    final int durationMinutes = max(
        1,
        ((DateTime.now().millisecondsSinceEpoch - joinTimeMs) / 60000).ceil());

    final int followersCount = endedUserState?.followersGained.length ?? 0;
    final int viewersCount = peakViewers;
    final int acceptedCallsCount = CallRequestsSheet.sessionHistory
        .where((e) => e['status'] == 'Accepted')
        .length;
    final int callsCount =
        max(acceptedCallsCount, liveData.value.coHostIds?.length ?? 0);
    final int commentsCount = comments.length;
    final int starsEarned = (endedUserState?.totalCoin ??
            (hostUserState?.totalCoin ?? 0))
        .toInt();
    final int giftsCount = hostGiftCount;

    final String streamTitle = (liveData.value.topicName?.isNotEmpty == true)
        ? liveData.value.topicName!
        : ((liveData.value.description?.isNotEmpty == true)
            ? liveData.value.description!
            : 'Party Room');

    final int durationSeconds = max(
        1,
        ((DateTime.now().millisecondsSinceEpoch - joinTimeMs) / 1000).ceil());

    // 1. Clean up Firestore documents immediately so stream disappears from all screens
    await deleteStreamOnFirebase();

    if (Get.isRegistered<LiveStreamSearchScreenController>()) {
      Get.find<LiveStreamSearchScreenController>()
          .removeStreamLocally(liveData.value.roomID, myUserId);
    }

    // 1b. Save completed live session locally so it immediately appears in My Lives & Insights
    try {
      final completedSession = LiveHistory(
        id: apiLiveStreamId ?? DateTime.now().millisecondsSinceEpoch,
        userId: myUserId,
        title: streamTitle,
        thumbnail: liveData.value.thumbnailUrl ?? myUser.value?.profilePhoto,
        viewerCount: viewersCount,
        duration: durationSeconds,
        totalGifts: giftsCount,
        totalComments: commentsCount,
        followersGained: followersCount,
        starsEarned: starsEarned,
        categoryName: liveData.value.categoryName ?? 'Live Stream',
        startedAt: startTime.toIso8601String(),
        endedAt: DateTime.now().toIso8601String(),
        status: 0,
        createdAt: startTime.toIso8601String(),
        hostUsername: myUser.value?.username,
        hostFullname: myUser.value?.fullname,
        hostProfilePhoto: myUser.value?.profilePhoto,
      );
      LiveHistoryStorage.saveLiveSession(completedSession);
    } catch (e) {
      Loggers.error('LiveHistoryStorage save error: $e');
    }

    // 2. Call backend end-stream API
    _endLiveStreamApi(
      duration: durationSeconds,
      viewerCount: viewersCount,
      followersGained: followersCount,
      starsEarned: starsEarned,
      totalComments: commentsCount,
      totalGifts: giftsCount,
    );

    // 3. Stop local recording and upload
    await _stopLocalRecordingAndUpload();

    // 4. Leave Zego room
    logoutRoom();

    // 5. Present real-time summary card dialog matching reference UI
    Get.dialog(
      LiveSummaryDialog(
        title: streamTitle,
        startTime: startTime,
        durationMinutes: durationMinutes,
        followersCount: followersCount,
        viewersCount: viewersCount,
        callsCount: callsCount,
        commentsCount: commentsCount,
        premiumGiftsCount: giftsCount,
        starsEarned: starsEarned,
        endedBy: 'Host',
        onClose: () {
          // Close summary dialog first
          Get.back();
          // Navigate back to root/home
          try {
            Navigator.of(Get.context!, rootNavigator: true)
                .popUntil((route) => route.isFirst);
          } catch (_) {
            try {
              Get.back();
            } catch (_) {}
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _endLiveStreamApi({
    int? duration,
    int? viewerCount,
    int? followersGained,
    int? starsEarned,
    int? totalComments,
    int? totalGifts,
  }) async {
    if (apiLiveStreamId == null) return;
    try {
      await GiftWalletService.instance.endLiveStream(
        liveStreamId: apiLiveStreamId!,
        duration: duration,
        viewerCount: viewerCount,
        followersGained: followersGained,
        starsEarned: starsEarned,
        totalComments: totalComments,
        totalGifts: totalGifts,
      );
      Loggers.success('endLiveStream API called successfully');
    } catch (e) {
      Loggers.error('endLiveStream API error: $e');
    }
  }

  void streamEnded({LivestreamUserState? capturedUserState, int? capturedViewers}) {
    if (isHost) {
      // Host must only end via explicit hostEndStream() to prevent premature termination
      return;
    }
    LivestreamUserState? userState = capturedUserState ??
        liveUsersStates.firstWhereOrNull((element) => element.userId == myUserId);
    AppUser? user = firestoreController.users.firstWhereOrNull((element) => element.userId == myUserId);
    userState?.user = user;
    int viewers = capturedViewers ?? liveUsersStates.length;
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

  togglePlayerAudioToggle() {
    videoPlayerController.value?.setVolume(isPlayerMute.value ? 1 : 0);
    isPlayerMute.value = !isPlayerMute.value;
  }

  void toggleView() {
    isViewVisible.value = !isViewVisible.value;
  }

  /// Host invites an active call participant (co-host) to PK Battle
  Future<void> sendPkInviteToCoHost(int userId, {int? duration}) async {
    if (!isHost) return;
    final isCoHost = coHostList.any(
        (u) => u.userId == userId && u.type == LivestreamUserType.coHost);
    if (!isCoHost || userId == myUserId) {
      showSnackBar('User is not an active video call participant');
      return;
    }
    if (liveData.value.pkOpponentId != null ||
        liveData.value.type == LivestreamType.battle ||
        liveData.value.battleType == BattleType.waiting ||
        liveData.value.battleType == BattleType.running) {
      showSnackBar('PK Battle already started');
      return;
    }
    final effectiveDuration = duration ?? selectedBattleDuration.value;
    selectedBattleDuration.value = effectiveDuration;
    await liveStreamDocRef.update({
      'pk_invited_user_ids': FieldValue.arrayUnion([userId]),
      'battle_duration': effectiveDuration,
    });
  }

  /// Host cancels PK invitation sent to a co-host
  void cancelPkInviteToCoHost(int userId) async {
    if (!isHost) return;
    liveStreamDocRef.update({
      'pk_invited_user_ids': FieldValue.arrayRemove([userId]),
    });
  }

  /// Co-host accepts PK invitation from host
  /// First acceptance wins: locks opponent slot, starts battle, invalidates all other pending invites
  Future<void> acceptPkInviteFromHost(int currentUserId) async {
    isPkInviteDialogOpen = false;

    // 5. Validation before acceptance
    final isCoHost = coHostList.any((u) =>
        u.userId == currentUserId && u.type == LivestreamUserType.coHost);
    if (!isCoHost) {
      showSnackBar('You are no longer an active call participant.');
      return;
    }
    if (liveData.value.pkOpponentId != null ||
        liveData.value.type == LivestreamType.battle ||
        liveData.value.battleType == BattleType.waiting ||
        liveData.value.battleType == BattleType.running) {
      showSnackBar('PK Battle already started.');
      return;
    }

    try {
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(liveStreamDocRef);
        if (!snapshot.exists) {
          throw 'Live stream ended';
        }
        final data = snapshot.data() as Map<String, dynamic>;
        final currentOpponent = data['pk_opponent_id'];
        final currentType = data['type'];
        final currentBattleType = data['battle_type'];

        // Mutex check: opponent slot must be empty and battle not active
        if (currentOpponent != null ||
            currentType == LivestreamType.battle.value ||
            currentBattleType == BattleType.waiting.value ||
            currentBattleType == BattleType.running.value) {
          throw 'PK Battle already started.';
        }

        final duration = (data['battle_duration'] is num && (data['battle_duration'] as num) > 0)
            ? (data['battle_duration'] as num).toInt()
            : selectedBattleDuration.value;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Atomically lock opponent slot and invalidate all other pending invitations!
        transaction.update(liveStreamDocRef, {
          'pk_opponent_id': currentUserId,
          'pk_invited_user_ids': [], // Clears all other pending invitations
          'battle_type': BattleType.waiting.value,
          'battle_duration': duration,
          'battle_created_at': now,
        });
      });
      showSnackBar('PK Battle starting!');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('PK Battle already started')) {
        showSnackBar('PK Battle already started.');
      } else if (msg.contains('no longer an active call participant')) {
        showSnackBar('You are no longer an active call participant.');
      } else {
        showSnackBar('This PK Battle already has an opponent.');
      }
    }
  }

  /// Co-host rejects PK invitation
  void rejectPkInviteFromHost(int currentUserId) async {
    isPkInviteDialogOpen = false;
    liveStreamDocRef.update({
      'pk_invited_user_ids': FieldValue.arrayRemove([currentUserId]),
    });
  }

  void startBattle() {
    expandedBattleUserIndex.value = null;
    startBattleWithDuration(selectedBattleDuration.value);
  }

  void startBattleWithDuration(int durationMinutes) {
    expandedBattleUserIndex.value = null;
    selectedBattleDuration.value = durationMinutes;
    updateLiveStreamData(
      battleType: BattleType.waiting,
      battleDuration: durationMinutes,
      battleCreatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> startAnotherRound(int durationMinutes) async {
    if (!isHost) return;
    selectedBattleDuration.value = durationMinutes;
    _isRoundFinalizing = false;
    isPkResultPopupShowing = false;

    // Reset current round coins for both participants
    updateUserStateToFirestore(myUserId, currentBattleCoin: 0);
    final opponentId = pkOpponentId.value ?? coHostList.firstOrNull?.userId;
    if (opponentId != null) {
      updateUserStateToFirestore(opponentId, currentBattleCoin: 0);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await liveStreamDocRef.update({
      FirebaseConst.battleType: BattleType.waiting.value,
      FirebaseConst.battleDuration: durationMinutes,
      FirebaseConst.battleCreatedAt: now,
      FirebaseConst.battleRound: FieldValue.increment(1),
    });
  }

  void battleRunning() {
    Livestream stream = liveData.value;
    final durationMinutes = stream.battleDuration > 0 ? stream.battleDuration : 2;
    totalBattleSecond = Duration(minutes: durationMinutes).inSeconds;

    final startTime =
        DateTime.fromMillisecondsSinceEpoch(stream.battleCreatedAt ?? 0);
    final endTime = startTime
        .add(Duration(seconds: totalBattleSecond + AppRes.battleStartInSecond));

    Loggers.success('Battle Timer Started (Duration: $durationMinutes min)');
    _isRoundFinalizing = false;

    _timerStart(() {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      remainingBattleSeconds.value = remaining.clamp(0, totalBattleSecond);

      if (remainingBattleSeconds.value <= 10 && remainingBattleSeconds.value > 0) {
        if (!countdownPlayer.playing) {
          countdownPlayer
              .seek(Duration(seconds: 10 - remainingBattleSeconds.value));
          countdownPlayer.play();
        }
      }

      Loggers.info(
          '[BATTLE RUNNING] Battle end in ${remainingBattleSeconds.value} sec.');

      if (remainingBattleSeconds.value <= 0) {
        if (!_isRoundFinalizing) {
          _isRoundFinalizing = true;
          timer?.cancel();
          winAudioPlayer.seek(const Duration(seconds: 0));
          winAudioPlayer.play();
          if (isHost) {
            _finalizeBattleRound();
          }
        }
      }
    });
  }

  /// Finalizes the battle round, calculates winner/loser/tie, gathers top supporters,
  /// updates Firestore lastRoundResult, and saves battle history on backend.
  Future<void> _finalizeBattleRound() async {
    if (!isHost) return;
    final hostState =
        liveUsersStates.firstWhereOrNull((e) => e.userId == myUserId);
    final opponentId = pkOpponentId.value ?? coHostList.firstOrNull?.userId;
    final opponentState =
        liveUsersStates.firstWhereOrNull((e) => e.userId == opponentId);

    final int hostCoins = hostState?.currentBattleCoin ?? 0;
    final int opponentCoins = opponentState?.currentBattleCoin ?? 0;

    final bool isTie = hostCoins == opponentCoins;
    final bool hostWins = hostCoins > opponentCoins;

    final hostAppUser = hostState?.getUser(firestoreController.users) ??
        liveData.value.hostUser ??
        firestoreController.users.firstWhereOrNull((u) => u.userId == myUserId);
    final opponentAppUser = opponentState?.getUser(firestoreController.users) ??
        pkOpponentUser.value ??
        (opponentId != null
            ? firestoreController.users.firstWhereOrNull((u) => u.userId == opponentId)
            : null);

    final winnerUser = isTie ? null : (hostWins ? hostAppUser : opponentAppUser);
    final loserUser = isTie ? null : (hostWins ? opponentAppUser : hostAppUser);

    final winnerCoins = isTie ? hostCoins : (hostWins ? hostCoins : opponentCoins);
    final loserCoins = isTie ? opponentCoins : (hostWins ? opponentCoins : hostCoins);

    // Top supporters for winner (or host if tie)
    final winnerId = winnerUser?.userId ?? myUserId;
    List<Map<String, dynamic>> topSupporters = [];
    final Map<int, int> supporterCoins = {};
    for (final c in comments) {
      if (c.commentType == LivestreamCommentType.gift &&
          c.receiverId == winnerId &&
          c.senderId != null) {
        supporterCoins[c.senderId!] =
            (supporterCoins[c.senderId!] ?? 0) + (c.gift?.coinPrice?.toInt() ?? 1);
      }
    }
    final sortedEntries = supporterCoins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedEntries.take(3)) {
      final u = firestoreController.users
          .firstWhereOrNull((user) => user.userId == entry.key);
      topSupporters.add({
        'id': entry.key,
        'name': entry.key == myUserId
            ? 'You'
            : (u?.fullname ?? u?.username ?? 'Supporter'),
        'profile': u?.profile,
        'diamonds': entry.value,
      });
    }

    final roundResult = {
      'is_tie': isTie,
      'final_score': isTie ? hostCoins : winnerCoins,
      'winner_id': winnerUser?.userId,
      'winner_name': winnerUser?.fullname ?? winnerUser?.username ?? 'Host',
      'winner_profile': winnerUser?.profile,
      'winner_score': winnerCoins,
      'loser_id': loserUser?.userId,
      'loser_name': loserUser?.fullname ?? loserUser?.username ?? 'Opponent',
      'loser_profile': loserUser?.profile,
      'loser_score': loserCoins,
      'user1_profile': hostAppUser?.profile,
      'user1_name': hostAppUser?.fullname ?? hostAppUser?.username ?? 'Host',
      'user2_profile': opponentAppUser?.profile,
      'user2_name': opponentAppUser?.fullname ?? opponentAppUser?.username ?? 'Opponent',
      'round': liveData.value.battleRound ?? 1,
      'top_supporters': topSupporters,
    };

    try {
      await liveStreamDocRef.update({
        FirebaseConst.battleType: BattleType.end.value,
        FirebaseConst.lastRoundResult: roundResult,
      });

      if (opponentId != null) {
        await GiftWalletService.instance.saveBattleResult(
          mode: 'video',
          user1Id: myUserId,
          user2Id: opponentId,
          user1Coins: hostCoins,
          user2Coins: opponentCoins,
          durationMinutes: liveData.value.battleDuration,
        );
      }
    } catch (e) {
      Loggers.error('finalizeBattleRound error: $e');
    }
  }

  void checkAndShowPkResultDialog(Map<String, dynamic> result) {
    if (isPkResultPopupShowing || Get.context == null) return;
    isPkResultPopupShowing = true;
    PkBattleResultDialog.show(
      context: Get.context!,
      result: result,
      isHost: isHost,
      onStartAnotherRound: () {
        isPkResultPopupShowing = false;
        if (Get.context != null) {
          PkBattleDurationSheet.show(
            context: Get.context!,
            initialDuration: selectedBattleDuration.value,
            onStart: (duration) {
              startAnotherRound(duration);
            },
          );
        }
      },
      onClose: () {
        isPkResultPopupShowing = false;
      },
    );
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
          if (Get.isRegistered<DashboardScreenController>()) {
            Get.find<DashboardScreenController>().onChanged(0);
          } else {
            Get.back();
          }
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
