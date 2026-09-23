class LevelBadgesModel {
  bool? status;
  String? message;
  List<LevelBadge>? data;

  LevelBadgesModel({this.status, this.message, this.data});

  LevelBadgesModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List).map((e) => LevelBadge.fromJson(e)).toList();
    }
  }
}

class LevelBadge {
  int? id;
  String? title;
  int? startLevel;
  int? endLevel;
  String? image;

  LevelBadge({this.id, this.title, this.startLevel, this.endLevel, this.image});

  LevelBadge.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    startLevel = json['start_level'];
    endLevel = json['end_level'];
    image = json['image'];
  }
}
