import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:geoedu/screen/explore_screen/explore_screen.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/style_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class DashboardScreen extends StatelessWidget {
  final User? myUser;

  const DashboardScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardScreenController());
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (controller.selectedPageIndex.value != 0) {
            controller.onChanged(0);
            return;
          }
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
        backgroundColor: scaffoldBackgroundColor(context),
        resizeToAvoidBottomInset: true,
        body: Obx(() {
            return Column(
              children: [
                Expanded(
                  child: ProsteIndexedStack(
                    index: controller.selectedPageIndex.value,
                    children: [
                      IndexedStackChild(child: LiveStreamSearchScreen(myUser: myUser), preload: true),
                      IndexedStackChild(child: const ExploreScreen(), preload: false),
                      IndexedStackChild(
                          child: const StarStoreDiamondScreen(showBackButton: false), preload: false),
                      // "Live" tab shows the same live-rooms browse screen/data
                      // as Home (the reference screenshot itself labels this
                      // screen "Home / Live Tab" as one target) rather than a
                      // separate, undifferentiated duplicate feature.
                      IndexedStackChild(child: LiveStreamSearchScreen(myUser: myUser), preload: false),
                    ],
                  ),
                ),
              ],
            );
          }),
        bottomNavigationBar: _buildBottomNavigationBar(context, controller),
      ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return Obx(() {
      PostUploadingProgress postUpload = controller.postProgress.value;
      bool isPostUploading =
      postUpload.uploadType == UploadType.none ? false : true;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: blackPure(context),
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                controller.bottomIcons.length,
                (index) {
                  return _buildBottomNavItem(
                      context, controller, index, isPostUploading);
                },
              ),
            ),
            SafeArea(
              top: false,
              bottom: isPostUploading ? true : false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: isPostUploading ? 30 : 0,
                margin: Platform.isAndroid || !isPostUploading
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 20, top: 5),
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                        height: 30,
                        decoration:
                            BoxDecoration(gradient: StyleRes.themeGradient)),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LayoutBuilder(builder: (context, constraints) {
                        double progress =
                            (constraints.maxWidth * postUpload.progress) / 100;
                        return AnimatedContainer(
                          height: 30,
                          width: constraints.maxWidth - progress,
                          duration: const Duration(milliseconds: 250),
                          decoration:
                              BoxDecoration(color: textDarkGrey(context)),
                        );
                      }),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (postUpload.uploadType != UploadType.error)
                            Text('${postUpload.progress.toInt()}%',
                                style: TextStyleCustom.outFitMedium500(
                                  color: whitePure(context),
                                  fontSize: 16,
                                )),
                          Text(
                              ' ${postUpload.uploadType.title(postUpload.type)}',
                              style: TextStyleCustom.outFitLight300(
                                  color: whitePure(context), fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buildBottomNavItem(BuildContext context,
      DashboardScreenController controller, int index, bool isPostUploading) {
    return Obx(() {
      final isSelected = controller.selectedPageIndex.value == index;
      final scaleValue = isSelected ? controller.scaleValue.value : 1.0;

      return SafeArea(
        bottom: isPostUploading ? false : true,
        child: GestureDetector(
          onTap: () => controller.onChanged(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: AnimatedScale(
              scale: scaleValue,
              duration: const Duration(milliseconds: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorRes.primaryColor.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      controller.bottomIcons[index],
                      size: 23,
                      color: isSelected ? ColorRes.primaryColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    controller.bottomNameList[index],
                    style: TextStyle(
                      color: isSelected ? ColorRes.primaryColor : Colors.white,
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double curveWidth = 90.0;
    double centerX = size.width / 2;

    path.moveTo(0, 0);

    path.lineTo(centerX - (curveWidth / 2) - 15, 0);

    path.cubicTo(
      centerX - (curveWidth / 2), 0,
      centerX - (curveWidth / 3), 35,
      centerX, 35,
    );

    path.cubicTo(
      centerX + (curveWidth / 3), 35,
      centerX + (curveWidth / 2), 0,
      centerX + (curveWidth / 2) + 15, 0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}