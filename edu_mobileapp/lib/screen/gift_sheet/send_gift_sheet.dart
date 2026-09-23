import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/bottom_sheet_top_view.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/common/widget/gradient_text.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/style_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class SendGiftSheet extends StatelessWidget {
  final GiftType giftType;
  final BattleView battleViewType;
  final int? userId;
  final List<AppUser> streamUsers;
  final String? source;

  const SendGiftSheet(
      {super.key,
      this.giftType = GiftType.none,
      this.battleViewType = BattleView.red,
      required this.userId,
      this.streamUsers = const [],
      this.source});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(SendGiftSheetController(giftType, userId, streamUsers, source: source));

    return Container(
      height: Get.height / 1.5,
      margin: EdgeInsets.only(top: AppBar().preferredSize.height * 2.5),
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1),
          ),
        ),
        gradient: LinearGradient(colors: [
          Color(0xFF031631),
          Color(0xFF000000),
        ])
        // color: scaffoldBackgroundColor(context),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            BottomSheetTopView(
                title: LKey.sendGifts.tr,
                margin: const EdgeInsets.only(top: 15)),
            switch (giftType) {
              GiftType.none => const SizedBox(),
              GiftType.livestream => GiftForLiveStream(
                  controller: controller, streamUsers: streamUsers),
              GiftType.battle => Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                    Color(0xFF031631),

                    // gradient: LinearGradient(colors: [
                    //   Color(0xFF000000),
                    // ]),
                  ),
                  // color: battleViewType.color,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomImage(
                              size: const Size(30, 30),
                              image: streamUsers.first.profile?.addBaseURL(),
                              fullName: streamUsers.first.fullname,
                              strokeColor: whitePure(context),
                              strokeWidth: 1.2),
                          const SizedBox(width: 5),
                          Flexible(
                              child: FullNameWithBlueTick(
                                  username: streamUsers.first.username,
                                  fontColor: whitePure(context),
                                  isVerify: streamUsers.first.isVerify))
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        LKey.youAreSendingCoinsTo
                            .trParams({'color': battleViewType.value}),
                        style: TextStyleCustom.outFitLight300(
                            color: whitePure(context), fontSize: 12),
                      )
                    ],
                  ),
                ),
            },
            const SizedBox(height: 10),
            Obx(() => GradientText(
                (controller.diamondWallet.value?.diamondBalance ?? 0).toString(),
                gradient: StyleRes.themeGradient,
                style: TextStyleCustom.unboundedSemiBold600(fontSize: 21))),
            Text('Diamonds You Have',
                style: TextStyleCustom.outFitRegular400(
                    fontSize: 15, color: textLightGrey(context))),
            const SizedBox(height: 10),
            Expanded(child: Obx(
              () {
                List<Gift> gifts = controller.settings.value?.gifts ?? [];

                // Group gifts by category
                final Map<String, List<Gift>> grouped = {};
                for (var gift in gifts) {
                  final catName = gift.categoryName ?? 'Other';
                  grouped.putIfAbsent(catName, () => []);
                  grouped[catName]!.add(gift);
                }

                final categoryNames = grouped.keys.toList();

                if (categoryNames.length <= 1) {
                  return _buildGiftGrid(gifts, controller, context);
                }

                // Add "All" tab at the beginning
                final allCategoryNames = ['All', ...categoryNames];
                final allGrouped = <String, List<Gift>>{
                  'All': gifts,
                  ...grouped,
                };

                return _GiftCategoryTabs(
                  categoryNames: allCategoryNames,
                  grouped: allGrouped,
                  controller: controller,
                );
              },
            ))
          ],
        ),
      ),
    );
  }
}

Widget _buildGiftGrid(
    List<Gift> gifts, SendGiftSheetController controller, BuildContext context) {
  return GridView.builder(
    itemCount: gifts.length,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 142,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5),
    itemBuilder: (context, index) {
      Gift gift = gifts[index];
      return InkWell(
        onTap: () => controller.onGiftTap(gift, context),
        child: Container(
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius:
                  SmoothBorderRadius(cornerRadius: 5, cornerSmoothing: 1),
            ),
            color: const Color(0xFF031631),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomImage(
                  image: gift.image?.addBaseURL(),
                  size: const Size(60, 60),
                  radius: 8),
              Text(gift.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitMedium500(
                      fontSize: 12, color: whitePure(context))),
              Text('${(gift.coinPrice ?? 0).numberFormat} Diamonds',
                  style: TextStyleCustom.outFitMedium500(
                      fontSize: 13, color: textLightGrey(context))),
              GradientText(LKey.send.tr,
                  gradient: StyleRes.themeGradient,
                  style: TextStyleCustom.unboundedMedium500(fontSize: 13))
            ],
          ),
        ),
      );
    },
  );
}

class _GiftCategoryTabs extends StatefulWidget {
  final List<String> categoryNames;
  final Map<String, List<Gift>> grouped;
  final SendGiftSheetController controller;

  const _GiftCategoryTabs({
    required this.categoryNames,
    required this.grouped,
    required this.controller,
  });

  @override
  State<_GiftCategoryTabs> createState() => _GiftCategoryTabsState();
}

class _GiftCategoryTabsState extends State<_GiftCategoryTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.categoryNames.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: TextStyleCustom.outFitMedium500(fontSize: 13),
          unselectedLabelStyle: TextStyleCustom.outFitLight300(fontSize: 13),
          indicatorColor: const Color(0xffB6FF52),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.white12,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: widget.categoryNames
              .map((name) => Tab(text: name))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.categoryNames.map((catName) {
              final gifts = widget.grouped[catName] ?? [];
              return _buildGiftGrid(gifts, widget.controller, context);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class GiftForLiveStream extends StatelessWidget {
  final SendGiftSheetController controller;
  final List<AppUser> streamUsers;

  const GiftForLiveStream(
      {super.key, required this.controller, required this.streamUsers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          AppUser? giftUser =
              controller.livestreamController.selectedGiftUser.value;
          if (giftUser == null) {
            return const SizedBox();
          }
          return streamUsers.length <= 1
              ? Container(
                  color:
                  Color(0xFF031631),

                  // color: bgLightGrey(context),
                  child: _PopupMenuItemCustom(streamUser: giftUser))
              : PopupMenuButton<AppUser>(
                  initialValue: giftUser,
                  onSelected: (AppUser value) {
                    controller.livestreamController.selectedGiftUser.value =
                        value;
                  },
                  shape: const RoundedRectangleBorder(
                    borderRadius: SmoothBorderRadius.vertical(
                        bottom:
                            SmoothRadius(cornerRadius: 15, cornerSmoothing: 1)),
                  ),
                  position: PopupMenuPosition.under,
                  constraints: const BoxConstraints(
                      maxWidth: double.infinity, minWidth: double.infinity),
                  itemBuilder: (BuildContext context) {
                    return List.generate(
                      streamUsers.length,
                      (index) => PopupMenuItem(
                          value: streamUsers[index],
                          padding: EdgeInsets.zero,
                          child: _PopupMenuItemCustom(
                              streamUser: streamUsers[index])),
                    );
                  },
                  child: _PopupMenuItemCustom(
                      isPopupChild: true, streamUser: giftUser),
                );
        }),
        const SizedBox(height: 3),
        Text(
          LKey.sendingCoinsMessage.tr,
          style: TextStyleCustom.outFitLight300(
              color: textLightGrey(context), fontSize: 13),
        )
      ],
    );
  }
}

class _PopupMenuItemCustom extends StatelessWidget {
  final bool isPopupChild;
  final AppUser streamUser;

  const _PopupMenuItemCustom(
      {this.isPopupChild = false, required this.streamUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isPopupChild ? bgLightGrey(context) : null,
      height: 45,
      width: MediaQuery.of(context).size.width - 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImage(
            size: const Size(30, 30),
            image: streamUser.profile?.addBaseURL(),
            fullName: streamUser.fullname ?? '',
            strokeColor: whitePure(context),
            strokeWidth: 1,
          ),
          const SizedBox(width: 5),
          FullNameWithBlueTick(
            username: streamUser.username,
            isVerify: streamUser.isVerify,
            iconSize: 14,
          ),
          if (isPopupChild)
            Image.asset(AssetRes.icDownArrow_1, width: 26, height: 26),
        ],
      ),
    );
  }
}

enum GiftType {
  none,
  livestream,
  battle;
}

enum BattleView {
  red('red'),
  blue('blue');

  final String value;

  const BattleView(this.value);

  Color get color {
    switch (this) {
      case BattleView.red:
        return ColorRes.likeRed;
      case BattleView.blue:
        return ColorRes.battleProgressColor;
    }
  }
}
