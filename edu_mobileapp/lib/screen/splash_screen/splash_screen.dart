import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_shimmer_fill_text.dart';
import 'package:geoedu/common/widget/theme_blur_bg.dart';
import 'package:geoedu/screen/splash_screen/splash_screen_controller.dart';
import 'package:geoedu/utilities/app_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashScreenController());
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/splash_bg.png",
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("assets/images/app_logo.png",height: 150,width: 150,),
                CustomShimmerFillText(
                  text: AppRes.appName.toUpperCase(),
                  baseColor: whitePure(context),
                  textStyle: TextStyleCustom.unboundedBlack900(
                      color: whitePure(context), fontSize: 18),
                  finalColor: whitePure(context),
                  shimmerColor: themeAccentSolid(context),
                ),
              ],
            ),
          )

          // const ThemeBlurBg(),
          // Align(
          //   alignment: Alignment.center,
          //   child: CustomShimmerFillText(
          //     text: AppRes.appName.toUpperCase(),
          //     baseColor: whitePure(context),
          //     textStyle: TextStyleCustom.unboundedBlack900(
          //         color: whitePure(context), fontSize: 30),
          //     finalColor: whitePure(context),
          //     shimmerColor: themeAccentSolid(context),
          //   ),
          // )
        ],
      ),
    );
  }
}
