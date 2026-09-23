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

  Livestream(
      {this.watchingCount,
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
      this.battleDuration = AppRes.battleDurationInMinutes});

  Livestream.fromJson(Map<String, dynamic> json) {
    type = LivestreamType.fromString(json['type']);
    battleType = BattleType.fromString(json['battle_type']);
    watchingCount = json['watching_count'];
    description = json['description'];
    isRestrictToJoin = json['is_restrict_to_join'];
    hostViewID = json['host_view_id'];
    roomID = json['room_id'];
    likeCount = json['like_count'];
    hostId = json['host_id'];
    coHostIds = json['co-host_ids'].cast<int>();
    createdAt = json['created_at'];
    battleCreatedAt = json['battle_created_at'];
    isDummyLive = json['is_dummy_live'];
    dummyUserLink = json['dummy_user_link'];
    battleDuration = json['battle_duration'];
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    subCategoryId = json['sub_category_id'];
    subCategoryName = json['sub_category_name'];
    topicId = json['topic_id'];
    topicName = json['topic_name'];
    languageId = json['language_id'];
    languageName = json['language_name'];
    hashtag = json['hashtag'];
    streamMode = json['stream_mode'];
    screenshotDisabled = json['screenshot_disabled'];
    favouriteGiftId = json['favourite_gift_id'];
    isAutoMode = json['is_auto_mode'];
    thumbnailUrl = json['thumbnail_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
