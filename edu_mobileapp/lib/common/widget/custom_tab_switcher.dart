import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class CustomTabSwitcher extends StatelessWidget {
  final List<String> items;
  final Function(int index) onTap;
  final RxInt selectedIndex;
  final Widget? widget;
  final int widgetTabIndex;
  final EdgeInsets? margin;
  final Color? selectedFontColor;
  final Color? backgroundColor;
  final bool border;
  final Widget? frontWidget;

  const CustomTabSwitcher(
      {super.key,
      required this.items,
      required this.onTap,
      required this.selectedIndex,
      this.widget,
      this.widgetTabIndex = -1,
      this.margin,
      this.selectedFontColor,
      this.border = true,
      this.backgroundColor,
      this.frontWidget});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 45,
        width: double.infinity,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: backgroundColor ?? bgMediumGrey(context),
          shape: border
              ? SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 10,
                    cornerSmoothing: 1,
                  ),
                  side: BorderSide(color: bgGrey(context)),
                )
              : const SmoothRectangleBorder(), // empty but not null
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Tab Indicator
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedAlign(
                  alignment: Alignment(
                    (selectedIndex * 2 / (items.length - 1)) - 1,
                    1,
                  ),
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    height: 4,
                    width: constraints.maxWidth / items.length,
                    decoration: ShapeDecoration(
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                              cornerRadius: 10 - 2, cornerSmoothing: 1),
                        ),
                        color: const Color(0xFF0389ff)
                        // color: whitePure(context),
                        ),
                  ),
                  // child: Container(
                  //   width: constraints.maxWidth / items.length,
                  //   decoration: ShapeDecoration(
                  //     shape: SmoothRectangleBorder(
                  //       borderRadius: SmoothBorderRadius(
                  //           cornerRadius: 10 - 2, cornerSmoothing: 1),
                  //     ),
                  //     color: whitePure(context),
                  //   ),
                  // ),
                );
              },
            ),
            // Tab Content
            Center(
              child: Row(
                children: List.generate(
                  items.length,
                  (index) {
                    bool isSelected = selectedIndex.value == index;
                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (frontWidget != null)
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  isSelected
                                      ? (selectedFontColor ??
                                          textDarkGrey(context))
                                      : Colors.white,
                                  BlendMode.srcIn,
                                ),
                                child: frontWidget!,
                              ),
                            Text(
                              items[index].tr,
                              style: TextStyleCustom.outFitRegular400(
                                  color: !isSelected
                                      ? Colors.white
                                      : (selectedFontColor ??
                                          textDarkGrey(context)),
                                  fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            if (widget != null && widgetTabIndex == index)
                              widget!
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
