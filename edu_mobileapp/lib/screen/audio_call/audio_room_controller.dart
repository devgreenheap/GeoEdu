import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geoedu/common/widget/live_summary_dialog.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
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
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:geoedu/common/manager/gift_audio_player.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/entry_effects_widget.dart'
    show AnimatedSvgPlayer;

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

  // Real-time top gifter tracking
  final RxMap<String, int> gifterTotals = <String, int>{}.obs;
  final RxString topGifterName = ''.obs;
  final RxInt topGifterDiamonds = 0.obs;

  void recordGiftForTopGifter(String username, int coinPrice) {
    if (username.isEmpty || coinPrice <= 0) return;
    final current = (gifterTotals[username] ?? 0) + coinPrice;
    gifterTotals[username] = current;
    String top = topGifterName.value;
    int maxC = topGifterDiamonds.value;
    gifterTotals.forEach((name, coins) {
      if (coins > maxC) {
        maxC = coins;
        top = name;
      }
    });
    topGifterName.value = top;
    topGifterDiamonds.value = maxC;
  }

  // Background music
  final AudioPlayer _musicPlayer = AudioPlayer();
  final Set<String> _playingStreamIds = {};
  RxBool isMusicPlaying = false.obs;
  RxList<String> musicUrls = <String>[].obs;
  String _currentPlaylistKey = '';

  // Inline gift bar (EloTV-style tap-to-send row, replaces the full-screen
  // gift sheet for this screen).
  RxBool isGiftBarOpen = true.obs;
  RxList<Gift> availableGifts = <Gift>[].obs;
  RxInt diamondBalance = 0.obs;
  bool _diamondBalanceFetched = false;
  Rx<int?> favouriteGiftId = Rx<int?>(null);
  RxBool isRoyalMode = false.obs;
  RxBool isAutoMode = false.obs;
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
  RxInt likeCount = 0.obs;

  void onLikeButtonTap() {
    likeCount.value++;
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
  final RxBool isGiftAnimating = false.obs;
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
  RxInt connectedCallsCount = 0.obs;
  RxInt sessionFollowersGained = 0.obs;

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
    final gifts = availableGifts.isNotEmpty
        ? availableGifts
        : (SessionManager.instance.getSettings()?.availableGifts ?? []);
    if (gifts.isEmpty) return null;
    final favId = favouriteGiftId.value;
    if (favId != null) {
      final fav = gifts.firstWhereOrNull((g) => g.id == favId);
      if (fav != null) return fav;
    }
    final sorted = List<Gift>.from(gifts)
      ..sort((a, b) => (b.coinPrice ?? 0).compareTo(a.coinPrice ?? 0));
    return sorted.first;
  }

  bool get featuredGiftIsNew {
    final createdAt = featuredGift?.createdAt;
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inDays <= 7;
  }

  void _refreshGiftsAndPreload() {
    final s = SessionManager.instance.getSettings();
    if (s != null && s.availableGifts.isNotEmpty) {
      availableGifts.value = s.availableGifts;
      GiftAudioPlayer.preloadAll(s.availableGifts);
      AnimatedSvgPlayer.preloadAll(s.availableGifts);
    }
    // Fetch latest settings from admin API in background so any updated gift audio is immediately cached
    CommonService.instance.fetchGlobalSettings().then((success) {
      if (success) {
        final fresh = SessionManager.instance.getSettings();
        if (fresh != null && fresh.availableGifts.isNotEmpty) {
          availableGifts.value = fresh.availableGifts;
          GiftAudioPlayer.preloadAll(fresh.availableGifts);
          AnimatedSvgPlayer.preloadAll(fresh.availableGifts);
        }
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    comments.clear();
    room.createdAt ??= DateTime.now().millisecondsSinceEpoch;
    roomName.value = room.roomName ?? 'Audio Room';
    _lastSeenLikeCount = room.likeCount ?? 0;
    likeCount.value = room.likeCount ?? 0;
    participantIds.value = List<int>.from(room.participantIds ?? []);
    backgroundImage.value = room.backgroundImage ?? '';
    musicUrls.value = List<String>.from(room.musicUrls ?? []);
    isAutoMode.value = room.isAutoMode ?? false;
    isRoyalMode.value = room.isRoyalMode ?? false;

    _refreshGiftsAndPreload();
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
    fetchDiamondBalanceIfNeeded(force: true);
  }

  Future<void> _purgeSubcollection(CollectionReference coll, {int limit = 300}) async {
    try {
      final snap = await coll.limit(limit).get();
      if (snap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      Loggers.error('Error purging subcollection: $e');
    }
  }

  Future<void> _purgeHostSubcollections() async {
    try {
      final hostRoomRef = _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString());
      final roomCreated = room.createdAt ?? DateTime.now().millisecondsSinceEpoch;

      final oldComments = await hostRoomRef
          .collection('comments')
          .where('timestamp', isLessThan: roomCreated - 3000)
          .limit(300)
          .get();
      if (oldComments.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in oldComments.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      Loggers.error('Error in _purgeHostSubcollections: $e');
    }
  }

  void _listenComments() {
    _commentsSubscription?.cancel();
    comments.clear();

    if (isHost) {
      _purgeHostSubcollections();
    }

    final roomCreated = room.createdAt ?? DateTime.now().millisecondsSinceEpoch;

    Query query = _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .collection('comments')
        .orderBy('timestamp');

    if (roomCreated > 0) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: roomCreated - 3000);
    }

    _commentsSubscription = query
        .limitToLast(100)
        .snapshots()
        .listen(
      (snapshot) {
        comments.value = snapshot.docs
            .map((doc) => AudioComment.fromJson(doc.data() as Map<String, dynamic>))
            .where((c) {
              if (room.roomId != null &&
                  room.roomId!.isNotEmpty &&
                  c.roomId != null &&
                  c.roomId!.isNotEmpty) {
                return c.roomId == room.roomId;
              }
              if (roomCreated > 0) {
                return c.timestamp >= (roomCreated - 3000);
              }
              return true;
            })
            .toList();
      },
      onError: (err) {
        Loggers.error('Comments query error with filter, falling back: $err');
        _commentsSubscription?.cancel();
        _commentsSubscription = _db
            .collection(FirebaseConst.audioRooms)
            .doc(room.hostId.toString())
            .collection('comments')
            .orderBy('timestamp')
            .limitToLast(100)
            .snapshots()
            .listen((fallbackSnap) {
          comments.value = fallbackSnap.docs
              .map((doc) => AudioComment.fromJson(doc.data()))
              .where((c) {
                if (room.roomId != null &&
                    room.roomId!.isNotEmpty &&
                    c.roomId != null &&
                    c.roomId!.isNotEmpty) {
                  return c.roomId == room.roomId;
                }
                if (roomCreated > 0) {
                  return c.timestamp >= (roomCreated - 3000);
                }
                return true;
              })
              .toList();
        });
      },
    );
  }

  Future<void> _postComment(AudioComment comment) {
    final commentWithRoom = AudioComment(
      senderId: comment.senderId,
      senderName: comment.senderName,
      senderPhoto: comment.senderPhoto,
      senderLevel: comment.senderLevel,
      type: comment.type,
      text: comment.text,
      giftName: comment.giftName,
      giftImage: comment.giftImage,
      giftCoinPrice: comment.giftCoinPrice,
      timestamp: comment.timestamp,
      roomId: comment.roomId ?? room.roomId,
    );
    return _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .collection('comments')
        .add(commentWithRoom.toJson());
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

  int _roomEnteredAt = 0;

  void _listenGifts() {
    _roomEnteredAt = DateTime.now().millisecondsSinceEpoch - 2000;
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
          final roomCreated = room.createdAt ?? 0;
          // If the gift was sent before this room session or before user entered, do not record or replay
          if (gift.timestamp < _roomEnteredAt ||
              (roomCreated > 0 && gift.timestamp < roomCreated - 3000)) {
            try {
              change.doc.reference.delete();
            } catch (_) {}
            continue;
          }

          recordGiftForTopGifter(gift.username, (gift.coinPrice ?? 0).toInt());

          // Sender already played the gift effect immediately locally
          if (gift.userId == myUser?.id) {
            continue;
          }
          hostGiftCount.value++;
          hostStarTotal.value += (gift.coinPrice ?? 0).toInt();
          giftQueue.add(gift);
          _processGiftQueue();
        }
      }
    });
  }

  void _processGiftQueue() async {
    if (activeGifts.isNotEmpty) return;
    if (giftQueue.isEmpty) {
      isGiftAnimating.value = false;
      return;
    }

    isGiftAnimating.value = true;
    GiftEffect gift = giftQueue.removeAt(0);
    activeGifts.add(gift);

    // Audio is handled by GiftEffectWidget to avoid duplicate audio triggers

    // Wait until animation ends and removes gift from activeGifts (or max 4.5s timeout)
    try {
      int waited = 0;
      while (activeGifts.contains(gift) && waited < 4500) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
    } finally {
      activeGifts.remove(gift);
      GiftAudioPlayer.stop();
      if (giftQueue.isNotEmpty) {
        _processGiftQueue();
      } else {
        isGiftAnimating.value = false;
      }
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
    GiftAudioPlayer.stop();
    if (!_isCleaningUp) {
      // Only clean up if _forceExit hasn't already done it
      _musicPlayer.stop();
      _musicPlayer.dispose();
      _leaveZegoRoom();
    }
    if (myUser?.id != null) {
      OnlinePresenceService.instance.setInCall(myUser!.id!, false);
    }
    // If host is closing, delete the room and clean subcollections so participants get disconnected
    if (isHost) {
      final hostRoomRef = _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString());
      _purgeSubcollection(hostRoomRef.collection('comments'));
      _purgeSubcollection(hostRoomRef.collection('gifts'));
      hostRoomRef.delete();
    }
    super.onClose();
  }

  Future<void> _initAudio() async {
    try {
      if (isHost) {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          showSnackBar('Microphone permission is required to host the audio room');
        }
      }

      await ZegoExpressEngine.instance.enableCamera(false);
      await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      await ZegoExpressEngine.instance.muteAllPlayStreamAudio(false);

      // Register callbacks BEFORE loginRoom so we don't miss existing streams
      ZegoExpressEngine.onRoomStreamUpdate = _onRoomStreamUpdate;
      ZegoExpressEngine.onRoomUserUpdate = _onRoomUserUpdate;

      final userId = myUser?.id?.toString() ?? '0';
      final userName = myUser?.fullname ?? '';
      final zegoUser = ZegoUser(userId, userName);

      final roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true;

      await ZegoExpressEngine.instance.loginRoom(
        room.roomId ?? '',
        zegoUser,
        config: roomConfig,
      );

      if (isHost) {
        // Host publishes audio stream
        await ZegoExpressEngine.instance.muteMicrophone(false);
        await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
        await ZegoExpressEngine.instance.setCaptureVolume(100);
        await ZegoExpressEngine.instance.startPublishingStream(
          '${room.roomId}_$userId',
        );
      } else {
        // Participants only listen initially — no mic
        await ZegoExpressEngine.instance.muteMicrophone(true);
        await ZegoExpressEngine.instance.mutePublishStreamAudio(true);

        // Manually play host's stream in case onRoomStreamUpdate didn't fire
        final hostStreamId = '${room.roomId}_${room.hostId}';
        _playRemoteSpeakerStream(hostStreamId);
      }

      await OnlinePresenceService.instance.setInCall(myUser!.id!, true);

      Loggers.success('AudioRoom: Joined room ${room.roomId}');
    } catch (e) {
      Loggers.error('AudioRoom: init audio error: $e');
    }
  }

  void _playRemoteSpeakerStream(String streamId) {
    final myStreamId = '${room.roomId}_${myUser?.id}';
    if (streamId == myStreamId) return; // Never play own stream
    _playingStreamIds.add(streamId);
    Loggers.info('AudioRoom: Subscribing to remote stream $streamId');

    void doPlay() async {
      try {
        await ZegoExpressEngine.instance.muteAllPlayStreamAudio(false);
        await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
        await ZegoExpressEngine.instance.startPlayingStream(streamId);
        await ZegoExpressEngine.instance.mutePlayStreamAudio(streamId, false);
        await ZegoExpressEngine.instance.setPlayVolume(streamId, 100);
        await ZegoExpressEngine.instance.setAllPlayStreamVolume(100);
        Loggers.success('AudioRoom: Successfully playing remote stream $streamId');
      } catch (e) {
        Loggers.error('AudioRoom: Error playing remote stream $streamId: $e');
      }
    }

    doPlay();

    // Redo after short delay in case remote publisher was still negotiating connection
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_playingStreamIds.contains(streamId)) {
        doPlay();
      }
    });
  }

  void _stopRemoteSpeakerStream(String streamId) {
    if (!_playingStreamIds.contains(streamId)) return;
    _playingStreamIds.remove(streamId);
    try {
      ZegoExpressEngine.instance.stopPlayingStream(streamId);
      Loggers.info('AudioRoom: Stopped playing remote stream $streamId');
    } catch (e) {
      Loggers.error('AudioRoom: Error stopping remote stream $streamId: $e');
    }
  }

  void _onRoomStreamUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
    final myStreamId = '${room.roomId}_${myUser?.id}';
    for (var stream in streamList) {
      final streamId = stream.streamID;
      if (streamId == myStreamId) continue;

      if (updateType == ZegoUpdateType.Add) {
        _playRemoteSpeakerStream(streamId);
        Loggers.success('AudioRoom: _onRoomStreamUpdate Add stream $streamId');
      } else {
        _stopRemoteSpeakerStream(streamId);
        Loggers.info('AudioRoom: _onRoomStreamUpdate Stopped stream $streamId');

        // Check if the host's stream was deleted — force exit all participants
        final hostStreamId = '${room.roomId}_${room.hostId}';
        if (!isHost && streamId == hostStreamId) {
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
      if (updatedRoom.isActive == false && !isHost) {
        _forceExit('Host has ended the room');
        return;
      }
      participantIds.value = List<int>.from(updatedRoom.participantIds ?? []);
      if (participantIds.length > peakListenerCount) {
        peakListenerCount = participantIds.length;
      }
      final newSpeakerCount = (updatedRoom.speakerIds?.length ?? 1) - 1;
      if (newSpeakerCount > connectedCallsCount.value) {
        connectedCallsCount.value = newSpeakerCount;
      }
      roomName.value = updatedRoom.roomName ?? 'Audio Room';
      backgroundImage.value = updatedRoom.backgroundImage ?? '';
      isRoomActive.value = updatedRoom.isActive ?? false;
      isAutoMode.value = updatedRoom.isAutoMode ?? false;
      favouriteGiftId.value = updatedRoom.favouriteGiftId;
      isRoyalMode.value = updatedRoom.isRoyalMode ?? false;
      themeIndex.value = updatedRoom.themeIndex;
      mutedSpeakerIds.value = List<int>.from(updatedRoom.mutedSpeakerIds ?? []);
      lockedSeatIndices.value = List<int>.from(updatedRoom.lockedSeatIndices ?? []);
      pinnedComment.value = updatedRoom.pinnedComment ?? '';
      final newLikeCount = updatedRoom.likeCount ?? 0;
      likeCount.value = newLikeCount;
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

      // Ensure every remote speaker's stream is playing on this device
      for (final spkId in newSpeakerIds) {
        if (spkId != myUser?.id) {
          final spkStreamId = '${room.roomId}_$spkId';
          if (!_playingStreamIds.contains(spkStreamId)) {
            _playRemoteSpeakerStream(spkStreamId);
          }
        }
      }

      // Stop any stream whose user is no longer a speaker (and not the host)
      final allowedActiveStreams = {
        '${room.roomId}_${room.hostId}',
        ...newSpeakerIds.map((id) => '${room.roomId}_$id'),
      };
      final staleStreams = _playingStreamIds
          .where((id) => !allowedActiveStreams.contains(id))
          .toList();
      for (final staleId in staleStreams) {
        _stopRemoteSpeakerStream(staleId);
      }

      // Sync playback muting for any muted speakers
      for (final spkId in newSpeakerIds) {
        if (spkId != myUser?.id) {
          final isSpkMuted = mutedSpeakerIds.contains(spkId);
          ZegoExpressEngine.instance.mutePlayStreamAudio(
            '${room.roomId}_$spkId',
            isSpkMuted,
          );
        }
      }

      // "Automatic Mode" (set when the host created the room) auto-accepts
      // speak requests instead of the host approving each one manually
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
          Get.delete<AudioRoomController>();
        } catch (e) {
          Loggers.error('AudioRoom: force exit navigation error: $e');
        }
      });
    });
  }

  Future<void> _fetchParticipantProfiles() async {
    final List<OnlineUser> fetched = [];
    final allIds = <int>{...participantIds, ...speakerIds, ...requestIds};
    for (int id in allIds) {
      try {
        final doc = await _db
            .collection(FirebaseConst.onlineUsers)
            .doc(id.toString())
            .get();
        if (doc.exists) {
          fetched.add(OnlineUser.fromJson(doc.data()!));
        } else {
          final userDoc = await _db
              .collection(FirebaseConst.users)
              .doc(id.toString())
              .get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            fetched.add(OnlineUser(
              userId: id,
              fullname: data['fullname'] ?? data['username'] ?? 'User $id',
              username: data['username'],
              profilePhoto: data['profile_photo'] ?? data['profile'],
            ));
          }
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
    if (isSpeaker.value) {
      showSnackBar('You are already connected as a speaker');
      return;
    }
    if (hasRequested.value) {
      showSnackBar('Join Call request is pending host approval');
      return;
    }
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      showSnackBar('Microphone permission is required to join call');
      return;
    }
    hasRequested.value = true;
    try {
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .update({
        'request_ids': FieldValue.arrayUnion([myUser!.id]),
      });
      _postComment(AudioComment(
        senderId: myUser!.id!,
        senderName: myUser!.fullname ?? myUser!.username ?? 'User',
        senderPhoto: myUser!.profilePhoto,
        senderLevel: myUser!.getLevel.level,
        type: AudioCommentType.text,
        text: '📹 requested to Join Call',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      showSnackBar('Join Call request sent to host');
    } catch (e) {
      hasRequested.value = false;
      showSnackBar('Failed to send request: $e');
    }
  }

  /// Host accepts a speaker request
  void acceptSpeaker(int userId) async {
    if (!isHost) return;
    connectedCallsCount.value++;
    final speakerStreamId = '${room.roomId}_$userId';
    // Immediately subscribe so host hears the user as soon as they speak
    _playRemoteSpeakerStream(speakerStreamId);

    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'speaker_ids': FieldValue.arrayUnion([userId]),
      'request_ids': FieldValue.arrayRemove([userId]),
    });
    final participant =
        participants.firstWhereOrNull((p) => p.userId == userId);
    _postComment(AudioComment(
      senderId: userId,
      senderName: participant?.fullname ?? 'User',
      senderPhoto: participant?.profilePhoto,
      type: AudioCommentType.text,
      text: '🎙️ joined the call as speaker',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    showSnackBar('Accepted ${participant?.fullname ?? "User"} to call');
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
    final speakerStreamId = '${room.roomId}_$userId';
    _stopRemoteSpeakerStream(speakerStreamId);
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
    final speakerStreamId = '${room.roomId}_$userId';
    ZegoExpressEngine.instance.mutePlayStreamAudio(speakerStreamId, !isMuted);
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
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        showSnackBar('Microphone permission is required to speak');
        return;
      }
      final userId = myUser?.id?.toString() ?? '0';
      final streamId = '${room.roomId}_$userId';

      await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(false);
      await ZegoExpressEngine.instance.setCaptureVolume(100);
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);

      await ZegoExpressEngine.instance.startPublishingStream(streamId);
      isMuted.value = false;
      showSnackBar('You can now speak');
      Loggers.success('AudioRoom: Started speaking on stream $streamId');
    } catch (e) {
      Loggers.error('AudioRoom: start speaking error: $e');
    }
  }

  /// Stop publishing stream when revoked
  Future<void> _stopSpeaking() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      await ZegoExpressEngine.instance.muteMicrophone(true);
      await ZegoExpressEngine.instance.mutePublishStreamAudio(true);
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
    ZegoExpressEngine.instance.mutePublishStreamAudio(isMuted.value);
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
    final newValue = !isRoyalMode.value;
    isRoyalMode.value = newValue;
    try {
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .update({'is_royal_mode': newValue});
    } catch (e) {
      Loggers.error('AudioRoom: toggleRoyalMode error: $e');
      isRoyalMode.value = !newValue;
    }
  }

  void toggleAutoMode(bool value) async {
    isAutoMode.value = value;
    if (!isHost) return;
    try {
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .update({'is_auto_mode': value});
      if (value && requestIds.isNotEmpty && speakerIds.length < maxSpeakerSeats) {
        final freeSeats = maxSpeakerSeats - speakerIds.length;
        for (final userId in List<int>.from(requestIds).take(freeSeats)) {
          acceptSpeaker(userId);
        }
      }
    } catch (e) {
      Loggers.error('toggleAutoMode error: $e');
    }
  }

  void setFavouriteGift(Gift gift) async {
    if (!isHost || gift.id == null) return;
    favouriteGiftId.value = gift.id;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'favourite_gift_id': gift.id});
  }

  void removeFavouriteGift() async {
    if (!isHost) return;
    favouriteGiftId.value = null;
    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({'favourite_gift_id': null});
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

  Future<void> fetchDiamondBalance() => fetchDiamondBalanceIfNeeded(force: true);

  void openGiftBar() {
    if (isHost) return;
    isGiftBarOpen.value = true;
    fetchDiamondBalanceIfNeeded(force: true);
    _refreshGiftsAndPreload();
  }

  Future<void> sendGiftDirect(Gift gift) async {
    // Prevent clicking another gift until the 1st one finishes loading & animating!
    if (isGiftAnimating.value || activeGifts.isNotEmpty) {
      return;
    }

    final hostId = room.hostId;
    if (hostId == null) {
      showSnackBar('Host not found');
      return;
    }
    if (isHost || hostId == myUser?.id) {
      showSnackBar('You cannot send gifts to yourself');
      return;
    }
    final giftId = gift.id;
    final coinPrice = gift.coinPrice ?? 0;
    if (coinPrice <= 0) {
      showSnackBar('Invalid gift price');
      return;
    }
    if (diamondBalance.value < coinPrice) {
      showInsufficientDiamondsDialog(
        requiredDiamonds: coinPrice,
        giftName: gift.displayName,
      );
      return;
    }

    // Immediately lock to prevent concurrent taps
    isGiftAnimating.value = true;

    final freshGift = (giftId != null)
        ? (availableGifts.firstWhereOrNull((g) => g.id == giftId) ?? gift)
        : gift;

    final rawAnim = freshGift.animationUrl?.trim() ?? '';
    final rawImage = freshGift.image?.trim() ?? '';
    final resolvedThumbnail = rawImage.isNotEmpty ? rawImage.addBaseURL() : '';
    final resolvedAsset = rawAnim.isNotEmpty
        ? rawAnim.addBaseURL()
        : (resolvedThumbnail.isNotEmpty ? resolvedThumbnail : freshGift.effectiveAssetUrl.addBaseURL());
    final soundUrl = freshGift.effectiveSoundUrl.isNotEmpty
        ? freshGift.effectiveSoundUrl
        : 'assets/images/fairy-sparkle.mp3';

    // Instantly play audio the moment the user taps the gift (0ms delay!)
    GiftAudioPlayer.play(soundUrl);

    // Instantly show local gift effect and play sound so sender sees instant action!
    diamondBalance.value -= coinPrice;
    hostGiftCount.value++;
    hostStarTotal.value += coinPrice;

    final giftEffect = GiftEffect(
      userId: myUser?.id ?? 0,
      username: myUser?.fullname ?? myUser?.username ?? 'User',
      senderPhoto: myUser?.profilePhoto,
      giftName: freshGift.displayName,
      assetUrl: resolvedAsset,
      thumbnailUrl: resolvedThumbnail,
      audio: soundUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      coinPrice: coinPrice,
    );

    giftQueue.add(giftEffect);
    _processGiftQueue();
    recordGiftForTopGifter(
        myUser?.fullname ?? myUser?.username ?? 'User', coinPrice);

    // Audience sending to host: validate and deduct through server API
    int effectiveGiftId = (giftId != null && giftId > 0) ? giftId : -1;
    if (effectiveGiftId <= 0) {
      final serverGifts = availableGifts.isNotEmpty
          ? availableGifts
          : (SessionManager.instance.getSettings()?.gifts ?? []);
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
        'giftName': freshGift.displayName,
        'gift_id': freshGift.id,
        'asset_url': resolvedAsset,
        'thumbnail_url': resolvedThumbnail,
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
        giftName: freshGift.displayName,
        giftImage: freshGift.image,
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

    final startTime = DateTime.fromMillisecondsSinceEpoch(
        room.createdAt ?? DateTime.now().millisecondsSinceEpoch);
    final durationMinutes = math.max(
        1,
        ((DateTime.now().millisecondsSinceEpoch -
                (room.createdAt ?? DateTime.now().millisecondsSinceEpoch)) /
            60000).ceil());
    final viewers = math.max(peakListenerCount, participantIds.length);
    final followers = sessionFollowersGained.value;
    final calls = connectedCallsCount.value;
    final commentsCount = comments.length;
    final gifts = hostGiftCount.value;
    final stars = hostStarTotal.value;

    _roomDocSubscription?.cancel();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    await _leaveZegoRoom();

    if (apiAudioRoomId != null) {
      try {
        await GiftWalletService.instance.endAudioRoom(
          audioRoomId: apiAudioRoomId!,
          peakListenerCount: viewers,
        );
      } catch (e) {
        Loggers.error('AudioRoom: end history error: $e');
      }
    }

    try {
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .update({'is_active': false});
    } catch (_) {}

    try {
      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(room.hostId.toString())
          .delete();
    } catch (_) {}

    if (room.roomId != null && room.roomId!.isNotEmpty) {
      try {
        await _db
            .collection(FirebaseConst.audioRooms)
            .doc(room.roomId!)
            .delete();
      } catch (_) {}
    }

    // Instantly remove from AudioCallListController so it vanishes from Home Page
    if (Get.isRegistered<AudioCallListController>()) {
      Get.find<AudioCallListController>().audioRooms.removeWhere(
            (r) => r.hostId == room.hostId || r.roomId == room.roomId,
          );
    }

    Get.dialog(
      LiveSummaryDialog(
        title: 'Audio Live Show',
        startTime: startTime,
        durationMinutes: durationMinutes,
        followersCount: followers,
        viewersCount: viewers,
        callsCount: calls,
        commentsCount: commentsCount,
        premiumGiftsCount: gifts,
        starsEarned: stars,
        endedBy: 'Host',
        onClose: () {
          Get.back(); // close summary dialog
          Get.back(); // exit AudioRoomScreen to home
          Get.delete<AudioRoomController>();
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> leaveRoom({bool shouldPop = true}) async {
    if (_isCleaningUp || myUser?.id == null) return;
    _isCleaningUp = true;
    _roomDocSubscription?.cancel();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    await _leaveZegoRoom();
    try {
      if (isHost) {
        final hostRoomRef = _db
            .collection(FirebaseConst.audioRooms)
            .doc(room.hostId.toString());
        await _purgeSubcollection(hostRoomRef.collection('comments'));
        await _purgeSubcollection(hostRoomRef.collection('gifts'));
        await hostRoomRef.delete();
      } else {
        await _db
            .collection(FirebaseConst.audioRooms)
            .doc(room.hostId.toString())
            .update({
          'participant_ids': FieldValue.arrayRemove([myUser!.id]),
        });
      }
    } catch (e) {
      Loggers.error('AudioRoom: leave room update error: $e');
    }
    if (shouldPop) {
      Get.back();
    }
    Get.delete<AudioRoomController>();
  }

  Future<void> _leaveZegoRoom() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      final hostStreamId = '${room.roomId}_${room.hostId}';
      await ZegoExpressEngine.instance.stopPlayingStream(hostStreamId);
      for (final sId in _playingStreamIds) {
        await ZegoExpressEngine.instance.stopPlayingStream(sId);
      }
      _playingStreamIds.clear();
      await ZegoExpressEngine.instance.logoutRoom(room.roomId ?? '');
    } catch (e) {
      Loggers.error('AudioRoom: leave zego room error: $e');
    }
  }

  void showInsufficientDiamondsDialog({required int requiredDiamonds, required String giftName}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF9500).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Insufficient Diamonds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'You need '),
                    TextSpan(
                      text: '$requiredDiamonds Diamonds',
                      style: const TextStyle(
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' to send $giftName.\nYour current balance is '),
                    TextSpan(
                      text: '${diamondBalance.value} Diamonds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorRes.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        Get.back(); // close dialog
                        await Get.to(() => StarStoreDiamondScreen(
                              onPurchaseCompleted: () {
                                Get.back(); // return to audio room
                                fetchDiamondBalance();
                              },
                            ));
                        fetchDiamondBalance();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Purchase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

