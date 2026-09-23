import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/online_presence_service.dart';
import 'package:geoedu/model/audio_call/audio_call.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/screen/audio_call/audio_call_screen.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_screen.dart';
import 'package:geoedu/screen/live_stream/go_live_setup_screen.dart';
import 'package:geoedu/screen/audio_call/widget/incoming_call_overlay.dart';
import 'package:geoedu/utilities/firebase_const.dart';

class AudioCallListController extends BaseController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? myUser = SessionManager.instance.getUser();

  RxList<AudioRoom> audioRooms = <AudioRoom>[].obs;

  StreamSubscription? _audioRoomsSubscription;
  StreamSubscription? _incomingCallSubscription;

  @override
  void onReady() {
    super.onReady();
    _listenAudioRooms();
    _listenIncomingCalls();
  }

  @override
  void onClose() {
    _audioRoomsSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    super.onClose();
  }

  void _listenAudioRooms() {
    _audioRoomsSubscription = _db
        .collection(FirebaseConst.audioRooms)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => AudioRoom.fromJson(doc.data()))
          .toList();
      audioRooms.value = rooms;
    }, onError: (e) {
      Loggers.error('AudioCallList: listen audio rooms error: $e');
    });
  }

  void _listenIncomingCalls() {
    if (myUser?.id == null) return;
    _incomingCallSubscription = _db
        .collection(FirebaseConst.audioCalls)
        .where('callee_id', isEqualTo: myUser!.id)
        .where('call_status', isEqualTo: AudioCallStatus.ringing)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final call = AudioCall.fromJson(change.doc.data()!);
          call.docId = change.doc.id;
          _showIncomingCall(call);
        }
      }
    }, onError: (e) {
      Loggers.error('AudioCallList: listen incoming calls error: $e');
    });
  }

  void _showIncomingCall(AudioCall call) {
    Get.dialog(
      IncomingCallOverlay(
        call: call,
        onAccept: () => _acceptCall(call),
        onReject: () => _rejectCall(call),
      ),
      barrierDismissible: false,
    );
  }

  void _acceptCall(AudioCall call) async {
    Get.back();
    await _db
        .collection(FirebaseConst.audioCalls)
        .doc(call.docId)
        .update({
      'call_status': AudioCallStatus.accepted,
      'answered_at': DateTime.now().millisecondsSinceEpoch,
    });
    await OnlinePresenceService.instance.setInCall(myUser!.id!, true);

    Get.to(() => AudioCallScreen(
      call: call,
      isCaller: false,
    ));
  }

  void _rejectCall(AudioCall call) async {
    Get.back();
    await _db
        .collection(FirebaseConst.audioCalls)
        .doc(call.docId)
        .update({'call_status': AudioCallStatus.rejected});
  }

  void createAudioRoom(String roomName) async {
    if (myUser?.id == null) return;
    if (myUser?.isHost != 1) {
      showSnackBar('Only hosts can create audio rooms');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final roomId = 'room_${myUser!.id}_$now';

    final room = AudioRoom(
      roomId: roomId,
      hostId: myUser!.id,
      hostName: myUser!.fullname ?? '',
      hostPhoto: myUser!.profilePhoto ?? '',
      roomName: roomName,
      maxParticipants: 8,
      participantIds: [myUser!.id!],
      createdAt: now,
      isActive: true,
    );

    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(myUser!.id.toString())
        .set(room.toJson());

    Get.to(() => AudioRoomScreen(
      room: room,
      isHost: true,
    ));
  }

  void joinAudioRoom(AudioRoom room) async {
    if (myUser?.id == null) return;

    final currentParticipants = room.participantIds ?? [];
    if (currentParticipants.contains(myUser!.id)) {
      // Already in room, just navigate
      Get.to(() => AudioRoomScreen(room: room, isHost: false));
      return;
    }

    if (currentParticipants.length >= (room.maxParticipants ?? 8)) {
      showSnackBar('Room is full');
      return;
    }

    await _db
        .collection(FirebaseConst.audioRooms)
        .doc(room.hostId.toString())
        .update({
      'participant_ids': FieldValue.arrayUnion([myUser!.id]),
    });

    Get.to(() => AudioRoomScreen(room: room, isHost: false));
  }

  void showCreateRoomDialog() {
    if (myUser?.isHost != 1) {
      showSnackBar('Only hosts can create audio rooms');
      return;
    }
    Get.to(() => const GoLiveSetupScreen(initialTab: 0));
  }
}
