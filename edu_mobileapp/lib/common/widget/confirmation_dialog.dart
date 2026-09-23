import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/text_button_custom.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class ConfirmationSheet extends StatelessWidget {
  final String title;
  final String description;
  final String? description2;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final bool isDismissible;
  final String? positiveText;
  final Color? actionColor;
  final bool boldWhiteDescription;

  const ConfirmationSheet({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    this.description2,
    this.positiveText,
    this.onClose,
    this.isDismissible = true,
    this.actionColor,
    this.boldWhiteDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
              shape: const SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius.vertical(
                      top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1))),
              color: ColorRes.cardBackground),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        height: 1,
                        width: 100,
                        color: bgGrey(context),
                        margin: const EdgeInsets.only(top: 10)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyleCustom.unboundedMedium500(
                                color: textDarkGrey(context), fontSize: 15)),
                      ),
                      if (isDismissible)
                        InkWell(
                          onTap: onClose ??
                              () {
                                Get.back();
                              },
                          child: Icon(Icons.close_rounded,
                              color: textDarkGrey(context), size: 25),
                        )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    '$description\n\n${description2 ?? LKey.proceedConfirmation.tr}',
                    style: boldWhiteDescription
                        ? TextStyleCustom.outFitLight300(fontSize: 16, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.bold)
                        : TextStyleCustom.outFitLight300(
                            fontSize: 16, color: textLightGrey(context)),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      if (isDismissible) ...[
                        Expanded(
                          child: TextButtonCustom(
                            onTap: onClose ??
                                () {
                                  Get.back();
                                },
                            title: LKey.cancel.tr,
                            backgroundColor: Colors.transparent,
                            borderSide: BorderSide(color: bgGrey(context)),
                            margin: EdgeInsets.zero,
                            titleColor: textDarkGrey(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: TextButtonCustom(
                          onTap: () {
                            Get.back();
                            onTap();
                          },
                          title: positiveText ?? LKey.continueText.tr,
                          backgroundColor: actionColor ?? textDarkGrey(context),
                          margin: EdgeInsets.zero,
                          titleColor: whitePure(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
