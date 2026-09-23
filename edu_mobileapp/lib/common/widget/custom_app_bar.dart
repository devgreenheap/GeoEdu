import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/custom_back_button.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

import '../../utilities/color_res.dart';

/// Shared dark gradient used behind secondary-screen bodies — replaces the
/// old blue/purple imagery per the GIO EDU dark theme.
const kSecondaryHeaderGradient = LinearGradient(
  colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

/// GIO EDU brand gradient for the app bar chrome itself — clean orange,
/// no white, for a professional/neat look across every screen's app bar.
const kAppBarGradient = LinearGradient(
  colors: [ColorRes.primaryColor, ColorRes.orangeDark],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget? widget;
  final Widget? rowWidget;
  final String? subTitle;
  final TextStyle? titleStyle;
  final Color? bgColor;
  final Color? iconColor;
  final bool isLoading;
  final bool? isShowBackShow;
  final bool centertitle;
  const CustomAppBar(
      {super.key,
      required this.title,
      this.widget,
      this.subTitle,
      this.titleStyle,
      this.bgColor,
      this.iconColor,
      this.rowWidget,
      this.isLoading = false,
      this.isShowBackShow = true,
      this.centertitle = true
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: kAppBarGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          spacing: widget != null ? 10 : 0,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                isShowBackShow == true ? CustomBackButton(
                  color: iconColor,
                  width: 18,
                  height: 18,
                  padding: const EdgeInsets.all(15),
                ) : const SizedBox.shrink(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: centertitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                         style: titleStyle ?? TextStyleCustom.unboundedMedium500(color: CupertinoColors.white),
                        // style: titleStyle ?? TextStyleCustom.unboundedMedium500(color: textDarkGrey(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isLoading)
                        CupertinoActivityIndicator(
                          color: textLightGrey(context),
                          radius: 8,
                        )
                      else if (subTitle != null)
                        Text(
                          subTitle ?? '',
                          style: TextStyleCustom.outFitLight300(
                            color: textLightGrey(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ) ,
                ),
                rowWidget ?? const SizedBox(width: 48)
              ],
            ),
            widget ?? const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class NewCustomAppBar extends StatelessWidget {
  const NewCustomAppBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(color: ColorRes.whitePure),
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      bottom: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      flexibleSpace: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: kAppBarGradient),
          ),
          Positioned(
            left: 150,
            right: 20,
            top: 8,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: 200,
            top: 20,
            right: 15,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

