import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/model/chat/chat_thread.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/chat_screen/chat_screen.dart';
import 'package:geoedu/screen/message_screen/message_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class ChatConversationUserCard extends StatelessWidget {
  final ChatThread chatConversation;

  const ChatConversationUserCard({super.key, required this.chatConversation});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessageScreenController>();

    return InkWell(
      onTap: () {
        Get.to(
          () => ChatScreen(conversationUser: chatConversation, user: User(id: chatConversation.userId)),
        );
      },
      onLongPress: () => controller.onLongPress(chatConversation),
      child: Obx(() {
        AppUser? user = chatConversation.chatUserRx.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          ),
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            children: [
              CustomImage(size: const Size(47, 47), image: user?.profile?.addBaseURL(), fullName: user?.fullname),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 5,
                      children: [
                        FullNameWithBlueTick(
                          username: user?.username,
                          fontSize: 13,
                          style: TextStyle(
                            color: whitePure(context),
                          ),
                          iconSize: 18,
                          isVerify: user?.isVerify,
                        ),
                        Row(
                          children: [
                            Image.asset("assets/images/three.png",width: 25,height: 25,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8,vertical: 1),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(12),bottomRight: Radius.circular(12)),
                                  color: ColorRes.orangeDark,
                              ),
                              child: Text("Lvl 3",style: TextStyle(color: Colors.white,fontSize: 10),),
                            ),
                          ],
                        )
                      ],
                    ),
                    Text(chatConversation.lastMsg ?? '',
                        style: TextStyleCustom.outFitLight300(fontSize: 14, color: Colors.white24),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  ],
                ),
              ),
              Column(
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateTime.fromMillisecondsSinceEpoch(int.parse(chatConversation.id ?? '0')).toString().timeAgo,
                      style: TextStyleCustom.outFitLight300(fontSize: 13, color: Colors.white)),
                  Visibility(
                    visible: (chatConversation.msgCount ?? 0) > 0,
                    replacement: const SizedBox(height: 23),
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(color: themeAccentSolid(context), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${chatConversation.msgCount ?? 0}',
                        style: TextStyleCustom.outFitRegular400(fontSize: 12, color: whitePure(context)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }),
    );
  }
}
