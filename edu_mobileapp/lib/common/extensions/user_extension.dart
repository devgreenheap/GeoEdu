import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/model/user_model/user_model.dart';

extension UserExtension on User {
  AppUser get appUser {
    return AppUser(
        username: username,
        userId: id,
        profile: profilePhoto,
        fullname: fullname,
        isVerify: isVerify,
        identity: identity,
        categoryId: categoryId,
        level: level);
  }

  Livestream livestream({
    required LivestreamType type,
    required int time,
    String? description,
    int? restrictToJoin = 1,
    int? hostViewId = -1,
    int? isDummyLive = 0,
    String? dummyUserLink = '',
    int? categoryId,
    String? categoryName,
    int? subCategoryId,
    String? subCategoryName,
    int? topicId,
    String? topicName,
    int? languageId,
    String? languageName,
    String? hashtag,
    String? streamMode,
    bool? isAutoMode,
    String? thumbnailUrl,
  }) {
    return Livestream(
        description: (description ?? '').trim(),
        isRestrictToJoin: restrictToJoin,
        type: type,
        watchingCount: 0,
        roomID: id.toString(),
        hostViewID: hostViewId,
        likeCount: 0,
        coHostIds: [],
        hostId: id,
        createdAt: time,
        battleType: BattleType.initiate,
        isDummyLive: isDummyLive,
        dummyUserLink: dummyUserLink,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        subCategoryId: subCategoryId,
        subCategoryName: subCategoryName,
        topicId: topicId,
        topicName: topicName,
        languageId: languageId,
        languageName: languageName,
        hashtag: hashtag,
        streamMode: streamMode,
        isAutoMode: isAutoMode,
        thumbnailUrl: thumbnailUrl,
        screenshotDisabled: disableScreenshotStatus);
  }

  LivestreamUserState streamState(
      {LivestreamUserType stateType = LivestreamUserType.audience,
      required int time}) {
    return LivestreamUserState(
        type: stateType,
        userId: id ?? -1,
        totalBattleCoin: 0,
        currentBattleCoin: 0,
        liveCoin: 0,
        followersGained: [],
        joinStreamTime: time);
  }
}
