class OnlineUser {
  int? userId;
  String? fullname;
  String? username;
  String? profilePhoto;
  int? isVerify;
  int? isHost;
  String? deviceToken;
  int? deviceType;
  bool? isOnline;
  bool? isInCall;
  int? lastSeen;

  OnlineUser({
    this.userId,
    this.fullname,
    this.username,
    this.profilePhoto,
    this.isVerify,
    this.isHost,
    this.deviceToken,
    this.deviceType,
    this.isOnline,
    this.isInCall,
    this.lastSeen,
  });

  OnlineUser.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    fullname = json['fullname'];
    username = json['username'];
    profilePhoto = json['profile_photo'];
    isVerify = json['is_verify'];
    isHost = json['is_host'];
    deviceToken = json['device_token'];
    deviceType = json['device_type'];
    isOnline = json['is_online'];
    isInCall = json['is_in_call'];
    lastSeen = json['last_seen'];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fullname': fullname,
      'username': username,
      'profile_photo': profilePhoto,
      'is_verify': isVerify,
      'is_host': isHost,
      'device_token': deviceToken,
      'device_type': deviceType,
      'is_online': isOnline,
      'is_in_call': isInCall,
      'last_seen': lastSeen,
    };
  }
}
