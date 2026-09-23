class AudioRoom {
  String? roomId;
  int? hostId;
  String? hostName;
  String? hostPhoto;
  String? roomName;
  int? maxParticipants;
  List<int>? participantIds;
  List<int>? speakerIds;
  List<int>? requestIds;
  int? createdAt;
  bool? isActive;
  int? languageId;
  String? languageName;
  bool? isAutoMode;
  String? chatRoomField;
  String? hashtag;
  List<String>? musicUrls;
  String? backgroundImage;
  int? favouriteGiftId;
  bool? isRoyalMode;
  int? themeIndex;
  List<int>? mutedSpeakerIds;
  List<int>? lockedSeatIndices;
  String? pinnedComment;
  int? likeCount;

  // PK Battle (audio-host-vs-audio-host)
  int? pkOpponentId;
  String? pkStatus; // 'invited', 'running', 'ended'
  int? pkStartedAt;
  int? pkDurationMinutes;
  int? pkCoins;
  int? pkInviteFrom;

  AudioRoom({
    this.roomId,
    this.hostId,
    this.hostName,
    this.hostPhoto,
    this.roomName,
    this.maxParticipants,
    this.participantIds,
    this.speakerIds,
    this.requestIds,
    this.createdAt,
    this.isActive,
    this.languageId,
    this.languageName,
    this.isAutoMode,
    this.chatRoomField,
    this.hashtag,
    this.musicUrls,
    this.backgroundImage,
    this.favouriteGiftId,
    this.isRoyalMode,
    this.themeIndex,
    this.mutedSpeakerIds,
    this.lockedSeatIndices,
    this.pinnedComment,
    this.likeCount,
    this.pkOpponentId,
    this.pkStatus,
    this.pkStartedAt,
    this.pkDurationMinutes,
    this.pkCoins,
    this.pkInviteFrom,
  });

  AudioRoom.fromJson(Map<String, dynamic> json) {
    roomId = json['room_id'];
    hostId = json['host_id'];
    hostName = json['host_name'];
    hostPhoto = json['host_photo'];
    roomName = json['room_name'];
    maxParticipants = json['max_participants'];
    participantIds = json['participant_ids'] != null
        ? List<int>.from(json['participant_ids'].map((x) => x))
        : [];
    speakerIds = json['speaker_ids'] != null
        ? List<int>.from(json['speaker_ids'].map((x) => x))
        : [];
    requestIds = json['request_ids'] != null
        ? List<int>.from(json['request_ids'].map((x) => x))
        : [];
    createdAt = json['created_at'];
    isActive = json['is_active'];
    languageId = json['language_id'];
    languageName = json['language_name'];
    isAutoMode = json['is_auto_mode'];
    chatRoomField = json['chat_room_field'];
    hashtag = json['hashtag'];
    // Rooms created before multi-song support stored a single 'music_url'
    // string — keep reading those so existing/live rooms don't lose audio.
    musicUrls = json['music_urls'] != null
        ? List<String>.from(json['music_urls'].map((x) => x))
        : (json['music_url'] != null && (json['music_url'] as String).isNotEmpty
            ? [json['music_url'] as String]
            : []);
    backgroundImage = json['background_image'];
    favouriteGiftId = json['favourite_gift_id'];
    isRoyalMode = json['is_royal_mode'];
    themeIndex = json['theme_index'];
    mutedSpeakerIds = json['muted_speaker_ids'] != null
        ? List<int>.from(json['muted_speaker_ids'].map((x) => x))
        : [];
    lockedSeatIndices = json['locked_seat_indices'] != null
        ? List<int>.from(json['locked_seat_indices'].map((x) => x))
        : [];
    pinnedComment = json['pinned_comment'];
    likeCount = json['like_count'];
    pkOpponentId = json['pk_opponent_id'];
    pkStatus = json['pk_status'];
    pkStartedAt = json['pk_started_at'];
    pkDurationMinutes = json['pk_duration_minutes'];
    pkCoins = json['pk_coins'];
    pkInviteFrom = json['pk_invite_from'];
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'host_id': hostId,
      'host_name': hostName,
      'host_photo': hostPhoto,
      'room_name': roomName,
      'max_participants': maxParticipants,
      'participant_ids': participantIds,
      'speaker_ids': speakerIds,
      'request_ids': requestIds,
      'created_at': createdAt,
      'is_active': isActive,
      'language_id': languageId,
      'language_name': languageName,
      'is_auto_mode': isAutoMode,
      'chat_room_field': chatRoomField,
      'hashtag': hashtag,
      'music_urls': musicUrls,
      'background_image': backgroundImage,
      'favourite_gift_id': favouriteGiftId,
      'is_royal_mode': isRoyalMode,
      'theme_index': themeIndex,
      'muted_speaker_ids': mutedSpeakerIds,
      'locked_seat_indices': lockedSeatIndices,
      'pinned_comment': pinnedComment,
      'like_count': likeCount,
      'pk_opponent_id': pkOpponentId,
      'pk_status': pkStatus,
      'pk_started_at': pkStartedAt,
      'pk_duration_minutes': pkDurationMinutes,
      'pk_coins': pkCoins,
      'pk_invite_from': pkInviteFrom,
    };
  }
}
