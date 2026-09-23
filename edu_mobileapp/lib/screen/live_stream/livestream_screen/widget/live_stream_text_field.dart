import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/gradient_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/style_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class LiveStreamTextFieldView extends StatelessWidget {
  final bool isAudience;
  final LivestreamScreenController controller;

  const LiveStreamTextFieldView(
      {super.key, required this.isAudience, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Livestream stream = controller.liveData.value;
      bool isTextEmpty = controller.isTextEmpty.value;
      bool isBattleON = stream.type == LivestreamType.battle;
      bool isGiftIconVisible = controller.streamViews.firstWhereOrNull(
              (view) => view.streamId == controller.myUserId.toString()) ==
          null;

      List<AppUser> users =
          stream.getAllUsers(controller.firestoreController.users);

      bool showBattleGiftBar = isBattleON &&
          isAudience &&
          isGiftIconVisible &&
          users.length == 2 &&
          controller.isBattleGiftBarOpen.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBattleGiftBar)
            BattleInlineGiftBar(controller: controller, users: users),
          Container(
            height: 43,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: ShapeDecoration(
                color: ColorRes.cardBackground.withValues(alpha: .75),
                shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                        cornerRadius: 30, cornerSmoothing: 1),
                    side: BorderSide(
                        color: whitePure(context).withValues(alpha: .2))),
            ),
            child: TextField(
              controller: controller.textCommentController,
              onChanged: (value) {
                controller.isTextEmpty.value = value.isEmpty ? true : false;
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: isAudience
                    ? '${LKey.writeHere.tr}..'
                    : LKey.whatDoYouThink.tr,
                hintStyle: TextStyleCustom.outFitLight300(
                    color: whitePure(context), fontSize: 17, opacity: .42),
                contentPadding: const EdgeInsets.only(left: 10, right: 10),
                suffixIconConstraints: const BoxConstraints(),
                suffixIcon: TextFieldSuffixIcon(
                  controller: controller,
                  isBattleOn: isBattleON,
                  isAudience: isAudience,
                  isTextEmpty: isTextEmpty,
                  isGiftIconVisible: isGiftIconVisible,
                  users: users,
                ),
              ),
              style: TextStyleCustom.outFitRegular400(
                  color: whitePure(context), fontSize: 17),
              cursorColor: whitePure(context).withValues(alpha: .6),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
        ],
      );
    });
  }
}

/// EloTV-style persistent gift row for PK battles: tap a gift to send it
/// instantly to whichever side is selected, no full-screen sheet.
class BattleInlineGiftBar extends StatelessWidget {
  final LivestreamScreenController controller;
  final List<AppUser> users;

  const BattleInlineGiftBar(
      {super.key, required this.controller, required this.users});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      BattleView side = controller.selectedBattleSide.value;
      AppUser targetUser =
          side == BattleView.red ? users.first : users.last;
      List<Gift> gifts = List<Gift>.from(controller.setting.allGiftsWithPen);
      int? favouriteId = controller.liveData.value.favouriteGiftId;
      if (favouriteId != null) {
        gifts.sort((a, b) => (a.id == favouriteId ? 0 : 1)
            .compareTo(b.id == favouriteId ? 0 : 1));
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: ColorRes.cardBackground.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _SideChip(
                  label: targetUser.username ?? LKey.host.tr,
                  color: ColorRes.likeRed,
                  selected: side == BattleView.red,
                  onTap: () =>
                      controller.selectedBattleSide.value = BattleView.red,
                ),
                const SizedBox(width: 8),
                _SideChip(
                  label: users.last.username ?? '',
                  color: ColorRes.battleProgressColor,
                  selected: side == BattleView.blue,
                  onTap: () =>
                      controller.selectedBattleSide.value = BattleView.blue,
                ),
                const Spacer(),
                GradientText(
                  '${controller.diamondBalance.value}',
                  gradient: StyleRes.themeGradient,
                  style: TextStyleCustom.unboundedMedium500(fontSize: 13),
                ),
                const SizedBox(width: 4),
                Image.asset(AssetRes.icCoin, height: 16, width: 16),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => controller.isBattleGiftBarOpen.value = false,
                  child: Icon(Icons.close,
                      size: 18, color: whitePure(context)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 94,
              child: gifts.isEmpty
                  ? Center(
                      child: Text('No gifts available',
                          style: TextStyleCustom.outFitLight300(
                              color: whitePure(context), fontSize: 12)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: gifts.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        Gift gift = gifts[index];
                        bool isHost = controller.myUserId ==
                            controller.liveData.value.hostId;
                        bool isFavourite = gift.id != null &&
                            gift.id ==
                                controller.liveData.value.favouriteGiftId;
                        return InkWell(
                          onTap: () => controller.sendBattleGiftDirect(
                              gift, targetUser),
                          onLongPress: isHost
                              ? () => controller.setFavouriteGift(gift)
                              : null,
                          child: Container(
                            width: 66,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CustomImage(
                                      image: gift.image?.addBaseURL(),
                                      size: const Size(38, 38),
                                      radius: 6,
                                    ),
                                    if (isFavourite)
                                      const Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Icon(Icons.star,
                                            size: 14, color: ColorRes.gold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  gift.displayName,
                                  style: TextStyleCustom.outFitMedium500(
                                      fontSize: 11,
                                      color: whitePure(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(gift.coinPrice ?? 0).numberFormat} Diamonds',
                                  style: TextStyleCustom.outFitMedium500(
                                      fontSize: 9,
                                      color: ColorRes.primaryColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _SideChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SideChip(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: .25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyleCustom.outFitMedium500(
              fontSize: 11, color: whitePure(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class TextFieldSuffixIcon extends StatelessWidget {
  final bool isTextEmpty;
  final bool isAudience;
  final bool isBattleOn;
  final bool isGiftIconVisible;
  final List<AppUser> users;
  final LivestreamScreenController controller;

  const TextFieldSuffixIcon({
    super.key,
    required this.isTextEmpty,
    required this.isAudience,
    required this.isBattleOn,
    required this.controller,
    required this.isGiftIconVisible,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final bool showGiftIconsForBattle = isTextEmpty &&
        isAudience &&
        isBattleOn &&
        isGiftIconVisible &&
        users.length == 2;

    final bool showSendButton = !isBattleOn || !isGiftIconVisible;

    return AnimatedContainer(
      width: isTextEmpty && isAudience ? 100 : 80,
      alignment: AlignmentDirectional.centerEnd,
      duration: const Duration(milliseconds: 100),
      child: !isTextEmpty
          ? _sendButton(context)
          : showGiftIconsForBattle
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GiftIcon(
                      bgColor: ColorRes.likeRed,
                      onTap: () =>
                          controller.openBattleGiftBar(BattleView.red),
                    ),
                    GiftIcon(
                      isblue: true,
                      bgColor: ColorRes.battleProgressColor,
                      onTap: () =>
                          controller.openBattleGiftBar(BattleView.blue),
                    ),
                  ],
                )
              : showSendButton && isTextEmpty && !isAudience
                  ? _sendButton(context)
                  : isBattleOn && isAudience
                      ? _sendButton(context)
                      : !isTextEmpty
                          ? _sendButton(context)
                          : GiftIcon(
                              onTap: () => controller
                                  .onGiftTap(GiftType.livestream, users: users),
                            ),
    );
  }

  Widget _sendButton(BuildContext context) {
    return InkWell(
      onTap: controller.onTextCommentSend,
      child: Container(
        height: 37,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Text(
          LKey.send.tr,
          style: TextStyleCustom.unboundedMedium500(
            color: whitePure(context),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class GiftIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? bgColor;
  final bool isblue;

  const GiftIcon({super.key, this.onTap, this.bgColor, this.isblue = false});

@override
Widget build(BuildContext context) {
  return InkWell(
    onTap: onTap,
    child: isblue ? Image.asset(AssetRes.liveblueGift,) : Image.asset(AssetRes.liveGift,),
  );
}

  // @override
  // Widget build(BuildContext context) {
  //   return InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       height: 37,
  //       width: 37,
  //       margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 3),
  //       decoration: BoxDecoration(
  //         gradient: bgColor == null ? StyleRes.themeGradient : null,
  //         color: bgColor,
  //         shape: BoxShape.circle,
  //       ),
  //       alignment: Alignment.center,
  //       child: Image.asset(AssetRes.effectGift,
  //           height: 20, width: 20, color: whitePure(context)),
  //     ),
  //   );
  // }
}
