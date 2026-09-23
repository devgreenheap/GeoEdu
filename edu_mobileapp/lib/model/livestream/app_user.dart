class AppUser {
  int? userId;
  String? username;
  String? fullname;
  String? profile;
  int? isVerify;
  String? identity;
  int? categoryId;
  int? level;

  AppUser(
      {this.userId,
      this.username,
      this.fullname,
      this.profile,
      this.isVerify,
      this.identity,
      this.categoryId,
      this.level});

  AppUser.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    identity = json['identity'];
    username = json['username'];
    fullname = json['fullname'];
    profile = json['profile'];
    isVerify = json['is_verify'];
    categoryId = json['category_id'];
    level = json['level'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['identity'] = identity;
    data['username'] = username;
    data['fullname'] = fullname;
    data['profile'] = profile;
    data['is_verify'] = isVerify;
    data['category_id'] = categoryId;
    data['level'] = level;
    return data;
  }
}


