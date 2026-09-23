import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/diamond_purchase/diamond_faq_screen.dart';
import 'package:geoedu/screen/diamond_purchase/widgets/diamond_purchase.dart';
import 'package:geoedu/screen/diamond_purchase/widgets/diamond_purchase_history.dart';
import 'package:geoedu/screen/diamond_purchase/widgets/diamond_purchase_tabs.dart';

import '../../common/widget/custom_app_bar.dart';
import '../../utilities/color_res.dart';

class DiamondPurchaseScreen extends StatefulWidget {
  const DiamondPurchaseScreen({super.key});

  @override
  State<DiamondPurchaseScreen> createState() => _DiamondPurchaseScreenState();
}

class _DiamondPurchaseScreenState extends State<DiamondPurchaseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: kSecondaryHeaderGradient)),
        ),
        Column(
          children: [
            CustomAppBar(
              iconColor: ColorRes.whitePure,
              title: "Diamond Ledger",
              rowWidget: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () => Get.to(() => const DiamondFaqScreen()),
              ),
            ),
            Expanded(
              child: DefaultTabController(length: 2, child: Column(
                children: [
                  DiamondPurchaseTabs(),
                  Expanded(child: TabBarView(children: [
                    DiamondPurchase(),
                    DiamondPurchaseHistory(),
                  ]))
                ],
              )),
            )
          ],
        )
      ]),
    );
  }
}
