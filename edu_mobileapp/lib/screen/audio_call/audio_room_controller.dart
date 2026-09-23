import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/functions/media_picker_helper.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/common/service/online_presence_service.dart';
import 'package:geoedu/model/audio_call/audio_comment.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/audio_call/online_user.dart';
import 'package:geoedu/model/livestream/entry_effects_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/app_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class AudioRoomController extends BaseController {
  final AudioRoom room;
  final bool isHost;

  AudioRoomController({required this.room, required this.isHost});

  static const int maxSpeakerSeats = 8;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? myUser = SessionManager.instance.getUser();

  RxBool isMuted = false.obs;
  RxBool isSpeakerOn = true.obs;
  RxString roomName = ''.obs;
  RxList<int> participantIds = <int>[].obs;
  RxList<OnlineUser> participants = <OnlineUser>[].obs;
  RxBool isRoomActive = true.obs;
  RxString backgroundImage = ''.obs;

  // Speaker request system
  RxList<int> speakerIds = <int>[].obs;
  RxList<int> requestIds = <int>[].obs;
  RxBool isSpeaker = false.obs;
  RxBool hasRequested = false.obs;

  // Background music
  final AudioPlayer _musicPlayer = AudioPlayer();
  RxBool isMusicPlaying = false.obs;
  RxList<String> musicUrls = <String>[].obs;
  String _currentPlaylistKey = '';

  // Inline gift bar (EloTV-style tap-to-send row, replaces the full-screen
  // gift sheet for this screen).
  RxBool isGiftBarOpen = false.obs;
  RxInt diamondBalance = 0.obs;
  bool _diamondBalanceFetched = false;
  Rx<int?> favouriteGiftId = Rx<int?>(null);
  RxBool isRoyalMode = false.obs;
  Rx<int?> themeIndex = Rx<int?>(null);
  RxList<int> mutedSpeakerIds = <int>[].obs;
  RxList<int> lockedSeatIndices = <int>[].obs;
  RxString pinnedComment = ''.obs;
  final pinCommentController = TextEditingController();

  // Room-wide like animation — same real broadcast pattern as the video
  // room: a Firestore counter, with every client's heart animation firing
  // off the counter's delta, not just the tapper's own.
  int _lastSeenLikeCount = 0;
  void Function()? onLikeTap;

  void onLikeButtonTap() {
    _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'like_count': FieldValue.increment(1)});
  }

  // Real-time chat — same shape/interaction pattern as the video room's
  // comment feed, scaled down to what audio rooms actually need.
  RxList<AudioComment> comments = <AudioComment>[].obs;
  final textCommentController = TextEditingController();
  StreamSubscription? _commentsSubscription;

  // PK Battle (audio-host-vs-audio-host)
  Rx<int?> pkOpponentId = Rx<int?>(null);
  Rx<String?> pkStatus = Rx<String?>(null);
  Rx<int?> pkStartedAt = Rx<int?>(null);
  RxInt pkDurationMinutes = 0.obs;
  RxInt myPkCoins = 0.obs;
  RxInt opponentPkCoins = 0.obs;
  Rx<int?> pkInviteFrom = Rx<int?>(null);
  Rx<AudioRoom?> opponentRoom = Rx<AudioRoom?>(null);
  RxInt pkRemainingSeconds = 0.obs;
  StreamSubscription? _opponentDocSubscription;
  Timer? _pkTimer;
  void Function(int inviterHostId)? onPkInviteReceived;

  // Room-wide gift animation broadcast (same pattern as video livestream's
  // GiftEffectWidget/listenGifts) — everyone in the room sees the effect,
  // not just the sender.
  List<GiftEffect> giftQueue = [];
  bool isGiftAnimating = false;
  RxList<GiftEffect> activeGifts = <GiftEffect>[].obs;
  StreamSubscription? _giftEffectSubscription;

  StreamSubscription? _roomDocSubscription;
  bool _isCleaningUp = false;

  int? apiAudioRoomId;
  int peakListenerCount = 0;

  // Real running totals for this session, accumulated as gifts actually
  // arrive over the room-wide broadcast — not fabricated placeholders.
  RxInt hostGiftCount = 0.obs;
  RxInt hostStarTotal = 0.obs;

  // Host-set diamond goal for this session — host-local only, matching the
  // video top bar's Target pill (no backend field for a session goal).
  RxInt targetDiamonds = 0.obs;
  void setTargetDiamonds(int value) => targetDiamonds.value = value;
  double get targetProgress {
    final target = targetDiamonds.value;
    if (target <= 0) return 0;
    return (hostStarTotal.value / target).clamp(0, 1).toDouble();
  }

  /// Highest-priced real gift from the catalog — used as the promo card,
  /// same rule as the video host top bar.
  Gift? get featuredGift {
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
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

  @override
  void onInit() {
    super.onInit();
    roomName.value = room.roomName ?? 'Audio Room';
    _lastSeenLikeCount = room.likeCount ?? 0;
    participantIds.value = List<int>.from(room.participantIds ?? []);
    backgroundImage.value = room.backgroundImage ?? '';
    musicUrls.value = List<String>.from(room.musicUrls ?? []);
  }

  @override
  void onReady() {
    super.onReady();
    _initAudio();
    _listenRoomDoc();
    _addSelfToRoom();
    _startBackgroundMusic();
    _listenGifts();
    _listenComments();
    if (isHost) _startRoomHistory();
  }

  void _listenComments() {
    _commentsSubscription = _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .collection('comments')
        .orderBy('timestamp')
        .limitToLast(100)
        .snapshots()
        .listen((snapshot) {
      comments.value = snapshot.docs
          .map((doc) => AudioComment.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> _postComment(AudioComment comment) {
    return _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .collection('comments')
        .add(comment.toJson());
  }

  /// Host waving at a listener who just joined — a real chat message.
  void sendWave(String? username) {
    if (username == null || myUser?.id == null) return;
    _postComment(AudioComment(
      senderId: myUser!.id!,
      senderName: myUser!.fullname ?? myUser!.username ?? 'User',
      senderPhoto: myUser!.profilePhoto,
      senderLevel: myUser!.getLevel.level,
      type: AudioCommentType.text,
      text: '👋 waved at $username',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void sendTextComment() {
    final text = textCommentController.text.trim();
    if (text.isEmpty || myUser?.id == null) return;
    textCommentController.clear();
    _postComment(AudioComment(
      senderId: myUser!.id!,
      senderName: myUser!.fullname ?? myUser!.username ?? 'User',
      senderPhoto: myUser!.profilePhoto,
      senderLevel: myUser!.getLevel.level,
      type: AudioCommentType.text,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Audio rooms live only in Firestore while running, so the MySQL history
  /// row is what the leaderboard and the host's stats read afterwards.
  Future<void> _startRoomHistory() async {
    try {
      apiAudioRoomId = await GiftWalletService.instance.startAudioRoom(
        roomId: room.roomId ?? '',
        roomName: room.roomName,
        languageId: room.languageId,
      );
      apiAudioRoomId ??= await GiftWalletService.instance.startAudioRoom(
        roomId: room.roomId ?? '',
        roomName: room.roomName,
        languageId: room.languageId,
        force: true,
      );
    } catch (e) {
      Loggers.error('AudioRoom: start history error: $e');
    }
  }

  void _listenGifts() {
    _giftEffectSubscription = _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .collection('gifts')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          GiftEffect gift =
              GiftEffect.fromJson(change.doc.data() as Map<String, dynamic>);
          // Sender already played the gift effect immediately locally
          if (gift.userId == myUser?.id) {
            continue;
          }
          hostGiftCount.value++;
          hostStarTotal.value += gift.coinPrice ?? 0;
          giftQueue.add(gift);
          _processGiftQueue();
        }
      }
    });
  }

  void _processGiftQueue() async {
    if (isGiftAnimating) return;
    if (giftQueue.isEmpty) return;

    isGiftAnimating = true;
    GiftEffect gift = giftQueue.removeAt(0);
    activeGifts.add(gift);

    try {
      String audio = (gift.audio != null && gift.audio!.trim().isNotEmpty)
          ? gift.audio!.trim()
          : 'assets/images/fairy-sparkle.mp3';
      try {
        final player = AudioPlayer();
        if (audio.startsWith('http://') || audio.startsWith('https://')) {
          await player.setUrl(audio);
        } else {
          await player.setAsset(audio);
        }
        await player.play();
      } catch (e) {
        try {
          final fallbackPlayer = AudioPlayer();
          await fallbackPlayer.setAsset('assets/images/fairy-sparkle.mp3');
          await fallbackPlayer.play();
        } catch (_) {}
      }
      await Future.delayed(const Duration(seconds: 4));
    } finally {
      activeGifts.remove(gift);
      isGiftAnimating = false;
      _processGiftQueue();
    }
  }

  @override
  void onClose() {
    _roomDocSubscription?.cancel();
    _opponentDocSubscription?.cancel();
    _giftEffectSubscription?.cancel();
    _commentsSubscription?.cancel();
    _pkTimer?.cancel();
    if (isHost && pkOpponentId.value != null) {
      _clearPkFields(room.hostId);
      _clearPkFields(pkOpponentId.value);
    }
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    if (!_isCleaningUp) {
      // Only clean up if _forceExit hasn't already done it
      _musicPlayer.stop();
      _musicPlayer.dispose();
      _leaveZegoRoom();
    }
    if (myUser?.id != null) {
      OnlinePresenceService.instance.setInCall(myUser!.id!, false);
    }
    // If host is closing, delete the room so participants get disconnected
    if (isHost) {
      _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .delete();
    }
    super.onClose();
  }

  Future<void> _initAudio() async {
    try {
      await ZegoExpressEngine.instance.enableCamera(false);
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);

      // Register callbacks BEFORE loginRoom so we don't miss existing streams
      ZegoExpressEngine.onRoomStreamUpdate = _onRoomStreamUpdate;
      ZegoExpressEngine.onRoomUserUpdate = _onRoomUserUpdate;

      final userId = myUser?.id?.toString() ?? '0';
      final userName = myUser?.fullname ?? '';
      final zegoUser = ZegoUser(userId, userName);

      await ZegoExpressEngine.instance.loginRoom(
        room.roomId ?? '',
        zegoUser,
      );

      if (isHost) {
        // Only host publishes audio stream
        await ZegoExpressEngine.instance.muteMicrophone(false);
        await ZegoExpressEngine.instance.startPublishingStream(
          '${room.roomId}_$userId',
        );
      } else {
        // Participants only listen — no mic, no stream
        await ZegoExpressEngine.instance.muteMicrophone(true);

        // Manually play host's stream in case onRoomStreamUpdate didn't fire
        final hostStreamId = '${room.roomId}_${room.hostId}';
        Future.delayed(const Duration(milliseconds: 500), () {
          ZegoExpressEngine.instance.startPlayingStream(hostStreamId);
          Loggers.info('AudioRoom: Manually started playing host stream $hostStreamId');
        });
      }

      await OnlinePresenceService.instance.setInCall(myUser!.id!, true);

      Loggers.success('AudioRoom: Joined room ${room.roomId}');
    } catch (e) {
      Loggers.error('AudioRoom: init audio error: $e');
    }
  }

  void _onRoomStreamUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
    for (var stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        ZegoExpressEngine.instance.startPlayingStream(stream.streamID);
        Loggers.success('AudioRoom: Playing stream ${stream.streamID}');
      } else {
        ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        Loggers.info('AudioRoom: Stopped stream ${stream.streamID}');

        // Check if the host's stream was deleted — force exit all participants
        final hostStreamId = '${room.roomId}_${room.hostId}';
        if (!isHost && stream.streamID == hostStreamId) {
          Loggers.info('AudioRoom: Host stream deleted, forcing exit');
          _forceExit('Host has ended the room');
        }
      }
    }
  }

  void _onRoomUserUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoUser> userList) {
    if (_isCleaningUp) return;
    if (updateType == ZegoUpdateType.Delete && !isHost) {
      final hostUserId = room.hostId?.toString();
      final hostLeft = userList.any((user) => user.userID == hostUserId);
      if (hostLeft) {
        Loggers.info('AudioRoom: Host disconnected from Zego');
        _forceExit('Host has disconnected');
      }
    }
  }

  void _listenRoomDoc() {
    _roomDocSubscription = _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        // Room was deleted (host ended)
        _forceExit('Host has ended the room');
        return;
      }
      final data = snapshot.data()!;
      final updatedRoom = AudioRoom.fromJson(data);
      participantIds.value = List<int>.from(updatedRoom.participantIds ?? []);
      if (participantIds.length > peakListenerCount) {
        peakListenerCount = participantIds.length;
      }
      roomName.value = updatedRoom.roomName ?? 'Audio Room';
      backgroundImage.value = updatedRoom.backgroundImage ?? '';
      isRoomActive.value = updatedRoom.isActive ?? false;
      favouriteGiftId.value = updatedRoom.favouriteGiftId;
      isRoyalMode.value = updatedRoom.isRoyalMode ?? false;
      themeIndex.value = updatedRoom.themeIndex;
      mutedSpeakerIds.value = List<int>.from(updatedRoom.mutedSpeakerIds ?? []);
      lockedSeatIndices.value = List<int>.from(updatedRoom.lockedSeatIndices ?? []);
      pinnedComment.value = updatedRoom.pinnedComment ?? '';
      final newLikeCount = updatedRoom.likeCount ?? 0;
      if (newLikeCount != _lastSeenLikeCount) {
        onLikeTap?.call();
        _lastSeenLikeCount = newLikeCount;
      }

      // PK Battle
      final newInviteFrom = updatedRoom.pkInviteFrom;
      final isNewInvite =
          isHost && newInviteFrom != null && newInviteFrom != pkInviteFrom.value;
      pkInviteFrom.value = newInviteFrom;
      if (isNewInvite) {
        onPkInviteReceived?.call(newInviteFrom);
      }
      pkStatus.value = updatedRoom.pkStatus;
      pkStartedAt.value = updatedRoom.pkStartedAt;
      pkDurationMinutes.value = updatedRoom.pkDurationMinutes ?? 0;
      myPkCoins.value = updatedRoom.pkCoins ?? 0;
      final newOpponentId = updatedRoom.pkOpponentId;
      if (newOpponentId != pkOpponentId.value) {
        pkOpponentId.value = newOpponentId;
        if (newOpponentId != null) {
          _listenOpponentDoc(newOpponentId);
        } else {
          _stopListenOpponentDoc();
        }
      }
      if (updatedRoom.pkStatus == 'running') {
        _startPkTimer();
      } else {
        _pkTimer?.cancel();
        pkRemainingSeconds.value = 0;
      }

      // Update speaker/request lists
      final newSpeakerIds = List<int>.from(updatedRoom.speakerIds ?? []);
      final newRequestIds = List<int>.from(updatedRoom.requestIds ?? []);
      speakerIds.value = newSpeakerIds;
      requestIds.value = newRequestIds;

      // "Automatic Mode" (set when the host created the room) auto-accepts
      // speak requests instead of the host approving each one manually —
      // that field already existed on the room but was never actually
      // consumed anywhere, so toggling it did nothing until now.
      if (isHost &&
          (updatedRoom.isAutoMode ?? false) &&
          newRequestIds.isNotEmpty &&
          newSpeakerIds.length < maxSpeakerSeats) {
        final freeSeats = maxSpeakerSeats - newSpeakerIds.length;
        for (final userId in newRequestIds.take(freeSeats)) {
          acceptSpeaker(userId);
        }
      }

      // Check if current user's speaker status changed
      if (!isHost && myUser?.id != null) {
        final wasSpeaker = isSpeaker.value;
        isSpeaker.value = newSpeakerIds.contains(myUser!.id);
        hasRequested.value = newRequestIds.contains(myUser!.id);

        // User just got approved as speaker — start publishing
        if (!wasSpeaker && isSpeaker.value) {
          _startSpeaking();
        }
        // User got revoked from speaker — stop publishing
        if (wasSpeaker && !isSpeaker.value) {
          _stopSpeaking();
        }
      }

      // Check if the playlist changed
      final newMusicUrls = List<String>.from(updatedRoom.musicUrls ?? []);
      if (newMusicUrls.join('|') != musicUrls.join('|')) {
        musicUrls.value = newMusicUrls;
        _startBackgroundMusic();
      }

      if (!isRoomActive.value) {
        _forceExit('Host has ended the room');
        return;
      }

      _fetchParticipantProfiles();
    }, onError: (e) {
      Loggers.error('AudioRoom: listen room doc error: $e');
      if (!isHost && !_isCleaningUp) {
        _forceExit('Room is no longer available');
      }
    });
  }

  /// Force exit for participants when host ends/disconnects.
  void _forceExit(String message) {
    if (_isCleaningUp || isHost) return;
    _isCleaningUp = true;
    isRoomActive.value = false;
    _roomDocSubscription?.cancel();

    // Stop all audio immediately
    _musicPlayer.stop();
    _musicPlayer.dispose();

    // Clean up Zego immediately — don't wait for onClose()
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    _leaveZegoRoom();

    showSnackBar(message);

    // Pop all overlays and the audio room screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pop back until we exit the AudioRoomScreen
      final navigator = Navigator.of(Get.context!, rootNavigator: true);
      try {
        if (Get.isDialogOpen == true) navigator.pop();
        if (Get.isBottomSheetOpen == true) navigator.pop();
      } catch (_) {}
      // Pop the AudioRoomScreen itself
      Future.delayed(const Duration(milliseconds: 150), () {
        try {
          if (navigator.canPop()) {
            navigator.pop();
            Loggers.info('AudioRoom: Navigator.pop() succeeded');
          } else {
            Loggers.error('AudioRoom: Navigator cannot pop');
          }
        } catch (e) {
          Loggers.error('AudioRoom: force exit navigation error: $e');
        }
      });
    });
  }

  Future<void> _fetchParticipantProfiles() async {
    final List<OnlineUser> fetched = [];
    for (int id in participantIds) {
      try {
        final doc = await _db
            .collection(FirebaseConst.onlineUsers)
            .doc(id.toString())
            .get();
        if (doc.exists) {
          fetched.add(OnlineUser.fromJson(doc.data()!));
        }
      } catch (e) {
        Loggers.error('AudioRoom: fetch participant $id error: $e');
      }
    }
    participants.value = fetched;
  }

  void _addSelfToRoom() async {
    if (myUser?.id == null) return;
    if (participantIds.contains(myUser!.id)) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'participant_ids': FieldValue.arrayUnion([myUser!.id]),
    });
    if (!isHost) {
      _postComment(AudioComment(
        senderId: myUser!.id!,
        senderName: myUser!.fullname ?? myUser!.username ?? 'User',
        senderPhoto: myUser!.profilePhoto,
        senderLevel: myUser!.getLevel.level,
        type: AudioCommentType.joined,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  // ─── Speaker Request System ───

  /// Participant requests to speak
  void requestToSpeak() async {
    if (isHost || myUser?.id == null) return;
    if (hasRequested.value || isSpeaker.value) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'request_ids': FieldValue.arrayUnion([myUser!.id]),
    });
    showSnackBar('Request sent to host');
  }

  /// Host accepts a speaker request
  void acceptSpeaker(int userId) async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'speaker_ids': FieldValue.arrayUnion([userId]),
      'request_ids': FieldValue.arrayRemove([userId]),
    });
  }

  /// Host rejects a speaker request
  void rejectSpeaker(int userId) async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'request_ids': FieldValue.arrayRemove([userId]),
    });
  }

  /// Host revokes speaking permission
  void revokeSpeaker(int userId) async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'speaker_ids': FieldValue.arrayRemove([userId]),
    });
  }

  void toggleMuteParticipant(int userId) async {
    if (!isHost) return;
    final isMuted = mutedSpeakerIds.contains(userId);
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'muted_speaker_ids':
          isMuted ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
    });
  }

  /// Locks/unlocks an empty seat by index so it can't be requested/filled.
  void toggleLockSeat(int seatIndex) async {
    if (!isHost) return;
    final isLocked = lockedSeatIndices.contains(seatIndex);
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'locked_seat_indices':
          isLocked ? FieldValue.arrayRemove([seatIndex]) : FieldValue.arrayUnion([seatIndex]),
    });
  }

  void submitPinnedComment() async {
    if (!isHost) return;
    final text = pinCommentController.text.trim();
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'pinned_comment': text});
    pinCommentController.clear();
  }

  void clearPinnedComment() async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'pinned_comment': ''});
  }

  // ─── PK Battle (audio host vs audio host) ───

  /// Other currently-live audio hosts, for the invite list.
  Future<List<AudioRoom>> fetchOtherLiveHosts() async {
    final snapshot = await _db
        .collection(FirebaseConst.audioRooms)
        .where('is_active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => AudioRoom.fromJson(doc.data()))
        .where((r) => r.hostId != null && r.hostId != room.hostId)
        .toList();
  }

  /// Invite another live host to a PK battle.
  Future<void> invitePkBattle(int opponentHostId) async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(opponentHostId.toString())
        .update({'pk_invite_from': room.hostId});
  }

  void cancelPkInvite(int opponentHostId) async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(opponentHostId.toString())
        .update({'pk_invite_from': null});
  }

  /// Invited host accepts — starts the battle on both rooms.
  Future<void> acceptPkBattle() async {
    if (!isHost || pkInviteFrom.value == null) return;
    final opponentId = pkInviteFrom.value!;
    final duration = SessionManager.instance.getSettings()?.battleDurationMinutes ??
        AppRes.battleDurationInMinutes;
    final now = DateTime.now().millisecondsSinceEpoch;

    final myUpdate = {
      'pk_opponent_id': opponentId,
      'pk_status': 'running',
      'pk_started_at': now,
      'pk_duration_minutes': duration,
      'pk_coins': 0,
      'pk_invite_from': null,
    };
    final opponentUpdate = {
      'pk_opponent_id': room.hostId,
      'pk_status': 'running',
      'pk_started_at': now,
      'pk_duration_minutes': duration,
      'pk_coins': 0,
      'pk_invite_from': null,
    };
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update(myUpdate);
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(opponentId.toString())
        .update(opponentUpdate);
  }

  void rejectPkBattle() async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'pk_invite_from': null});
  }

  /// Ends the battle on both rooms and reports the winner.
  Future<void> endPkBattle() async {
    if (!isHost || pkOpponentId.value == null) return;
    final opponentId = pkOpponentId.value!;
    final myCoins = myPkCoins.value;
    final theirCoins = opponentPkCoins.value;

    try {
      await GiftWalletService.instance.saveBattleResult(
        mode: 'audio',
        user1Id: room.hostId!,
        user2Id: opponentId,
        user1Coins: myCoins,
        user2Coins: theirCoins,
        durationMinutes: pkDurationMinutes.value,
      );
    } catch (e) {
      Loggers.error('AudioRoom: save battle result error: $e');
    }

    await _clearPkFields(room.hostId);
    await _clearPkFields(opponentId);

    if (myCoins == theirCoins) {
      showSnackBar('PK Battle ended in a draw!');
    } else if (myCoins > theirCoins) {
      showSnackBar('PK Battle won! 🏆');
    } else {
      showSnackBar('PK Battle lost.');
    }
  }

  Future<void> _clearPkFields(int? hostId) async {
    if (hostId == null) return;
    try {
      await _db.collection(FirebaseConst.audioRooms).doc(hostId.toString()).update({
        'pk_opponent_id': null,
        'pk_status': null,
        'pk_started_at': null,
        'pk_coins': null,
      });
    } catch (e) {
      Loggers.error('AudioRoom: clear PK fields error: $e');
    }
  }

  void _listenOpponentDoc(int opponentHostId) {
    _opponentDocSubscription?.cancel();
    _opponentDocSubscription = _db
        .collection(FirebaseConst.audioRooms)
        .doc(opponentHostId.toString())
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final opponent = AudioRoom.fromJson(snapshot.data()!);
      opponentRoom.value = opponent;
      opponentPkCoins.value = opponent.pkCoins ?? 0;
      // If the opponent left/ended the battle from their side, mirror it here.
      if (opponent.pkOpponentId != room.hostId && isHost) {
        _clearPkFields(room.hostId);
      }
    });
  }

  void _stopListenOpponentDoc() {
    _opponentDocSubscription?.cancel();
    _opponentDocSubscription = null;
    opponentRoom.value = null;
    opponentPkCoins.value = 0;
  }

  void _startPkTimer() {
    _pkTimer?.cancel();
    _pkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = pkStartedAt.value;
      if (startedAt == null) return;
      final endTime = DateTime.fromMillisecondsSinceEpoch(startedAt)
          .add(Duration(minutes: pkDurationMinutes.value));
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      pkRemainingSeconds.value = remaining > 0 ? remaining : 0;
      if (remaining <= 0 && isHost) {
        endPkBattle();
      }
    });
  }

  /// Start publishing stream when approved as speaker
  Future<void> _startSpeaking() async {
    try {
      final userId = myUser?.id?.toString() ?? '0';
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.startPublishingStream(
        '${room.roomId}_$userId',
      );
      isMuted.value = false;
      showSnackBar('You can now speak');
      Loggers.success('AudioRoom: Started speaking');
    } catch (e) {
      Loggers.error('AudioRoom: start speaking error: $e');
    }
  }

  /// Stop publishing stream when revoked
  Future<void> _stopSpeaking() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      await ZegoExpressEngine.instance.muteMicrophone(true);
      isMuted.value = false;
      showSnackBar('Speaking permission revoked');
      Loggers.info('AudioRoom: Stopped speaking');
    } catch (e) {
      Loggers.error('AudioRoom: stop speaking error: $e');
    }
  }

  void toggleMute() {
    if (!isHost && !isSpeaker.value) return;
    isMuted.value = !isMuted.value;
    ZegoExpressEngine.instance.muteMicrophone(isMuted.value);
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(isSpeakerOn.value);
  }

  Future<void> _startBackgroundMusic() async {
    if (musicUrls.isEmpty) {
      await _musicPlayer.stop();
      isMusicPlaying.value = false;
      _currentPlaylistKey = '';
      return;
    }

    // Rebuild the queue only when the track list itself changed, so an
    // unrelated room-doc update doesn't restart playback mid-song.
    final playlistKey = musicUrls.join('|');
    if (playlistKey == _currentPlaylistKey && isMusicPlaying.value) return;

    try {
      _currentPlaylistKey = playlistKey;
      await _musicPlayer.setAudioSources(
        musicUrls
            .map((url) => AudioSource.uri(Uri.parse(url.addBaseURL())))
            .toList(),
      );
      await _musicPlayer.setLoopMode(LoopMode.all);
      await _musicPlayer.setVolume(0.3);
      await _musicPlayer.play();
      isMusicPlaying.value = true;
      Loggers.success('AudioRoom: Background playlist started (${musicUrls.length} tracks)');
    } catch (e) {
      Loggers.error('AudioRoom: play music error: $e');
      isMusicPlaying.value = false;
    }
  }

  void skipToNextTrack() {
    if (musicUrls.length < 2) return;
    _musicPlayer.seekToNext();
  }

  void toggleMusic() {
    if (isMusicPlaying.value) {
      _musicPlayer.pause();
      isMusicPlaying.value = false;
    } else {
      _musicPlayer.play();
      isMusicPlaying.value = true;
    }
  }

  void removeMusic() async {
    if (!isHost) return;
    await _musicPlayer.stop();
    isMusicPlaying.value = false;
    musicUrls.clear();
    _currentPlaylistKey = '';
    // Clear music from Firestore so participants stop too
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'music_urls': <String>[]});
  }

  /// Fun Centre → My Music: unlike the create-room music picker, this lets
  /// the host add tracks to an already-running room's playlist.
  void changeMusic() async {
    if (!isHost) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'wav', 'm4a', 'ogg', 'wma', 'flac'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    showLoader();
    try {
      final List<String> added = [];
      for (final file in result.files) {
        if (file.path == null) continue;
        final uploadResult =
            await CommonService.instance.uploadFileGivePath(XFile(file.path!));
        if (uploadResult.data != null) added.add(uploadResult.data!);
      }
      if (added.isNotEmpty) {
        await _db
            .collection(FirebaseConst.audioRooms)
            .doc(room.hostId.toString())
            .update({'music_urls': FieldValue.arrayUnion(added)});
      }
    } catch (e) {
      Loggers.error('AudioRoom: change music error: $e');
    }
    stopLoader();
  }

  /// Fun Centre → Royal Mode: a cosmetic gold badge/frame for the room,
  /// visible to every viewer, toggled on/off by the host.
  void toggleRoyalMode() async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'is_royal_mode': !isRoyalMode.value});
  }

  void setFavouriteGift(Gift gift) async {
    if (!isHost || gift.id == null) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'favourite_gift_id': gift.id});
  }

  void changeBackgroundImage() async {
    if (!isHost) return;
    final image =
        await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    showLoader();
    try {
      final result = await CommonService.instance.uploadFileGivePath(image);
      if (result.data != null) {
        await _db
            .collection(FirebaseConst.audioRooms)
            .doc(room.hostId.toString())
            .update({'background_image': result.data, 'theme_index': null});
      }
    } catch (e) {
      Loggers.error('AudioRoom: change bg error: $e');
    }
    stopLoader();
  }

  /// Themes → a curated preset color theme, mutually exclusive with a
  /// custom uploaded background image.
  void setTheme(int index) async {
    if (!isHost) return;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'theme_index': index, 'background_image': ''});
  }

  Future<void> fetchDiamondBalanceIfNeeded({bool force = false}) async {
    if (_diamondBalanceFetched && !force) return;
    _diamondBalanceFetched = true;
    final response = await GiftWalletService.instance.fetchMyDiamondWallet();
    if (response.data?.diamondBalance != null) {
      diamondBalance.value = response.data!.diamondBalance!;
    }
  }

  void openGiftBar() {
    isGiftBarOpen.value = true;
    fetchDiamondBalanceIfNeeded(force: true);
    CommonService.instance.fetchGlobalSettings();
  }

  Future<void> sendGiftDirect(Gift gift) async {
    final hostId = room.hostId;
    if (hostId == null) {
      showSnackBar('Host not found');
      return;
    }
    final giftId = gift.id;
    final coinPrice = gift.coinPrice ?? 0;
    if (coinPrice <= 0) {
      showSnackBar('Invalid gift price');
      return;
    }
    if (diamondBalance.value < coinPrice) {
      showSnackBar('Not enough diamonds in your wallet');
      return;
    }

    final isHostSelf = (hostId == myUser?.id);

    final rawAsset = gift.effectiveAssetUrl;
    final assetUrl = rawAsset.isNotEmpty
        ? rawAsset.addBaseURL()
        : (gift.image?.addBaseURL() ?? '');
    final soundUrl = (gift.soundUrl != null && gift.soundUrl!.trim().isNotEmpty)
        ? gift.soundUrl!.trim().addBaseURL()
        : 'assets/images/fairy-sparkle.mp3';

    // Instantly show local gift effect and play sound so sender sees instant action!
    diamondBalance.value -= coinPrice;
    hostGiftCount.value++;
    hostStarTotal.value += coinPrice;

    final giftEffect = GiftEffect(
      userId: myUser?.id ?? 0,
      username: myUser?.fullname ?? myUser?.username ?? 'User',
      senderPhoto: myUser?.profilePhoto,
      giftName: gift.displayName,
      assetUrl: assetUrl,
      audio: soundUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      coinPrice: coinPrice,
    );

    giftQueue.add(giftEffect);
    _processGiftQueue();

    // If host is testing or celebrating in their own room:
    if (isHostSelf) {
      try {
        await _db
            .collection(FirebaseConst.audioRooms)
            .doc(hostId.toString())
            .collection('gifts')
            .add({
          'userId': myUser?.id,
          'username': myUser?.fullname ?? myUser?.username ?? '',
          'senderPhoto': myUser?.profilePhoto ?? '',
          'giftName': gift.displayName,
          'asset_url': assetUrl,
          'audio': soundUrl,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'coin_price': coinPrice,
        });
      } catch (e) {
        Loggers.error('Error broadcasting audio gift to firestore: $e');
      }

      _postComment(AudioComment(
        senderId: myUser!.id!,
        senderName: myUser!.fullname ?? myUser!.username ?? 'User',
        senderPhoto: myUser!.profilePhoto,
        senderLevel: myUser!.getLevel.level,
        type: AudioCommentType.gift,
        giftName: gift.displayName,
        giftImage: gift.image,
        giftCoinPrice: coinPrice,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      return;
    }

    // Otherwise, audience sending to host: validate and deduct through server API
    int effectiveGiftId = (giftId != null && giftId > 0) ? giftId : -1;
    if (effectiveGiftId <= 0) {
      final serverGifts = SessionManager.instance.getSettings()?.gifts ?? [];
      final matchingServerGift = serverGifts.firstWhere(
        (g) => (g.coinPrice ?? 0) == coinPrice,
        orElse: () => serverGifts.isNotEmpty ? serverGifts.first : Gift.penGift,
      );
      if (matchingServerGift.id != null && matchingServerGift.id! > 0) {
        effectiveGiftId = matchingServerGift.id!;
      }
    }

    try {
      final int? langId = (room.languageId != null && room.languageId! > 0)
          ? room.languageId
          : null;
      final response = await GiftWalletService.instance.spendDiamonds(
          diamonds: coinPrice,
          userId: hostId,
          giftId: effectiveGiftId,
          source: 'audio_gift',
          languageId: langId);

      if (response.status != true) {
        // Rollback optimistic deduction
        diamondBalance.value += coinPrice;
        fetchDiamondBalanceIfNeeded(force: true);
        return showSnackBar(response.message);
      }

      // Broadcast to all room listeners via Firestore
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(hostId.toString())
          .collection('gifts')
          .add({
        'userId': myUser?.id,
        'username': myUser?.fullname ?? myUser?.username ?? '',
        'senderPhoto': myUser?.profilePhoto ?? '',
        'giftName': gift.displayName,
        'asset_url': assetUrl,
        'audio': soundUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'coin_price': coinPrice,
      });

      _postComment(AudioComment(
        senderId: myUser!.id!,
        senderName: myUser!.fullname ?? myUser!.username ?? 'User',
        senderPhoto: myUser!.profilePhoto,
        senderLevel: myUser!.getLevel.level,
        type: AudioCommentType.gift,
        giftName: gift.displayName,
        giftImage: gift.image,
        giftCoinPrice: coinPrice,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));

      if (pkStatus.value == 'running') {
        await _db
            .collection(FirebaseConst.audioRooms)
            .doc(hostId.toString())
            .update({'pk_coins': FieldValue.increment(coinPrice)});
      }
    } catch (e) {
      Loggers.error('Error sending audio gift: $e');
    }
  }

  void endRoom() async {
    if (!isHost || _isCleaningUp) return;
    _isCleaningUp = true;
    _roomDocSubscription?.cancel();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    _leaveZegoRoom();
    if (apiAudioRoomId != null) {
      try {
        await GiftWalletService.instance.endAudioRoom(
          audioRoomId: apiAudioRoomId!,
          peakListenerCount: peakListenerCount,
        );
      } catch (e) {
        Loggers.error('AudioRoom: end history error: $e');
      }
    }
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .delete();
    Get.back();
  }

  void leaveRoom() async {
    if (_isCleaningUp || myUser?.id == null) return;
    _isCleaningUp = true;
    _roomDocSubscription?.cancel();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    _leaveZegoRoom();
    try {
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .update({
        'participant_ids': FieldValue.arrayRemove([myUser!.id]),
      });
    } catch (e) {
      Loggers.error('AudioRoom: leave room update error: $e');
    }
    Get.back();
  }

  Future<void> _leaveZegoRoom() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      await ZegoExpressEngine.instance.logoutRoom(room.roomId ?? '');
    } catch (e) {
      Loggers.error('AudioRoom: leave zego room error: $e');
    }
  }
}
