import 'dart:convert';

import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/api_service.dart';
import 'package:geoedu/common/service/utils/params.dart';
import 'package:geoedu/common/service/utils/web_service.dart';
import 'package:geoedu/model/general/agent_commission_model.dart';
import 'package:geoedu/model/general/banner_model.dart';
import 'package:geoedu/model/general/agent_users_model.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/city_model.dart';
import 'package:geoedu/model/general/coupon_model.dart';
import 'package:geoedu/model/general/file_path_model.dart';
import 'package:geoedu/model/general/interest_model.dart';
import 'package:geoedu/model/general/languages_model.dart';
import 'package:geoedu/model/general/country_state_model.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/model/general/location_place_model.dart';
import 'package:geoedu/model/general/place_detail.dart';
import 'package:geoedu/model/general/level_badge_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/model/general/support_ticket_model.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/utilities/app_res.dart';

class CommonService {
  CommonService._();

  static final CommonService instance = CommonService._();

  Future<bool> fetchGlobalSettings() async {
    SettingModel settingsModel = await ApiService.instance.call(
        url: WebService.setting.fetchSettings,
        fromJson: SettingModel.fromJson,
        cancelAuthToken: true);

    var setting = settingsModel.data;
    if (setting != null) {
      SessionManager.instance.setSettings(setting);
      return true;
    }
    return false;
  }

  Future<FilePathModel> uploadFileGivePath(XFile files,
      {Function(double percentage)? onProgress}) async {
    FilePathModel model = await ApiService.instance.multiPartCallApi(
      url: WebService.setting.uploadFileGivePath,
      filesMap: {
        Params.file: [files]
      },
      onProgress: onProgress,
      fromJson: FilePathModel.fromJson,
    );

    return model;
  }

  Future<StatusModel> deleteFile(String filePath) async {
    StatusModel model = await ApiService.instance.call(
        url: WebService.setting.deleteFile,
        param: {Params.filePath: filePath},
        fromJson: StatusModel.fromJson);
    return model;
  }

  Future<CategorySubCategoryTopicModel> fetchCategorySubCategoryTopic() async {
    CategorySubCategoryTopicModel model = await ApiService.instance.call(
      url: WebService.setting.fetchCategorySubCategoryTopic,
      fromJson: CategorySubCategoryTopicModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<LanguagesModel> fetchLanguages() async {
    LanguagesModel model = await ApiService.instance.call(
      url: WebService.setting.fetchLanguages,
      fromJson: LanguagesModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<InterestsModel> fetchInterests() async {
    InterestsModel model = await ApiService.instance.call(
      url: WebService.setting.fetchInterests,
      fromJson: InterestsModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<CountryStateModel> fetchCountryStateList({int? countryId, bool includeStates = true}) async {
    CountryStateModel model = await ApiService.instance.call(
      url: WebService.setting.fetchCountryStateList,
      param: {
        if (countryId != null) 'country_id': countryId,
        'include_states': includeStates ? 1 : 0,
      },
      fromJson: CountryStateModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<CityModel> fetchCityList({required int stateId}) async {
    CityModel model = await ApiService.instance.call(
      url: WebService.setting.fetchCityList,
      param: {
        'state_id': stateId,
      },
      fromJson: CityModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<LevelBadgesModel> fetchLevelBadges() async {
    LevelBadgesModel model = await ApiService.instance.call(
      url: WebService.setting.fetchLevelBadges,
      fromJson: LevelBadgesModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<AgentUsersModel> fetchAgentUsers({int limit = 20, int? lastItemId}) async {
    AgentUsersModel model = await ApiService.instance.call(
      url: WebService.giftWallet.fetchAgentUsers,
      param: {
        Params.limit: limit.toString(),
        Params.lastItemId: lastItemId,
      },
      fromJson: AgentUsersModel.fromJson,
    );
    return model;
  }

  Future<AgentCommissionModel> fetchAgentCommission({int limit = 20, int? lastItemId}) async {
    AgentCommissionModel model = await ApiService.instance.call(
      url: WebService.giftWallet.fetchAgentCommission,
      param: {
        Params.limit: limit.toString(),
        Params.lastItemId: lastItemId,
      },
      fromJson: AgentCommissionModel.fromJson,
    );
    return model;
  }

  Future<StatusModel> approveScreenshotDisable({required int requestId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.giftWallet.approveScreenshotDisable,
      param: {'request_id': requestId},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<StatusModel> approveHost({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.giftWallet.approveHost,
      param: {Params.userId: userId},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<CouponsModel> fetchCoupons({int limit = 20}) async {
    CouponsModel model = await ApiService.instance.call(
      url: WebService.giftWallet.fetchCoupons,
      param: {Params.limit: limit.toString()},
      fromJson: CouponsModel.fromJson,
    );
    return model;
  }

  Future<List<Places>> searchPlace({String title = ''}) async {
    Setting? settings = SessionManager.instance.getSettings();

    Map<String, String> header = {
      Params.authorization:
          'Bearer ${settings?.placeApiAccessToken ?? 'PLACE API ACCESS TOKEN EMPTY'}'
    };

    Map<String, dynamic> body = {
      Params.textQuery: title,
      Params.maxResultCount: '${AppRes.paginationLimit}'
    };

    Uri uri = Uri.parse(WebService.google.searchTextByPlace);

    Loggers.info(uri);
    Loggers.info(header);
    Loggers.info(body);

    Response response = await post(uri, headers: header, body: body);
    LocationPlaceModel model =
        LocationPlaceModel.fromJson(jsonDecode(response.body));

    Loggers.error(model.error?.toJson() ?? 'NO ERROR');
    Loggers.success(model.places?.map((e) => e.toJson()));

    return model.places ?? [];
  }

  Future<List<Places>> searchNearBy(
      {required double lat, required double lon}) async {
    Setting? settings = SessionManager.instance.getSettings();

    Map<String, String> header = {
      Params.authorization:
          'Bearer ${settings?.placeApiAccessToken ?? 'PLACE API ACCESS TOKEN EMPTY'}'
    };
    Map<String, dynamic> locationRestriction = {
      Params.circle: {
        Params.center: {Params.latitude: '$lat', Params.longitude: '$lon'},
        Params.radius: '${AppRes.nearBySearchRadius}'
      }
    };
    Map<String, dynamic> body = {
      Params.includedTypes: AppRes.nearbySearchTypes,
      Params.maxResultCount: AppRes.paginationLimit.toString(),
      Params.locationRestriction: locationRestriction
    };

    Uri uri = Uri.parse(WebService.google.searchNearByPlace(lat, lon));

    Loggers.info('URI : $uri');
    Loggers.info('HEADER : $header');
    Loggers.info('BODY : $body');
    Response response =
        await post(uri, headers: header, body: jsonEncode(body));
    LocationPlaceModel model =
        LocationPlaceModel.fromJson(jsonDecode(response.body));

    Loggers.error(model.error?.toJson() ?? 'NO ERROR');
    Loggers.success(model.places?.map((e) => e.toJson()));

    return model.places ?? [];
  }

  /// [type] is 'video' or 'audio'; omit it for the combined ranking.
  Future<LeaderboardUsersModel> fetchTopGifters({
    required String period,
    int limit = 20,
    String? type,
    int? languageId,
  }) async {
    LeaderboardUsersModel model = await ApiService.instance.call(
      url: WebService.giftWallet.fetchTopGifters,
      param: {
        Params.period: period,
        Params.limit: limit.toString(),
        if (type != null) Params.type: type,
        if (languageId != null) Params.languageId: languageId.toString(),
      },
      fromJson: LeaderboardUsersModel.fromJson,
    );
    return model;
  }

  Future<LeaderboardUsersModel> fetchTopHosts({
    required String period,
    int limit = 20,
    String? type,
    int? languageId,
  }) async {
    LeaderboardUsersModel model = await ApiService.instance.call(
      url: WebService.giftWallet.fetchTopHosts,
      param: {
        Params.period: period,
        Params.limit: limit.toString(),
        if (type != null) Params.type: type,
        if (languageId != null) Params.languageId: languageId.toString(),
      },
      fromJson: LeaderboardUsersModel.fromJson,
    );
    return model;
  }

  Future<LeaderboardUsersModel> fetchTopPkBattlePlayers({
    required String period,
    int limit = 20,
    String? mode,
  }) async {
    LeaderboardUsersModel model = await ApiService.instance.call(
      url: WebService.giftWallet.fetchTopPkBattlePlayers,
      param: {
        Params.period: period,
        Params.limit: limit.toString(),
        if (mode != null) Params.mode: mode,
      },
      fromJson: LeaderboardUsersModel.fromJson,
    );
    return model;
  }

  Future<PlaceDetail> getIPPlaceDetail() async {
    Map<String, dynamic> detail =
        await ApiService.instance.callGet(url: WebService.common.ipApi);
    return PlaceDetail.fromJson(detail);
  }

  Future<BannerModel> fetchBanners({String type = 'homepage'}) async {
    BannerModel model = await ApiService.instance.call(
      url: WebService.common.fetchBanners,
      param: {Params.type: type},
      fromJson: BannerModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<LiveHistoryResponse> fetchMyLives({int? lastItemId}) async {
    LiveHistoryResponse response = await ApiService.instance.call(
      url: WebService.giftWallet.fetchMyLives,
      param: {
        if (lastItemId != null) Params.lastItemId: lastItemId,
      },
      fromJson: LiveHistoryResponse.fromJson,
    );
    return response;
  }

  Future<LiveHistoryResponse> fetchRecordedLives({int? categoryId, int? lastItemId}) async {
    LiveHistoryResponse response = await ApiService.instance.call(
      url: WebService.giftWallet.fetchRecordedLives,
      param: {
        if (categoryId != null) 'category_id': categoryId,
        if (lastItemId != null) Params.lastItemId: lastItemId,
      },
      fromJson: LiveHistoryResponse.fromJson,
    );
    return response;
  }

  Future<StatusModel> deleteLiveHistory({required int liveStreamId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.giftWallet.deleteLiveHistory,
      param: {
        Params.liveStreamId: liveStreamId,
      },
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<StatusModel> createSupport({
    required String subject,
    required String message,
  }) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.common.createSupport,
      param: {
        'subject': subject,
        'message': message,
      },
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<SupportTicketModel> fetchMySupports({
    int limit = 20,
    int? lastItemId,
  }) async {
    SupportTicketModel model = await ApiService.instance.call(
      url: WebService.common.fetchMySupports,
      param: {
        Params.limit: limit.toString(),
        if (lastItemId != null) Params.lastItemId: lastItemId,
      },
      fromJson: SupportTicketModel.fromJson,
    );
    return model;
  }
}
