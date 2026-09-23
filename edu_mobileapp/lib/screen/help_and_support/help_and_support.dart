import 'package:flutter/material.dart';
import 'package:geoedu/screen/help_and_support/payment_faq_screen.dart';
import 'package:geoedu/screen/help_and_support/report_issue/report_issue_screen.dart';
import 'package:geoedu/screen/settings_screen/settings_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../common/widget/custom_app_bar.dart';
import '../../utilities/theme_res.dart';
import '../settings_screen/widget/setting_icon_text_with_arrow.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: kSecondaryHeaderGradient))),
          Column(
            children: [
              CustomAppBar(title: "Help & Support",iconColor: Colors.white,),
              SettingLabel(title: "Support Center",),
              SettingIconTextWithArrow(
                widget: Image.asset(
                  AssetRes.icForwardArrow,
                  width: 24,
                  height: 20,
                  color: whitePure(context),
                ),
                icon: AssetRes.help,
                title: "Frequently Asked Questions",
                onTap: () {
                  Get.to(() => const PaymentFaqScreen());
                },
              ),SettingIconTextWithArrow(
                widget: Image.asset(
                  AssetRes.icForwardArrow,
                  width: 24,
                  height: 20,
                  color: whitePure(context),
                ),
                icon: AssetRes.helpReport,
                title: "Report an Issue",
                onTap: (){
                  Get.to(()=>ReportIssueScreen());
                },
              ),
            ],
          )
        ],
      )
    );
  }
}
