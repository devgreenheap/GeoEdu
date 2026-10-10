import 'package:get_storage/get_storage.dart';

class LiveHistoryResponse {
  bool? status;
  String? message;
  List<LiveHistory>? data;

  LiveHistoryResponse({this.status, this.message, this.data});

  factory LiveHistoryResponse.fromJson(Map<String, dynamic> json) {
    List<LiveHistory> list = [];
    final rawData = json['data'];
    if (rawData is List) {
      for (var x in rawData) {
        if (x is Map<String, dynamic>) {
          try {
            list.add(LiveHistory.fromJson(x));
          } catch (_) {}
        }
      }
    }
    return LiveHistoryResponse(
      status: json['status'] == true || json['status'] == 1,
      message: json['message']?.toString(),
      data: list,
    );
  }
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

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory LiveHistory.fromJson(Map<String, dynamic> json) => LiveHistory(
        id: _toInt(json['id']),
        userId: _toInt(json['user_id']),
        title: json['title']?.toString(),
        thumbnail: json['thumbnail']?.toString(),
        videoUrl: json['video_url']?.toString(),
        viewerCount: _toInt(json['viewer_count']),
        duration: _toInt(json['duration']),
        totalGifts: _toInt(json['total_gifts']),
        totalComments: _toInt(json['total_comments']),
        followersGained: _toInt(json['followers_gained']),
        starsEarned: _toInt(json['stars_earned']),
        categoryName: json['category_name']?.toString(),
        startedAt: json['started_at']?.toString(),
        endedAt: json['ended_at']?.toString(),
        status: _toInt(json['status']),
        createdAt: json['created_at']?.toString(),
        categoryId: _toInt(json['category_id']),
        hostUsername: json['host_username']?.toString(),
        hostFullname: json['host_fullname']?.toString(),
        hostProfilePhoto: json['host_profile_photo']?.toString(),
        hostIsVerify: _toInt(json['host_is_verify']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'thumbnail': thumbnail,
        'video_url': videoUrl,
        'viewer_count': viewerCount,
        'duration': duration,
        'total_gifts': totalGifts,
        'total_comments': totalComments,
        'followers_gained': followersGained,
        'stars_earned': starsEarned,
        'category_name': categoryName,
        'started_at': startedAt,
        'ended_at': endedAt,
        'status': status,
        'created_at': createdAt,
        'category_id': categoryId,
        'host_username': hostUsername,
        'host_fullname': hostFullname,
        'host_profile_photo': hostProfilePhoto,
        'host_is_verify': hostIsVerify,
      };

  /// A session is still live until the backend flips its status on end.
  bool get isLive => status == 1;

  String get timeAgo {
    final raw = startedAt ?? createdAt;
    if (raw == null) return '';
    try {
      final date = DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceAll(' ', 'T'));
      if (date == null) return '';
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
      return DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceAll(' ', 'T'));
    } catch (_) {
      return null;
    }
  }
}

/// Local persistent storage for completed live sessions to ensure zero data loss
class LiveHistoryStorage {
  static const _keyPrefix = 'completed_live_sessions_';

  static List<LiveHistory> getLocalSessions(int userId) {
    try {
      final storage = GetStorage('geoedu');
      List? raw;
      if (userId > 0) {
        raw = storage.read('$_keyPrefix$userId');
      }
      if (raw == null || raw.isEmpty) {
        raw = storage.read('${_keyPrefix}current');
      }
      if (raw is List) {
        return raw
            .map((item) => LiveHistory.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static void saveLiveSession(LiveHistory live) {
    final uid = live.userId ?? 0;
    try {
      final storage = GetStorage('geoedu');
      final current = getLocalSessions(uid);
      // Deduplicate by ID or start timestamp
      final updated = [
        live,
        ...current.where((e) =>
            e.id != live.id &&
            (e.startedAt == null || e.startedAt != live.startedAt)),
      ];
      final toSave = updated.take(50).map((e) => e.toJson()).toList();
      if (uid > 0) {
        storage.write('$_keyPrefix$uid', toSave);
      }
      storage.write('${_keyPrefix}current', toSave);
    } catch (_) {}
  }

  static void removeSession(int userId, int liveId) {
    try {
      final storage = GetStorage('geoedu');
      final current = getLocalSessions(userId);
      final updated = current.where((e) => e.id != liveId).map((e) => e.toJson()).toList();
      if (userId > 0) {
        storage.write('$_keyPrefix$userId', updated);
      }
      storage.write('${_keyPrefix}current', updated);
    } catch (_) {}
  }
}
