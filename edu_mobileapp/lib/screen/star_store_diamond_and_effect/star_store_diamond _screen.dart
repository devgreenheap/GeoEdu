import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/leader_board/leader_board_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/tab_widget.dart';
import 'package:geoedu/screen/diamond_purchase/diamond_purchase_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/diamond_store.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/effects_store.dart';

class StarStoreDiamondScreen extends StatefulWidget {
  // False when embedded as the "Premium" bottom-nav tab body — there's
  // nothing for a back arrow to pop back to in that context.
  final bool showBackButton;
  final VoidCallback? onPurchaseCompleted;

  const StarStoreDiamondScreen({
    super.key,
    this.showBackButton = true,
    this.onPurchaseCompleted,
  });

  @override
  State<StarStoreDiamondScreen> createState() => _StarStoreDiamondScreenState();
}

class _StarStoreDiamondScreenState extends State<StarStoreDiamondScreen> {

  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: widget.showBackButton ? 56 : 0,
        leading: widget.showBackButton
            ? Center(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFB300),
              size: 24,
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                text: 'Diamond ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                children: [
                  TextSpan(
                    text: 'Store',
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Get.to(() => const LeaderBoardScreen()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.8),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300), size: 16),
                  SizedBox(width: 5),
                  Text(
                    'Top',
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const DiamondPurchaseScreen()),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background ambient illumination
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF090A0F),
                    Color(0xFF0D101A),
                    Color(0xFF090A0F),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB300).withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            children: [
              StarStepTabs(
                currentStep: currentTab,
                onChanged: (index) {
                  setState(() {
                    currentTab = index;
                  });
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFFFB300),
                  backgroundColor: const Color(0xFF141724),
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: currentTab == 0
                        ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: DiamondStore(
                              onPurchaseCompleted: widget.onPurchaseCompleted,
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: EffectsStoreScreen(
                              onSwitchToDiamondStore: () {
                                setState(() {
                                  currentTab = 0;
                                });
                              },
                            ),
                          ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
