import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/custom_search_text_field.dart';
import 'package:geoedu/common/widget/custom_tab_switcher.dart';
import 'package:geoedu/common/widget/gradient_border.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/common/widget/no_data_widget.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/chat/chat_thread.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kSecondaryHeaderGradient;
import 'package:geoedu/screen/audio_call/audio_call_list_screen.dart' show kAudioChatCardGradient;
import 'package:geoedu/screen/message_screen/message_screen_controller.dart';
import 'package:geoedu/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';
import '../../utilities/asset_res.dart';
import '../blocked_user_screen/blocked_user_screen.dart';
import '../invite_screen/invite_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageScreenController());
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          LKey.messages.tr,
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
              decoration: const BoxDecoration(gradient: kAudioChatCardGradient),
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: kSecondaryHeaderGradient),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 10,),
              CustomSearchTextField(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                gradient: true,
                searchTextColor: Colors.white,
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
              ),
              Column(
                children: [
                  Obx(() {
                    final filtered = controller.filteredSuggestedUsers;
                    if (filtered.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(AssetRes.chatStarIcon, height: 24),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Start a Conversation',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Get.to(() => const InviteScreen()),
                                    child: GradientBorder(
                                      strokeWidth: 1,
                                      radius: 20,
                                      gradient: kAudioChatCardGradient,
                                      child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.group, size: 14, color: ColorRes.primaryColor),
                                          SizedBox(width: 6),
                                          Text(
                                            "Invite",
                                            style: TextStyle(color: Colors.white, fontSize: 9),
                                          ),
                                        ],
                                      ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 22, color: Colors.white),
                                    color: ColorRes.cardBackground,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      if (value == 'blocked') {
                                        Get.to(() => const BlockedUserScreen());
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'blocked',
                                        child: Row(
                                          children: [
                                            Icon(Icons.block, color: Colors.white70, size: 18),
                                            SizedBox(width: 8),
                                            Text('Blocked Contacts', style: TextStyle(color: Colors.white, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            separatorBuilder: (context, i) => const SizedBox(width: 10),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final AppUser user = filtered[index];
                              return Container(
                                width: 130,
                                child: GradientBorder(
                                  strokeWidth: 1.2,
                                  radius: 16,
                                  gradient: kAudioChatCardGradient,
                                  child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ColorRes.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    /// Profile Image
                                    CustomImage(
                                      size: const Size(72, 72),
                                      image: (user.profile ?? '').addBaseURL(),
                                      fullName: user.fullname,
                                    ),

                                    /// Name
                                    Text(
                                      user.fullname ?? '',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 5),
                                    GestureDetector(
                                      onTap: () => controller.startChat(user),
                                      child: Container(
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: ColorRes.primaryColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(AssetRes.chatIcon3, height: 14),
                                            const SizedBox(width: 6),
                                            const Text(
                                              "Say Hi",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                  CustomTabSwitcher(
                    border: false,
                    backgroundColor: ColorRes.cardBackground.withValues(alpha: 0.85),
                    selectedFontColor: ColorRes.primaryColor,
                    items: controller.chatCategories,
                    frontWidget: Row(
                      children: [
                        Image.asset(AssetRes.chatIcon1, height: 15),
                        const SizedBox(width: 8),
                      ],
                    ),
                    onTap: (index) {
                      controller.onPageChanged(index);
                      controller.pageController.animateToPage(index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear);
                    },
                    selectedIndex: controller.selectedChatCategory,
                    widget: Obx(() {
                      int length = controller.dashboardController.requestUnReadCount.value;
                      if (length <= 0) {
                        return const SizedBox();
                      }
                      return Container(
                        height: 22,
                        width: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: ColorRes.likeRed),
                        alignment: Alignment.center,
                        child: Text(
                          '$length',
                          style: TextStyleCustom.outFitRegular400(
                              fontSize: 12, color: whitePure(context)),
                        ),
                      );
                    }),
                    widgetTabIndex: 1,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ],
              ),

              Expanded(
                child: Obx(
                      () => controller.isLoading.value &&
                      (controller.selectedChatCategory.value == 0
                          ? controller.chatsUsers.isEmpty
                          : controller.requestsUsers.isEmpty)
                      ? const LoaderWidget()
                      : PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    children: const [
                      ChatsListView(),
                      RequestsListView(),
                    ],
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

class ChatsListView extends StatelessWidget {
  const ChatsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();
    return Obx(() {
      return NoDataView(
        showShow: controller.chatsUsers.isEmpty,
        title: LKey.chatListEmptyTitle.tr,
        description: LKey.chatListEmptyDescription.tr,
        child: ListView.builder(
          itemCount: controller.chatsUsers.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            ChatThread chatConversation = controller.chatsUsers[index];
            chatConversation.bindChatUser();
            return ChatConversationUserCard(chatConversation: chatConversation);
          },
        ),
      );
    });
  }
}

class RequestsListView extends StatelessWidget {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();

    return Obx(
      () => NoDataView(
        showShow: controller.requestsUsers.isEmpty,
        title: LKey.chatRequestEmptyTitle.tr,
        description: LKey.chatRequestEmptyDescription.tr,
        child: ListView.builder(
          itemCount: controller.requestsUsers.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            ChatThread chatConversation = controller.requestsUsers[index];
            chatConversation.bindChatUser();
            return ChatConversationUserCard(chatConversation: chatConversation);
          },
        ),
      ),
    );
  }
}
