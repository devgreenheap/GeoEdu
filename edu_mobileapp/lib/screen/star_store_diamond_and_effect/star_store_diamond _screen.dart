import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/screen/leader_board/leader_board_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/tab_widget.dart';
import 'package:geoedu/screen/diamond_purchase/diamond_purchase_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/diamond_store.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/effects_store.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../utilities/theme_res.dart';

class StarStoreDiamondScreen extends StatefulWidget {
  // False when embedded as the "Premium" bottom-nav tab body — there's
  // nothing for a back arrow to pop back to in that context.
  final bool showBackButton;

  const StarStoreDiamondScreen({super.key, this.showBackButton = true});

  @override
  State<StarStoreDiamondScreen> createState() => _StarStoreDiamondScreenState();
}

class _StarStoreDiamondScreenState extends State<StarStoreDiamondScreen> {

  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () {
                  Get.back();
                },
              )
            : null,
        title: const Text(
          "Diamond Store",
          style: TextStyle(color: ColorRes.whitePure, fontWeight: FontWeight.w700),
        ),
        actions: [
          GestureDetector(
            onTap: () => Get.to(() => const LeaderBoardScreen()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorRes.gold, width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, color: ColorRes.gold, size: 16),
                  SizedBox(width: 5),
                  Text(
                    'Top',
                    style: TextStyle(color: ColorRes.gold, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            onPressed: () => Get.to(() => const DiamondPurchaseScreen()),
          ),
        ],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kAppBarGradient),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Column(
            children: [
              StarStepTabs(currentStep: currentTab, onChanged: (index){
                setState(() {
                  currentTab = index;
                });
              }),
              Container(height: .5, color: textLightGrey(context)),
              Expanded(
                child: SingleChildScrollView(
                  child: currentTab == 0 ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: const DiamondStore()) : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: const EffectsStoreScreen()),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
