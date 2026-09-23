import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/common/widget/no_data_widget.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/block_user_model.dart';
import 'package:geoedu/screen/blocked_user_screen/blocked_user_screen_controller.dart';
import 'package:geoedu/screen/follow_following_screen/follow_following_screen.dart';
import 'package:geoedu/utilities/theme_res.dart';

import '../../utilities/text_style_custom.dart';

class BlockedUserScreen extends StatelessWidget {
  const BlockedUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlockedUserScreenController());
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(LKey.blockedUsers.tr,style: TextStyleCustom.unboundedMedium500(color: whitePure(context)),),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        elevation: 0,
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
      ),
      body: Stack(
        children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: kSecondaryHeaderGradient))),
          Column(
            children: [
              // CustomAppBar(title: LKey.blockedUsers.tr),
              Expanded(
                child: Obx(
                  () =>
                      controller.isLoading.value && controller.blockedUsers.isEmpty
                          ? const LoaderWidget()
                          : NoDataView(
                              showShow: !controller.isLoading.value &&
                                  controller.blockedUsers.isEmpty,
                              title: LKey.blockListEmptyTitle,
                              description: LKey.blockListEmptyDescription,
                              child: RefreshIndicator(
                                onRefresh: () async => controller.fetchBlockedUsers(),
                                child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: controller.blockedUsers.length,
                                    padding: const EdgeInsets.only(top: 10),
                                    itemBuilder: (context, index) {
                                      BlockUsers user =
                                          controller.blockedUsers[index];
                                      return UserProfileTile(
                                          actionName: ActionName.block,
                                          onTap: () =>
                                              controller.unblockUser(user.toUser, () {
                                                controller.blockedUsers.removeWhere(
                                                    (element) =>
                                                        element.toUserId ==
                                                        user.toUserId);
                                              }),
                                          isFollowOrIsBlock: true,
                                          user: user.toUser);
                                    }),
                              ),
                            ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
