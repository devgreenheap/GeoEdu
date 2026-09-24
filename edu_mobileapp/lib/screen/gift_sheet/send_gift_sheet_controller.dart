import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/firebase_notification_manager.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/diamond_purchase/diamond_wallet_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_dialog.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/common/manager/gift_audio_player.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/entry_effects_widget.dart'
    show AnimatedSvgPlayer;

class SendGiftSheetController extends BaseController {
  Rx<Setting?> settings = Rx<Setting?>(null);
  Rx<User?> myUser = Rx<User?>(null);
  Rx<DiamondWallet?> diamondWallet = Rx<DiamondWallet?>(null);
  int? userId;
  List<AppUser> liveUsers;
  GiftType? giftType;
  String? source;
  late LivestreamScreenController livestreamController;

  SendGiftSheetController(this.giftType, this.userId, this.liveUsers, {this.source});

  @override
  void onInit() {
    super.onInit();
    _initData();

    if (liveUsers.isNotEmpty &&
        (giftType == GiftType.livestream || giftType == GiftType.battle)) {
      livestreamController = Get.find<LivestreamScreenController>();
      // This selection feeds `receiver_id` for the gift API call the moment
      // "Send" is tapped in this same sheet, so it must be set synchronously
      // — a debounced update here could still be pending (or get raced by a
      // second gift sheet opened in quick succession, e.g. during a PK
      // battle) when the user taps Send, leaving the wrong or null receiver
      // and silently dropping that gift from the session's stats.
      if (livestreamController.selectedGiftUser.value == null) {
        livestreamController.selectedGiftUser = liveUsers.first.obs;
      } else {
        livestreamController.selectedGiftUser.value = liveUsers.firstWhere(
            (element) =>
                element.userId ==
                livestreamController.selectedGiftUser.value?.userId,
            orElse: () => liveUsers.first);
      }
    }
  }

  _initData() {
    final s = SessionManager.instance.getSettings();
    if (s != null) {
      s.gifts = s.availableGifts;
      if (s.gifts != null && s.gifts!.isNotEmpty) {
        GiftAudioPlayer.preloadAll(s.gifts!);
        AnimatedSvgPlayer.preloadAll(s.gifts!);
      }
    }
    settings.value = s;
    myUser.value = SessionManager.instance.getUser();
    _fetchDiamondWallet();

    // Fetch latest settings from admin so newly uploaded gift audios/animations are available immediately
    CommonService.instance.fetchGlobalSettings().then((success) {
      if (success) {
        final fresh = SessionManager.instance.getSettings();
        if (fresh != null) {
          fresh.gifts = fresh.availableGifts;
          settings.value = fresh;
          if (fresh.gifts != null && fresh.gifts!.isNotEmpty) {
            GiftAudioPlayer.preloadAll(fresh.gifts!);
            AnimatedSvgPlayer.preloadAll(fresh.gifts!);
          }
        }
      }
    });
  }

  Future<void> _fetchDiamondWallet() async {
    final response = await GiftWalletService.instance.fetchMyDiamondWallet();
    diamondWallet.value = response.data;
  }

  void onGiftTap(Gift gift, BuildContext context) {
    if (gift.id == null) {
      return showSnackBar('Gift Not Found');
    }

    sendGift(gift, context);
  }

  Future<void> sendGift(Gift gift, BuildContext context) async {
    final giftId = gift.id?.toInt() ?? -1;

    final coinPrice = gift.coinPrice ?? 0;
    userId ??= livestreamController.selectedGiftUser.value?.userId;

    if (giftId == -1 || userId == -1) {
      return Loggers.error('Invalid Gift: $giftId or User: $userId');
    }

    if (coinPrice <= 0) {
      return Loggers.error(
          'Invalid coin price: $coinPrice, skipping gift sending.');
    }
    showLoader();
    int effectiveGiftId = (giftId > 0) ? giftId : -1;
    if (effectiveGiftId <= 0) {
      final serverGifts = SessionManager.instance.getSettings()?.gifts ?? [];
      if (serverGifts.isNotEmpty) {
        final matchingServerGift = serverGifts.firstWhere(
          (g) => (g.coinPrice ?? 0) == coinPrice,
          orElse: () => serverGifts.first,
        );
        if (matchingServerGift.id != null && matchingServerGift.id! > 0) {
          effectiveGiftId = matchingServerGift.id!;
        }
      }
    }
    final response = await GiftWalletService.instance.spendDiamonds(
        diamonds: coinPrice.toInt(),
        userId: userId!,
        giftId: effectiveGiftId,
        source: source);
    stopLoader();
    if (response.status == true) {
      // Deduct diamonds from diamond wallet
      diamondWallet.update((val) {
        if (val != null) {
          val.diamondBalance = (val.diamondBalance ?? 0) - coinPrice.toInt();
        }
      });
      Loggers.info('Diamond balance: ${diamondWallet.value?.diamondBalance}');
      if (giftType == GiftType.none) {
        Get.back(result: GiftManager(gift));
      } else {
        Get.back(
            result: GiftManager(gift,
                streamUser: livestreamController.selectedGiftUser.value));
      }
    } else {
      showSnackBar(response.message);
    }
  }
}

class GiftManager {
  Gift gift;
  AppUser? streamUser;

  GiftManager(this.gift, {this.streamUser});

  static Future<void> openGiftSheet(
      {int? userId,
      Post? post,
      GiftType giftType = GiftType.none,
      BattleView battleViewType = BattleView.red,
      List<AppUser> streamUsers = const [],
      String? source,
      required Function(GiftManager giftManager) onCompletion}) async {
    await Get.bottomSheet<GiftManager>(
      SendGiftSheet(
        userId: userId,
        giftType: giftType,
        battleViewType: battleViewType,
        streamUsers: streamUsers,
        source: source,
      ),
      isScrollControlled: true,
    ).then((gift) {
      if (gift != null) {
        onCompletion(gift);
      }
    });
  }

  static void showAnimationDialog(Gift gift) {
    showGeneralDialog(
      context: Get.context!,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SendGiftDialog(gift: gift);
      },
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation);

        if (slideAnimation.isForwardOrCompleted) {
          HapticManager.shared.light();
        }

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  static void sendNotification(Post? post) {
    final user = post?.user;
    if (user == null || user.id == SessionManager.instance.getUserID()) return;

    if (user.notifyGiftReceived == 1) {
      FirebaseNotificationManager.instance.sendLocalisationNotification(
        LKey.activitySentGift,
        type: NotificationType.post,
        deviceType: user.device,
        deviceToken: user.deviceToken,
        languageCode: user.appLanguage,
        body: NotificationInfo(id: post?.id),
      );
    }
  }
}
