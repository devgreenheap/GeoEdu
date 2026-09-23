import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

enum TermAndPrivacyType {
  privacyPolicy,
  termAndCondition;

  String get title {
    switch (this) {
      case TermAndPrivacyType.privacyPolicy:
        return LKey.privacyPolicy;
      case TermAndPrivacyType.termAndCondition:
        return LKey.termsOfUse;
    }
  }
}

class TermAndPrivacyScreen extends StatefulWidget {
  final TermAndPrivacyType type;

  const TermAndPrivacyScreen({super.key, required this.type});

  @override
  State<TermAndPrivacyScreen> createState() => _TermAndPrivacyScreenState();
}

class _TermAndPrivacyScreenState extends State<TermAndPrivacyScreen> {
  Rx<Setting?> settings = Rx(null);

  @override
  void initState() {
    super.initState();
    settings.value = SessionManager.instance.getSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: widget.type.title.tr,iconColor: Colors.white,),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorRes.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true, // Removes extra top padding
                  child: Obx(
                    () => HtmlWidget(
                      widget.type == TermAndPrivacyType.privacyPolicy
                          ? settings.value?.privacyPolicy ?? ''
                          : settings.value?.termsOfUses ?? '',
                      textStyle: TextStyleCustom.outFitRegular400(
                              fontSize: 15, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.bold),
                      renderMode: RenderMode.listView,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
