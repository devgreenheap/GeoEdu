class AudioCall {
  String? docId;
  int? callerId;
  int? calleeId;
  String? callerName;
  String? calleeName;
  String? callerPhoto;
  String? calleePhoto;
  String? callerDeviceToken;
  String? calleeDeviceToken;
  int? callerDeviceType;
  int? calleeDeviceType;
  String? roomId;
  String? callStatus;
  int? createdAt;
  int? answeredAt;
  int? endedAt;

  AudioCall({
    this.docId,
    this.callerId,
    this.calleeId,
    this.callerName,
    this.calleeName,
    this.callerPhoto,
    this.calleePhoto,
    this.callerDeviceToken,
    this.calleeDeviceToken,
    this.callerDeviceType,
    this.calleeDeviceType,
    this.roomId,
    this.callStatus,
    this.createdAt,
    this.answeredAt,
    this.endedAt,
  });

  AudioCall.fromJson(Map<String, dynamic> json) {
    docId = json['doc_id'];
    callerId = json['caller_id'];
    calleeId = json['callee_id'];
    callerName = json['caller_name'];
    calleeName = json['callee_name'];
    callerPhoto = json['caller_photo'];
    calleePhoto = json['callee_photo'];
    callerDeviceToken = json['caller_device_token'];
    calleeDeviceToken = json['callee_device_token'];
    callerDeviceType = json['caller_device_type'];
    calleeDeviceType = json['callee_device_type'];
    roomId = json['room_id'];
    callStatus = json['call_status'];
    createdAt = json['created_at'];
    answeredAt = json['answered_at'];
    endedAt = json['ended_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      'doc_id': docId,
      'caller_id': callerId,
      'callee_id': calleeId,
      'caller_name': callerName,
      'callee_name': calleeName,
      'caller_photo': callerPhoto,
      'callee_photo': calleePhoto,
      'caller_device_token': callerDeviceToken,
      'callee_device_token': calleeDeviceToken,
      'caller_device_type': callerDeviceType,
      'callee_device_type': calleeDeviceType,
      'room_id': roomId,
      'call_status': callStatus,
      'created_at': createdAt,
      'answered_at': answeredAt,
      'ended_at': endedAt,
    };
  }
}

class AudioCallStatus {
  static const String ringing = 'ringing';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String ended = 'ended';
  static const String missed = 'missed';
}
