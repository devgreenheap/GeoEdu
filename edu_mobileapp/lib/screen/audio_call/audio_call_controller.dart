import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/online_presence_service.dart';
import 'package:geoedu/model/audio_call/audio_call.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class AudioCallController extends BaseController {
  final AudioCall call;
  final bool isCaller;

  AudioCallController({required this.call, required this.isCaller});

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? myUser = SessionManager.instance.getUser();

  RxBool isMuted = false.obs;
  RxBool isSpeakerOn = true.obs;
  RxString callStatusText = 'Calling...'.obs;
  RxInt callDuration = 0.obs;
  RxBool isConnected = false.obs;

  StreamSubscription? _callDocSubscription;
  Timer? _timeoutTimer;
  Timer? _durationTimer;

  @override
  void onReady() {
    super.onReady();
    _initAudio();
    _listenCallDoc();
    if (isCaller) {
      _startTimeout();
    }
  }

  @override
  void onClose() {
    _callDocSubscription?.cancel();
    _timeoutTimer?.cancel();
    _durationTimer?.cancel();
    _leaveZegoRoom();
    super.onClose();
  }

  Future<void> _initAudio() async {
    try {
      await ZegoExpressEngine.instance.enableCamera(false);
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      await ZegoExpressEngine.instance.muteMicrophone(false);

      final userId = myUser?.id?.toString() ?? '0';
      final userName = myUser?.fullname ?? '';
      final zegoUser = ZegoUser(userId, userName);

      await ZegoExpressEngine.instance.loginRoom(
        call.roomId ?? '',
        zegoUser,
      );

      await ZegoExpressEngine.instance.startPublishingStream(
        '${call.roomId}_$userId',
      );

      ZegoExpressEngine.onRoomStreamUpdate = _onRoomStreamUpdate;
      ZegoExpressEngine.onRoomUserUpdate = _onRoomUserUpdate;

      Loggers.success('AudioCall: Joined room ${call.roomId}');
    } catch (e) {
      Loggers.error('AudioCall: init audio error: $e');
    }
  }

  void _onRoomStreamUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
    for (var stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        ZegoExpressEngine.instance.startPlayingStream(stream.streamID);
        Loggers.success('AudioCall: Playing stream ${stream.streamID}');
      } else {
        ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        Loggers.info('AudioCall: Stopped stream ${stream.streamID}');
      }
    }
  }

  void _onRoomUserUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoUser> userList) {
    if (updateType == ZegoUpdateType.Delete) {
      Loggers.info('AudioCall: Remote user left');
      if (isConnected.value) {
        endCall();
      }
    }
  }

  void _listenCallDoc() {
    if (call.docId == null) return;
    _callDocSubscription = _db
        .collection(FirebaseConst.audioCalls)
        .doc(call.docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['call_status'] as String?;

      switch (status) {
        case AudioCallStatus.accepted:
          _onCallAccepted();
          break;
        case AudioCallStatus.rejected:
          _onCallRejected();
          break;
        case AudioCallStatus.ended:
          _onCallEnded();
          break;
        case AudioCallStatus.missed:
          _onCallMissed();
          break;
      }
    });
  }

  void _onCallAccepted() {
    if (isConnected.value) return;
    _timeoutTimer?.cancel();
    isConnected.value = true;
    callStatusText.value = 'Connected';
    _startDurationTimer();
  }

  void _onCallRejected() {
    callStatusText.value = 'Call Declined';
    Future.delayed(const Duration(seconds: 1), () => _cleanup());
  }

  void _onCallEnded() {
    callStatusText.value = 'Call Ended';
    Future.delayed(const Duration(milliseconds: 500), () => _cleanup());
  }

  void _onCallMissed() {
    callStatusText.value = 'No Answer';
    Future.delayed(const Duration(seconds: 1), () => _cleanup());
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!isConnected.value) {
        _db
            .collection(FirebaseConst.audioCalls)
            .doc(call.docId)
            .update({'call_status': AudioCallStatus.missed});
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value++;
    });
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    ZegoExpressEngine.instance.muteMicrophone(isMuted.value);
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(isSpeakerOn.value);
  }

  void sendGift() {
    final receiverId = isCaller ? call.calleeId : call.callerId;
    GiftManager.openGiftSheet(
      userId: receiverId ?? -1,
      source: 'audio_gift',
      onCompletion: (giftManager) {
        GiftManager.showAnimationDialog(giftManager.gift);
      },
    );
  }

  void endCall() async {
    if (call.docId == null) return;
    await _db
        .collection(FirebaseConst.audioCalls)
        .doc(call.docId)
        .update({
      'call_status': AudioCallStatus.ended,
      'ended_at': DateTime.now().millisecondsSinceEpoch,
    });
    _cleanup();
  }

  Future<void> _leaveZegoRoom() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      await ZegoExpressEngine.instance.logoutRoom(call.roomId ?? '');
    } catch (e) {
      Loggers.error('AudioCall: leave room error: $e');
    }
  }

  void _cleanup() {
    _callDocSubscription?.cancel();
    _timeoutTimer?.cancel();
    _durationTimer?.cancel();
    if (myUser?.id != null) {
      OnlinePresenceService.instance.setInCall(myUser!.id!, false);
    }
    if (Get.isDialogOpen == true) Get.back();
    Get.back();
  }

  String get formattedDuration {
    final minutes = (callDuration.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (callDuration.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
