class AgentUsersModel {
  bool? status;
  String? message;
  List<AgentUser>? data;

  AgentUsersModel({this.status, this.message, this.data});

  AgentUsersModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((e) => AgentUser.fromJson(e))
          .toList();
    }
  }
}

class AgentUser {
  int? id;
  String? fullname;
  String? username;
  String? profilePhoto;
  String? userEmail;
  String? userMobileNo;
  num? coinWallet;
  num? coinCollectedLifetime;
  int? level;
  int? isHost;
  int? isAgent;
  int? hostRequested;
  num? followerCount;
  num? followingCount;
  String? createdAt;
  num? isFreez;
  int? screenshotDisableRequested;
  int? screenshotDisableStatus;
  int? screenshotDisableRequestId;

  AgentUser({
    this.id,
    this.fullname,
    this.username,
    this.profilePhoto,
    this.userEmail,
    this.userMobileNo,
    this.coinWallet,
    this.coinCollectedLifetime,
    this.level,
    this.isHost,
    this.isAgent,
    this.hostRequested,
    this.followerCount,
    this.followingCount,
    this.createdAt,
    this.isFreez,
    this.screenshotDisableRequested,
    this.screenshotDisableStatus,
    this.screenshotDisableRequestId,
  });

  AgentUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fullname = json['fullname'];
    username = json['username'];
    profilePhoto = json['profile_photo'];
    userEmail = json['user_email'];
    userMobileNo = json['user_mobile_no'];
    coinWallet = json['coin_wallet'];
    coinCollectedLifetime = json['coin_collected_lifetime'];
    level = json['level'];
    isHost = json['is_host'];
    isAgent = json['is_agent'];
    hostRequested = json['host_requested'];
    followerCount = json['follower_count'];
    followingCount = json['following_count'];
    createdAt = json['created_at'];
    isFreez = json['is_freez'];
    screenshotDisableRequested = json['screenshot_disable_requested'];
    screenshotDisableStatus = json['screenshot_disable_status'];
    screenshotDisableRequestId = json['screenshot_disable_request_id'];
  }
}
