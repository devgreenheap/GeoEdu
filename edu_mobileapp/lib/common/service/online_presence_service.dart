import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/model/audio_call/online_user.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/firebase_const.dart';

class OnlinePresenceService {
  OnlinePresenceService._();

  static final OnlinePresenceService instance = OnlinePresenceService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;

  Future<void> goOnline(User user) async {
    if (user.id == null) return;
    try {
      final onlineUser = OnlineUser(
        userId: user.id,
        fullname: user.fullname ?? '',
        username: user.username ?? '',
        profilePhoto: user.profilePhoto ?? '',
        isVerify: user.isVerify ?? 0,
        isHost: user.isHost ?? 0,
        deviceToken: user.deviceToken ?? '',
        deviceType: Platform.isIOS ? 1 : 0,
        isOnline: true,
        isInCall: false,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      );

      await _db
          .collection(FirebaseConst.onlineUsers)
          .doc(user.id.toString())
          .set(onlineUser.toJson());

      _startHeartbeat(user.id!);
      Loggers.success('OnlinePresence: User ${user.id} is now online');
    } catch (e) {
      Loggers.error('OnlinePresence goOnline error: $e');
    }
  }

  void _startHeartbeat(int userId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _db
          .collection(FirebaseConst.onlineUsers)
          .doc(userId.toString())
          .update({
        'last_seen': DateTime.now().millisecondsSinceEpoch,
        'is_online': true,
      }).catchError((e) {
        Loggers.error('OnlinePresence heartbeat error: $e');
      });
    });
  }

  Future<void> goOffline(int userId) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    try {
      await _db
          .collection(FirebaseConst.onlineUsers)
          .doc(userId.toString())
          .update({
        'is_online': false,
        'last_seen': DateTime.now().millisecondsSinceEpoch,
      });
      Loggers.success('OnlinePresence: User $userId is now offline');
    } catch (e) {
      Loggers.error('OnlinePresence goOffline error: $e');
    }
  }

  Future<void> setInCall(int userId, bool inCall) async {
    try {
      await _db
          .collection(FirebaseConst.onlineUsers)
          .doc(userId.toString())
          .update({'is_in_call': inCall});
    } catch (e) {
      Loggers.error('OnlinePresence setInCall error: $e');
    }
  }
}
