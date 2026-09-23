class LiveHistoryResponse {
  bool? status;
  String? message;
  List<LiveHistory>? data;

  LiveHistoryResponse({this.status, this.message, this.data});

  factory LiveHistoryResponse.fromJson(Map<String, dynamic> json) =>
      LiveHistoryResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] == null
            ? []
            : List<LiveHistory>.from(
                json['data'].map((x) => LiveHistory.fromJson(x))),
      );
}

class LiveHistory {
  int? id;
  int? userId;
  String? title;
  String? thumbnail;
  String? videoUrl;
  int? viewerCount;
  int? duration;
  int? totalGifts;
  int? totalComments;
  int? followersGained;
  int? starsEarned;
  String? categoryName;
  String? startedAt;
  String? endedAt;
  int? status;
  String? createdAt;
  int? categoryId;
  String? hostUsername;
  String? hostFullname;
  String? hostProfilePhoto;
  int? hostIsVerify;

  LiveHistory({
    this.id,
    this.userId,
    this.title,
    this.thumbnail,
    this.videoUrl,
    this.viewerCount,
    this.duration,
    this.totalGifts,
    this.totalComments,
    this.followersGained,
    this.starsEarned,
    this.categoryName,
    this.startedAt,
    this.endedAt,
    this.status,
    this.createdAt,
    this.categoryId,
    this.hostUsername,
    this.hostFullname,
    this.hostProfilePhoto,
    this.hostIsVerify,
  });

  factory LiveHistory.fromJson(Map<String, dynamic> json) => LiveHistory(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        thumbnail: json['thumbnail'],
        videoUrl: json['video_url'],
        viewerCount: json['viewer_count'],
        duration: json['duration'],
        totalGifts: json['total_gifts'],
        totalComments: json['total_comments'],
        followersGained: json['followers_gained'],
        starsEarned: json['stars_earned'],
        categoryName: json['category_name'],
        startedAt: json['started_at'],
        endedAt: json['ended_at'],
        status: json['status'],
        createdAt: json['created_at'],
        categoryId: json['category_id'],
        hostUsername: json['host_username'],
        hostFullname: json['host_fullname'],
        hostProfilePhoto: json['host_profile_photo'],
        hostIsVerify: json['host_is_verify'],
      );

  /// A session is still live until the backend flips its status on end.
  bool get isLive => status == 1;

  String get timeAgo {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt!);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  String get durationFormatted {
    if (duration == null || duration == 0) return '0:00';
    final mins = duration! ~/ 60;
    final secs = duration! % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// The date this session started on, for date-grouping — falls back to
  /// createdAt if startedAt wasn't returned for some reason.
  DateTime? get sessionDate {
    final raw = startedAt ?? createdAt;
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
