class LiveStreamApiModel {
  bool? status;
  String? message;
  LiveStreamApiData? data;

  LiveStreamApiModel({this.status, this.message, this.data});

  factory LiveStreamApiModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamApiModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? LiveStreamApiData.fromJson(json['data'])
          : null,
    );
  }
}

class LiveStreamApiData {
  int? id;
  int? categoryId;
  int? subCategoryId;
  int? topicId;
  String? title;
  String? startedAt;
  String? endedAt;
  int? duration;

  LiveStreamApiData({
    this.id,
    this.categoryId,
    this.subCategoryId,
    this.topicId,
    this.title,
    this.startedAt,
    this.endedAt,
    this.duration,
  });

  factory LiveStreamApiData.fromJson(Map<String, dynamic> json) {
    return LiveStreamApiData(
      id: json['id'],
      categoryId: json['category_id'],
      subCategoryId: json['sub_category_id'],
      topicId: json['topic_id'],
      title: json['title'],
      startedAt: json['started_at'],
      endedAt: json['ended_at'],
      duration: json['duration'],
    );
  }
}
