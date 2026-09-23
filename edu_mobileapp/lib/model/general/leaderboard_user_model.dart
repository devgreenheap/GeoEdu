class LeaderboardUsersModel {
  bool? status;
  String? message;
  List<LeaderboardUser>? data;

  /// The requester's own row, returned even when they fall outside the page.
  LeaderboardUser? myRank;

  LeaderboardUsersModel({this.status, this.message, this.data, this.myRank});

  LeaderboardUsersModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((e) => LeaderboardUser.fromJson(e))
          .toList();
    }
    if (json['my_rank'] != null) {
      myRank = LeaderboardUser.fromJson(json['my_rank']);
    }
  }
}

class LeaderboardUser {
  int? rank;
  int? userId;
  String? username;
  String? fullname;
  String? profilePhoto;
  num? totalStars;
  bool? isHost;
  num? coinWallet;
  int? level;
  bool isFollowing;
  int? wins;
  int? battles;

  LeaderboardUser({
    this.rank,
    this.userId,
    this.username,
    this.fullname,
    this.profilePhoto,
    this.totalStars,
    this.isHost,
    this.coinWallet,
    this.level,
    this.isFollowing = false,
    this.wins,
    this.battles,
  });

  LeaderboardUser.fromJson(Map<String, dynamic> json)
      : isFollowing = json['is_following'] == true || json['is_following'] == 1 {
    rank = json['rank'];
    userId = json['user_id'];
    username = json['username'];
    fullname = json['fullname'];
    profilePhoto = json['profile_photo'];
    totalStars = json['total_stars'];
    isHost = json['is_host'] == true || json['is_host'] == 1;
    coinWallet = json['coin_wallet'];
    level = json['user_level'];
    wins = json['wins'];
    battles = json['battles'];
  }
}
