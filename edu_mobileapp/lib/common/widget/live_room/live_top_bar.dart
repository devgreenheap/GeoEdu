import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/leader_board/leader_board_screen.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/profile_screen/profile_screen.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/screen/search_screen/search_user_list_screen.dart';
import 'package:geoedu/screen/select_language_screen/select_language_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';

/// A small circular pill used across the live-room top bar for icon
/// buttons, with an optional numeric badge (used for the Chat unread
/// count). Generalizes the icon-chip pattern that used to be inlined as
/// `_TopBarIconChip` in live_stream_search_screen.dart.
class StatPill extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final int badgeCount;

  const StatPill({
    super.key,
    required this.onTap,
    required this.child,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ColorRes.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: child,
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(color: ColorRes.liveRed, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Top bar for the Home/Live screens: language, trophy (Leaderboard),
/// search, Go Live pill, profile avatar — only these. Diamond wallet, Chat
/// and Menu moved into the Profile screen's own app bar instead.
class LiveTopBar extends StatelessWidget {
  final LiveStreamSearchScreenController controller;
  final User? myUser;

  const LiveTopBar({super.key, required this.controller, this.myUser});

  @override
  Widget build(BuildContext context) {
    ProfileScreenController profileScreenController = Get.put(
        ProfileScreenController(myUser.obs, null),
        tag: "${DateTime.now().millisecondsSinceEpoch}");

    return SafeArea(
      minimum: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              StatPill(
                onTap: () {
                  Get.to(() => const SelectLanguageScreen(
                      languageNavigationType: LanguageNavigationType.fromSetting));
                },
                child: const Text('த', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              StatPill(
                onTap: () => Get.to(() => const LeaderBoardScreen()),
                child: Image.asset(AssetRes.medalIcon, height: 20),
              ),
            ],
          ),
          Row(
            children: [
              StatPill(
                onTap: () => Get.to(() => SearchUserListScreen(myUser: myUser)),
                child: Image.asset(AssetRes.searchIcon, height: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: controller.onGoLive,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: ColorRes.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(LKey.goLive.tr, style: TextStyleCustom.unboundedMedium500(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                User? user = profileScreenController.userData.value;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProfileScreen(isDashBoard: false, user: myUser, isTopBarVisible: false)));
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ColorRes.primaryColor, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CustomImage(
                      size: const Size(80, 80),
                      image: user?.isBlock == true ? '' : user?.profilePhoto?.addBaseURL(),
                      fullName: user?.fullname,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
