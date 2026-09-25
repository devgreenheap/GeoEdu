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
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
import 'package:geoedu/utilities/color_res.dart';
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

  Future<void> refreshDiamondWallet() async {
    final response = await GiftWalletService.instance.fetchMyDiamondWallet();
    diamondWallet.value = response.data;
  }

  Future<void> _fetchDiamondWallet() => refreshDiamondWallet();

  void onGiftTap(Gift gift, BuildContext context) {
    if (gift.id == null) {
      return showSnackBar('Gift Not Found');
    }

    final coinPrice = gift.coinPrice ?? 0;
    final currentBalance = diamondWallet.value?.diamondBalance ?? 0;
    if (currentBalance < coinPrice) {
      showInsufficientDiamondsDialog(
        requiredDiamonds: coinPrice.toInt(),
        giftName: gift.displayName,
      );
      return;
    }

    sendGift(gift, context);
  }

  void showInsufficientDiamondsDialog({
    required int requiredDiamonds,
    required String giftName,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF9500).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Insufficient Diamonds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'You need '),
                    TextSpan(
                      text: '$requiredDiamonds Diamonds',
                      style: const TextStyle(
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' to send $giftName.\nYour current balance is '),
                    TextSpan(
                      text: '${diamondWallet.value?.diamondBalance ?? 0} Diamonds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorRes.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        Get.back();
                        await Get.to(() => const StarStoreDiamondScreen());
                        refreshDiamondWallet();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Purchase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
