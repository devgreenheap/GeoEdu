import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/api_service.dart';
import 'package:geoedu/common/service/utils/params.dart';
import 'package:geoedu/common/service/utils/web_service.dart';
import 'package:geoedu/model/diamond_purchase/diamond_faq_model.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_history_model.dart';
import 'package:geoedu/model/livestream/live_stream_api_model.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/model/diamond_purchase/diamond_wallet_model.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/model/gift_wallet/gift_profit_model.dart';
import 'package:geoedu/model/gift_wallet/withdraw_model.dart';
import 'package:geoedu/model/star_store/diamond_pack_model.dart';
import 'package:geoedu/model/star_score/star_score_model.dart';
import 'package:geoedu/model/star_store/diamond_info_model.dart';
import 'package:geoedu/model/star_store/effects_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/app_res.dart';

class GiftWalletService {
  GiftWalletService._();

  static final GiftWalletService instance = GiftWalletService._();

  Future<StatusModel> sendGift({int? userId, int? giftId, String? source}) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.sendGift,
        fromJson: StatusModel.fromJson,
        param: {
          Params.userId: userId,
          Params.giftId: giftId,
          if (source != null) Params.source: source,
        });
    return response;
  }

  Future<List<Withdraw>> fetchMyWithdrawalRequest({int? lastItemId}) async {
    WithdrawModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyWithdrawalRequest,
        fromJson: WithdrawModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          Params.lastItemId: lastItemId,
        });

    return response.data ?? [];
  }

  Future<StatusModel> submitWithdrawalRequest(
      {required String coins,
      required String gateway,
      required String account}) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.submitWithdrawalRequest,
        fromJson: StatusModel.fromJson,
        param: {
          Params.coins: coins,
          Params.gateway: gateway,
          Params.account: account
        });

    return response;
  }

  Future<List<DiamondPackModel>> fetchDiamondPackages() async {
    DiamondPackResponseModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchDiamondPackages,
        fromJson: DiamondPackResponseModel.fromJson);
    return response.data ?? [];
  }

  Future<UserModel> verifyDiamondPurchase({
    required String paymentId,
    String? orderId,
    String? signature,
    required int diamondPackId,
    required double amount,
    String? couponCode,
  }) async {
    UserModel response = await ApiService.instance.call(
        url: WebService.giftWallet.verifyDiamondPurchase,
        fromJson: UserModel.fromJson,
        param: {
          Params.paymentId: paymentId,
          if (orderId != null) Params.orderId: orderId,
          if (signature != null) Params.signature: signature,
          Params.diamondPackId: diamondPackId,
          Params.amount: amount,
          if (couponCode != null) Params.couponCode: couponCode,
        });
    return response;
  }

  Future<List<DiamondTransactionModel>> fetchDiamondTransactions(
      {int? lastItemId}) async {
    DiamondTransactionListModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchDiamondTransactions,
        fromJson: DiamondTransactionListModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != null) Params.lastItemId: lastItemId,
        });
    return response.data ?? [];
  }

  Future<DiamondWalletModel> fetchMyDiamondWallet() async {
    DiamondWalletModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyDiamondWallet,
        fromJson: (json) {
          Loggers.info('Diamond Wallet RAW JSON: $json');
          Loggers.info('Diamond Wallet data field: ${json["data"]}');
          return DiamondWalletModel.fromJson(json);
        });
    return response;
  }

  Future<List<DiamondTransactionModel>> fetchMyDiamondTransactions(
      {int? lastItemId}) async {
    DiamondTransactionListModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyDiamondTransactions,
        fromJson: DiamondTransactionListModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != null) Params.lastItemId: lastItemId,
        });
    return response.data ?? [];
  }

  Future<List<DiamondSpendHistoryModel>> fetchMyDiamondSpendHistory(
      {int? lastItemId}) async {
    DiamondSpendHistoryListModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyDiamondSpendHistory,
        fromJson: DiamondSpendHistoryListModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != null) Params.lastItemId: lastItemId,
        });
    return response.data ?? [];
  }

  /// [source] is 'video_gift', 'audio_gift' or 'chat_gift' — it tags the gift
  /// ledger row so the leaderboard can split video from audio rankings.
  Future<StatusModel> spendDiamonds({
    required int diamonds,
    required int userId,
    required int giftId,
    String purpose = 'gift',
    String? source,
    int? languageId,
  }) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.spendDiamonds,
        fromJson: StatusModel.fromJson,
        param: {
          Params.diamonds: diamonds,
          Params.userId: userId,
          Params.giftId: giftId,
          Params.purpose: purpose,
          if (source != null) Params.source: source,
          if (languageId != null) Params.languageId: languageId,
        });
    return response;
  }

  Future<int?> startAudioRoom({
    required String roomId,
    String? roomName,
    int? languageId,
    bool force = false,
  }) async {
    final Map<String, dynamic> response = await ApiService.instance.call(
        url: WebService.giftWallet.startAudioRoom,
        fromJson: (json) => json,
        param: {
          Params.roomId: roomId,
          Params.roomName: roomName,
          Params.languageId: languageId,
          if (force) Params.force: 1,
        });
    if (response['status'] == true) {
      return response['data']?['id'];
    }
    return null;
  }

  Future<void> endAudioRoom({
    required int audioRoomId,
    int? peakListenerCount,
  }) async {
    await ApiService.instance.call(
        url: WebService.giftWallet.endAudioRoom,
        fromJson: StatusModel.fromJson,
        param: {
          Params.audioRoomId: audioRoomId,
          Params.peakListenerCount: peakListenerCount,
        });
  }

  Future<void> saveBattleResult({
    required String mode,
    required int user1Id,
    required int user2Id,
    required int user1Coins,
    required int user2Coins,
    int? durationMinutes,
  }) async {
    await ApiService.instance.call(
        url: WebService.giftWallet.saveBattleResult,
        fromJson: StatusModel.fromJson,
        param: {
          Params.mode: mode,
          Params.user1Id: user1Id,
          Params.user2Id: user2Id,
          Params.user1Coins: user1Coins,
          Params.user2Coins: user2Coins,
          Params.durationMinutes: durationMinutes,
        });
  }

  Future<User?> buyCoins({required int id, String? purchasedAt}) async {
    UserModel response = await ApiService.instance.call(
        url: WebService.giftWallet.buyCoins,
        fromJson: UserModel.fromJson,
        param: {
          Params.coinPackageId: id,
          Params.purchasedAt: purchasedAt,
        });
    if (response.status == true) {
      return response.data;
    }
    return null;
  }

  Future<StarScoreResponseModel> fetchStarTransactions({
    required String type,
    int? lastItemId,
  }) async {
    StarScoreResponseModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchStarTransactions,
        fromJson: StarScoreResponseModel.fromJson,
        param: {
          Params.type: type,
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != null) Params.lastItemId: lastItemId,
        });
    return response;
  }

  Future<List<DiamondInfoModel>> fetchDiamondBuyingInformation() async {
    DiamondInfoResponseModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchDiamondBuyingInformation,
        fromJson: DiamondInfoResponseModel.fromJson);
    return response.data ?? [];
  }

  Future<List<EntryEffectModel>> fetchEntryEffects() async {
    EntryEffectResponseModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchEntryEffects,
        fromJson: EntryEffectResponseModel.fromJson);
    return response.data ?? [];
  }

  Future<StatusModel> buyEntryEffect({
    required int entryEffectId,
    required int diamonds,
  }) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.buyEntryEffect,
        fromJson: StatusModel.fromJson,
        param: {
          Params.entryEffectId: entryEffectId,
          Params.diamonds: diamonds,
        });
    return response;
  }

  Future<List<EntryEffectModel>> fetchMyEntryEffects({int? lastItemId}) async {
    EntryEffectResponseModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyEntryEffects,
        fromJson: EntryEffectResponseModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != null) Params.lastItemId: lastItemId,
        });
    return response.data ?? [];
  }

  Future<StatusModel> requestBecomeHost() async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.requestBecomeHost,
        fromJson: StatusModel.fromJson);
    return response;
  }

  Future<StatusModel> requestBecomeAgent() async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.requestBecomeAgent,
        fromJson: StatusModel.fromJson);
    return response;
  }

  Future<LiveStreamApiModel> startLiveStream({
    required int categoryId,
    required int subCategoryId,
    required int topicId,
    int? languageId,
    String? title,
    bool force = false,
  }) async {
    LiveStreamApiModel response = await ApiService.instance.call(
        url: WebService.giftWallet.startLiveStream,
        fromJson: LiveStreamApiModel.fromJson,
        param: {
          Params.categoryId: categoryId,
          Params.subCategoryId: subCategoryId,
          Params.topicId: topicId,
          if (languageId != null) Params.languageId: languageId,
          if (title != null) Params.title: title,
          if (force) Params.force: 1,
        });
    return response;
  }

  Future<LiveStreamApiModel> endLiveStream({
    required int liveStreamId,
  }) async {
    LiveStreamApiModel response = await ApiService.instance.call(
        url: WebService.giftWallet.endLiveStream,
        fromJson: LiveStreamApiModel.fromJson,
        param: {
          Params.liveStreamId: liveStreamId,
        });
    return response;
  }

  Future<StatusModel> uploadLiveStreamRecording({
    required int liveStreamId,
    required String videoFilePath,
  }) async {
    StatusModel response = await ApiService.instance.multiPartCallApi(
      url: WebService.giftWallet.uploadLiveStreamRecording,
      param: {
        Params.liveStreamId: liveStreamId,
      },
      filesMap: {
        'video': [XFile(videoFilePath)],
      },
      fromJson: StatusModel.fromJson,
    );
    return response;
  }

  Future<GiftProfitModel> fetchGiftProfit() async {
    GiftProfitModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchGiftProfit,
        fromJson: GiftProfitModel.fromJson);
    return response;
  }

  Future<StatusModel> requestScreenshotDisable({required String reason}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.giftWallet.requestScreenshotDisable,
      param: {Params.reason: reason},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<DiamondFaqModel> fetchDiamondFaqs({String? category}) async {
    DiamondFaqModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchDiamondFaqs,
        param: {
          if (category != null) 'category': category,
        },
        fromJson: DiamondFaqModel.fromJson);
    return response;
  }
}
