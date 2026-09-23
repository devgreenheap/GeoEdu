import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/manager/share_manager.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/common/widget/custom_popup_menu_button.dart';
import 'package:geoedu/common/widget/my_refresh_indicator.dart';
import 'package:geoedu/common/widget/text_button_custom.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:geoedu/screen/message_screen/message_screen.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/screen/profile_screen/widget/profile_page_view.dart';
import 'package:geoedu/screen/profile_screen/widget/profile_tab_bar_view.dart';
import 'package:geoedu/screen/profile_screen/widget/profile_user_header.dart';
import 'package:geoedu/screen/settings_screen/settings_screen.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class ProfileScreen extends StatelessWidget {
  final User? user;
  final bool isTopBarVisible;
  final bool isDashBoard;
  final Function(User? user)? onUserUpdate;

  const ProfileScreen(
      {super.key,
        this.user,
        this.isTopBarVisible = true,
        this.isDashBoard = false,
        this.onUserUpdate});

  @override
  Widget build(BuildContext context) {
    ProfileScreenController controller = Get.put(
        ProfileScreenController(user.obs, onUserUpdate),
        tag: isDashBoard
            ? ProfileScreenController.tag
            : "${DateTime.now().millisecondsSinceEpoch}");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kAppBarGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isTopBarVisible ? 'Profile' : 'My Profile',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() {
            User? viewedUser = controller.userData.value;
            bool isMe = viewedUser?.id?.toInt() == SessionManager.instance.getUserID();
            return Row(
              children: [
                if (isMe) ...[
                  DiamondBalanceBadge(),
                  const SizedBox(width: 8),
                  Obx(() => IconButton(
                        icon: Badge(
                          isLabelVisible: Get.find<DashboardScreenController>().unReadCount.value > 0,
                          label: Text('${Get.find<DashboardScreenController>().unReadCount.value}'),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                        ),
                        onPressed: () => Get.to(() => const MessageScreen()),
                      )),
                ],
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                  onPressed: () =>
                      ShareManager.shared.showCustomShareSheet(user: viewedUser, keys: ShareKeys.user),
                ),
                if (isMe)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () =>
                        Get.to(() => SettingsScreen(onUpdateUser: controller.onUpdateUser)),
                  )
                else
                  CustomPopupMenuButton(
                    items: [
                      MenuItem(viewedUser?.isBlock == true ? LKey.unBlock.tr : LKey.block.tr, () {
                        controller.toggleBlockUnblock(viewedUser?.isBlock ?? false);
                      }),
                      MenuItem(LKey.report.tr, () => controller.reportUser(viewedUser)),
                      if (SessionManager.instance.isModerator.value == 1)
                        MenuItem(
                            viewedUser?.isFreez == 1 ? LKey.unFreeze.tr : LKey.freeze.tr,
                            () => controller.freezeUnfreezeUser(viewedUser?.isFreez == 1))
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            );
          }),
        ],
      ),
      body: PopScope(
        onPopInvokedWithResult: (didPop, result) {
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Obx((){
                      if (controller.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white,),
                        );
                      }
                      return DefaultTabController(
                        length: 2,
                        child: MyRefreshIndicator(
                          depth: 4,
                          onRefresh: controller.onRefresh,
                          child: NestedScrollView(
                            headerSliverBuilder: (context, _) {
                              return [
                                SliverList(
                                  delegate: SliverChildListDelegate([
                                    ProfileUserHeader(controller: controller, isTopBarVisible: isTopBarVisible,)
                                  ]),
                                ),
                              ];
                            },
                            body: Column(
                              children: [
                                ProfileTabs(controller: controller),
                                ProfilePageView(controller: controller)
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    Obx(() {
                      User? user = controller.userData.value;
                      if (user?.isFreez != 1) {
                        return const SizedBox();
                      }
                      return Container(
                        color: scaffoldBackgroundColor(context)
                            .withValues(alpha: 0.4),
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_person_rounded,
                                    size: 80, color: textLightGrey(context)),
                                const SizedBox(height: 20),
                                Text(
                                  LKey.profileUnavailable.tr,
                                  style: TextStyleCustom.unboundedSemiBold600(
                                      color: textLightGrey(context),
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30.0),
                                  child: Text(
                                    LKey.profileTemporarilyFrozen.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyleCustom.outFitMedium500(
                                        color: textLightGrey(context),
                                        fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Obx(() {
                                  bool isModerator = SessionManager
                                      .instance.isModerator.value ==
                                      1;
                                  if (!isModerator) {
                                    return const SizedBox();
                                  }
                                  return TextButtonCustom(
                                    onTap: () =>
                                        controller.freezeUnfreezeUser(true),
                                    title: LKey.unFreeze.tr,
                                    titleColor: whitePure(context),
                                    backgroundColor: textDarkGrey(context),
                                  );
                                })
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
