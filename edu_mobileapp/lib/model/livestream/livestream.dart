import 'package:get/get.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/utilities/app_res.dart';

class Livestream {
  int? watchingCount;
  String? description;
  LivestreamType? type;
  BattleType? battleType;
  int battleDuration = AppRes.battleDurationInMinutes;
  int? isRestrictToJoin;
  int? hostViewID;
  String? roomID;
  int? likeCount;
  int? hostId;
  List<int>? coHostIds;
  AppUser? hostUser;
  List<AppUser>? coHostUsers;
  int? createdAt;
  int? battleCreatedAt;
  int? isDummyLive;
  String? dummyUserLink;
  int? categoryId;
  String? categoryName;
  int? subCategoryId;
  String? subCategoryName;
  int? topicId;
  String? topicName;
  int? languageId;
  String? languageName;
  String? hashtag;
  String? streamMode; // 'video_room', 'direct_call', 'pk_battle'
  int? screenshotDisabled;
  int? favouriteGiftId;
  bool? isAutoMode;
  String? thumbnailUrl;
  String? pinnedComment;
  bool? isActive;
  int? pkOpponentId;
  List<int>? pkInvitedUserIds;
  int? targetDiamonds;
  int? favouriteGiftTarget;
  int? maxParticipants;
  int? battleRound;
  Map<String, dynamic>? lastRoundResult;

  Livestream(
      {this.watchingCount,
      this.isActive,
      this.description,
      this.type,
      this.battleType,
      this.isRestrictToJoin,
      this.hostViewID,
      this.roomID,
      this.likeCount,
      this.hostId,
      this.coHostIds,
      this.createdAt,
      this.battleCreatedAt,
      this.isDummyLive,
      this.dummyUserLink,
      this.categoryId,
      this.categoryName,
      this.subCategoryId,
      this.subCategoryName,
      this.topicId,
      this.topicName,
      this.languageId,
      this.languageName,
      this.hashtag,
      this.streamMode,
      this.screenshotDisabled,
      this.favouriteGiftId,
      this.isAutoMode,
      this.thumbnailUrl,
      this.pinnedComment,
      this.pkOpponentId,
      this.pkInvitedUserIds,
      this.targetDiamonds,
      this.favouriteGiftTarget,
      this.maxParticipants = 7,
      this.battleDuration = AppRes.battleDurationInMinutes,
      this.battleRound = 1,
      this.lastRoundResult});

  Livestream.fromJson(Map<String, dynamic> json) {
    type = LivestreamType.fromString(json['type']);
    battleType = BattleType.fromString(json['battle_type']);
    watchingCount = json['watching_count'] is num ? (json['watching_count'] as num).toInt() : 0;
    description = json['description']?.toString();
    isRestrictToJoin = json['is_restrict_to_join'] is num ? (json['is_restrict_to_join'] as num).toInt() : null;
    hostViewID = json['host_view_id'] is num ? (json['host_view_id'] as num).toInt() : null;
    roomID = json['room_id']?.toString();
    likeCount = json['like_count'] is num ? (json['like_count'] as num).toInt() : 0;
    hostId = json['host_id'] is num ? (json['host_id'] as num).toInt() : null;
    final rawCoHosts = json['co-host_ids'];
    if (rawCoHosts is List) {
      coHostIds = rawCoHosts.whereType<num>().map((e) => e.toInt()).toList();
    } else {
      coHostIds = [];
    }
    createdAt = json['created_at'] is num ? (json['created_at'] as num).toInt() : null;
    battleCreatedAt = json['battle_created_at'] is num ? (json['battle_created_at'] as num).toInt() : null;
    isDummyLive = json['is_dummy_live'] is num ? (json['is_dummy_live'] as num).toInt() : null;
    dummyUserLink = json['dummy_user_link']?.toString();
    battleDuration = json['battle_duration'] is num ? (json['battle_duration'] as num).toInt() : AppRes.battleDurationInMinutes;
    battleRound = json['battle_round'] is num ? (json['battle_round'] as num).toInt() : 1;
    if (json['last_round_result'] is Map) {
      lastRoundResult = Map<String, dynamic>.from(json['last_round_result']);
    } else {
      lastRoundResult = null;
    }
    categoryId = json['category_id'] is num ? (json['category_id'] as num).toInt() : null;
    categoryName = json['category_name']?.toString();
    subCategoryId = json['sub_category_id'] is num ? (json['sub_category_id'] as num).toInt() : null;
    subCategoryName = json['sub_category_name']?.toString();
    topicId = json['topic_id'] is num ? (json['topic_id'] as num).toInt() : null;
    topicName = json['topic_name']?.toString();
    languageId = json['language_id'] is num ? (json['language_id'] as num).toInt() : null;
    languageName = json['language_name']?.toString();
    hashtag = json['hashtag']?.toString();
    streamMode = json['stream_mode']?.toString();
    screenshotDisabled = json['screenshot_disabled'] is num ? (json['screenshot_disabled'] as num).toInt() : null;
    favouriteGiftId = json['favourite_gift_id'] is num ? (json['favourite_gift_id'] as num).toInt() : null;
    isAutoMode = json['is_auto_mode'] as bool?;
    thumbnailUrl = json['thumbnail_url']?.toString();
    pinnedComment = json['pinned_comment']?.toString();
    isActive = json['is_active'] as bool?;
    pkOpponentId = json['pk_opponent_id'] is num ? (json['pk_opponent_id'] as num).toInt() : null;
    final rawPkInvites = json['pk_invited_user_ids'];
    if (rawPkInvites is List) {
      pkInvitedUserIds = rawPkInvites.whereType<num>().map((e) => e.toInt()).toList();
    } else {
      pkInvitedUserIds = [];
    }
    targetDiamonds = json['target_diamonds'] is num ? (json['target_diamonds'] as num).toInt() : null;
    favouriteGiftTarget = json['favourite_gift_target'] is num ? (json['favourite_gift_target'] as num).toInt() : null;
    maxParticipants = json['max_participants'] is num
        ? (json['max_participants'] as num).toInt()
        : (json['max_seats'] is num ? (json['max_seats'] as num).toInt() : 7);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (isActive != null) {
      data['is_active'] = isActive;
    }
    data['watching_count'] = watchingCount;
    data['description'] = description;
    data['type'] = type?.value;
    data['battle_type'] = battleType?.value;
    data['is_restrict_to_join'] = isRestrictToJoin;
    data['host_view_id'] = hostViewID;
    data['room_id'] = roomID;
    data['like_count'] = likeCount;
    data['host_id'] = hostId;
    data['co-host_ids'] = coHostIds;
    data['created_at'] = createdAt;
    data['battle_created_at'] = battleCreatedAt;
    data['is_dummy_live'] = isDummyLive;
    data['dummy_user_link'] = dummyUserLink;
    data['battle_duration'] = battleDuration;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['sub_category_id'] = subCategoryId;
    data['sub_category_name'] = subCategoryName;
    data['topic_id'] = topicId;
    data['topic_name'] = topicName;
    data['language_id'] = languageId;
    data['language_name'] = languageName;
    data['hashtag'] = hashtag;
    data['stream_mode'] = streamMode;
    data['screenshot_disabled'] = screenshotDisabled;
    data['favourite_gift_id'] = favouriteGiftId;
    data['is_auto_mode'] = isAutoMode;
    data['thumbnail_url'] = thumbnailUrl;
    data['pinned_comment'] = pinnedComment;
    data['pk_opponent_id'] = pkOpponentId;
    data['pk_invited_user_ids'] = pkInvitedUserIds;
    if (targetDiamonds != null) data['target_diamonds'] = targetDiamonds;
    if (favouriteGiftTarget != null) data['favourite_gift_target'] = favouriteGiftTarget;
    if (maxParticipants != null) {
      data['max_participants'] = maxParticipants;
      data['max_seats'] = maxParticipants;
    }
    if (battleRound != null) data['battle_round'] = battleRound;
    if (lastRoundResult != null) data['last_round_result'] = lastRoundResult;
    return data;
  }

  List<AppUser> getAllUsers(List<AppUser> users) {
    AppUser? hostUser =
        users.firstWhereOrNull((element) => element.userId == hostId);
    final coHostUsers = coHostIds
            ?.map((id) => users.firstWhereOrNull((user) => user.userId == id))
            .whereType<AppUser>()
            .toList() ??
        [];

    final allUsers = [if (hostUser != null) hostUser, ...coHostUsers];
    return allUsers;
  }

  AppUser? getHostUser(List<AppUser> users) {
    final controller = Get.find<FirebaseFirestoreController>();
    AppUser? hostUser = controller.users
        .firstWhereOrNull((element) => element.userId == hostId);
    return hostUser;
  }

  List<AppUser> getCoHostUsers(List<AppUser> users) {
    final coHostUsers = coHostIds
            ?.map((id) => users.firstWhereOrNull((user) => user.userId == id))
            .whereType<AppUser>()
            .toList() ??
        [];
    return coHostUsers;
  }
}

enum LivestreamType {
  livestream('LIVESTREAM'),
  battle('BATTLE'),
  dummy('DUMMY');

  final String value;

  const LivestreamType(this.value);

  static LivestreamType fromString(String value) {
    return LivestreamType.values.firstWhereOrNull((e) => e.value == value) ??
        LivestreamType.livestream;
  }
}

enum BattleType {
  initiate('INITIATE'),
  waiting('WAITING'),
  running('RUNNING'),
  end('END');

  final String value;

  const BattleType(this.value);

  static BattleType fromString(String? value) {
    return BattleType.values.firstWhereOrNull((e) => e.value == value) ??
        BattleType.initiate;
  }
}
