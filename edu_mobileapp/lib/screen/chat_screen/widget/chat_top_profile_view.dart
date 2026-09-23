import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/navigation/navigate_with_controller.dart';
import 'package:geoedu/common/widget/custom_back_button.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/custom_popup_menu_button.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/chat/chat_thread.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/screen/chat_screen/chat_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class ChatTopProfileView extends StatelessWidget {
  final ChatScreenController controller;

  const ChatTopProfileView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: kAppBarGradient),
          ),
        ),
        Positioned(
          left: 150,
          right: 20,
          top: 8,
          child: Container(
            height: 40,
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
        Container(
          color: Colors.transparent,
          // color: bgLightGrey(context),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: SafeArea(
            bottom: false,
            child: Obx(() {
              ChatThread chatThread = controller.conversationUser.value;
              chatThread.bindChatUser();
              AppUser? chatUser = chatThread.chatUser;
              bool iBlocked = chatThread.iBlocked ?? false;
              return Row(
                spacing: 10,
                children: [
                  const CustomBackButton(
                    color: ColorRes.whitePure,
                    image: AssetRes.icBackArrow_1,
                    height: 25,
                    width: 25,
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        User user = User(
                          id: chatUser?.userId,
                          fullname: chatUser?.fullname,
                          username: chatUser?.username,
                          profilePhoto: chatUser?.profile,
                          isVerify: chatUser?.isVerify,
                        );
                        NavigationService.shared.openProfileScreen(
                          user,
                          onUserUpdate: (user) {
                            if (controller.otherUser?.id == user?.id) {
                              controller.otherUser = user;
                            }
                          },
                        );
                      },
                      child: Row(
                        spacing: 10,
                        children: [
                          CustomImage(
                              size: const Size(48, 48),
                              image: chatUser?.profile?.addBaseURL(),
                              fullName: chatUser?.fullname),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FullNameWithBlueTick(
                                    username: chatUser?.username ?? '',
                                    fontSize: 13,
                                    style: TextStyle(color: whitePure(context)),
                                    iconSize: 18,
                                    isVerify: chatUser?.isVerify),
                                Text(chatUser?.fullname ?? '',
                                    style: TextStyleCustom.outFitLight300(
                                        color: Colors.white,
                                        fontSize: 15))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPopupMenuButton(
                      items: [
                        MenuItem(
                          iBlocked ? LKey.unBlock.tr : LKey.block.tr,
                              () {
                            controller.toggleBlockUnblock(chatThread);
                          },
                        ),
                        MenuItem(
                          LKey.report.tr,
                              () {
                            controller.onReportUser(chatThread);
                          },
                        ),
                      ],
                      child: Container(
                          height: 36,
                          width: 36,
                          decoration: const BoxDecoration(
                              color: Colors.transparent, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(Icons.more_vert,color: whitePure(context),))),
                  // Image.asset(AssetRes.icMore, width: 25, height: 25)))
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
