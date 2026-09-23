import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoedu/screen/leader_board/top_gifters_screen.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/custom_popup_menu_button.dart';
import 'package:geoedu/common/widget/gradient_border.dart';
import 'package:geoedu/common/widget/text_button_custom.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/follow_following_screen/followers_screen.dart';
import 'package:geoedu/screen/level_screen/level_screen_2/level_screen_new.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/screen/profile_screen/widget/profile_preview_interactive_screen.dart';
import 'package:geoedu/screen/profile_screen/widget/user_link_sheet.dart';
import 'package:geoedu/screen/settings_screen/settings_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/style_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

import 'package:geoedu/screen/diamond_purchase/diamond_purchase_screen.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import '../../../utilities/color_res.dart';
import '../../follow_following_screen/following_screen.dart';

/// GIO EDU brand gradient (orange -> gold) — used for the Lvl badge,
/// replacing the old purple-pink/blue accents.
const _kProfileAccentGradient = LinearGradient(
  colors: [ColorRes.primaryColor, ColorRes.gold],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Avatar-ring gradient when there's no story to show — matches the same
/// orange -> orange-dark gradient used for the Edit Profile step indicator.
const _kAvatarRingSolidOrange = LinearGradient(
  colors: [ColorRes.primaryColor, ColorRes.orangeDark],
);

class ProfileUserHeader extends StatelessWidget {
  final ProfileScreenController controller;
  final bool isTopBarVisible;

  const ProfileUserHeader({super.key, required this.controller, required this.isTopBarVisible});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        User? user = controller.userData.value;
        bool isUserNotFound = controller.isUserNotFound.value;
        bool isMe = user?.id?.toInt() == SessionManager.instance.getUserID();

        if (isUserNotFound) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: NoUserFoundButton(),
          );
        }

        return Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileStatsRow(
                    userNotFound: isUserNotFound,
                    controller: controller,
                    user: user,
                    showEditBadge: isMe,
                    stats: const [],
                    onTap: (value) {},
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.fullname ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => controller.handlePublishOrMessageBtn(true),
                                  child: const Icon(Icons.edit, color: Colors.white70, size: 18),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Get.to(() => const TopGiftersScreen()),
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff2A2318),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(AssetRes.medalIcon, height: 18),
                                      const SizedBox(width: 6),
                                      const Text('Top Gifter',
                                          style: TextStyle(
                                              color: ColorRes.primaryColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              if (user?.getLevel.id != null) ...[
                                const SizedBox(width: 8),
                                GradientBorder(
                                  onPressed: () => Get.to(() => const LevelScreenNew()),
                                  strokeWidth: 1.5,
                                  radius: 30,
                                  gradient: _kProfileAccentGradient,
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    alignment: Alignment.center,
                                    child: ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) => _kProfileAccentGradient
                                          .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                      child: RichText(
                                        text: TextSpan(
                                          text: LKey.lvl.tr,
                                          style: TextStyleCustom.outFitLight300(fontSize: 13),
                                          children: [
                                            TextSpan(
                                                text: ' ${user?.getLevel.level ?? 0}',
                                                style: TextStyleCustom.outFitBold700(fontSize: 13))
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if ((user?.bio ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              user!.bio!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _StatsBox(
                user: user,
                onFollowers: () {
                  user?.checkIsBlocked(() {
                    Get.to(() => FollowersScreen(user: user));
                  });
                },
                onFollowing: () {
                  user?.checkIsBlocked(() {
                    Get.to(() => FollowingsScreen(user: user));
                  });
                },
              ),
              UserLinkView(user: user),
              UserButtonView(user: user, controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _StatsBox extends StatelessWidget {
  final User? user;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;

  const _StatsBox({required this.user, required this.onFollowers, required this.onFollowing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: ColorRes.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.people_alt_rounded,
              iconColor: ColorRes.gold,
              value: user?.followerCount ?? 0,
              label: 'Followers',
              onTap: onFollowers,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(
            child: _StatCell(
              icon: Icons.person_rounded,
              iconColor: ColorRes.green1,
              value: user?.followingCount ?? 0,
              label: 'Following',
              onTap: onFollowing,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final num value;
  final String label;
  final VoidCallback onTap;

  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value.toInt().numberFormat,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  final User? user;
  final List<StatItem> stats;
  final Function(int value) onTap;
  final ProfileScreenController controller;
  final bool userNotFound;
  final bool showEditBadge;

  const ProfileStatsRow({
    super.key,
    required this.user,
    required this.stats,
    required this.onTap,
    required this.controller,
    required this.userNotFound,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isStoryAvailable = (user?.stories ?? []).isNotEmpty;
    GlobalKey previewKey = GlobalKey();
    bool isWatch = isStoryAvailable && (user?.stories ?? []).every((element) => element.isWatchedByMe());
    RxBool isHeroEnable = false.obs;

    return Row(
      children: [
        // Profile Picture
        if (userNotFound)
          Image.asset(AssetRes.icUserPlaceholder, width: 80, height: 80, fit: BoxFit.cover)
        else
          GestureDetector(
            onTap: () => controller.onStoryTap(isStoryAvailable),
            onLongPressStart: (details) {
              isHeroEnable.value = true;
            },
            onLongPressEnd: (details) {
              isHeroEnable.value = false;
            },
            onLongPress: () {
              user?.checkIsBlocked(() {
                // _showProfilePreview(context, previewKey, user);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.transparent,
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (_, __, ___) => ProfilePreviewInteractiveScreen(user: user)),
                );
              });
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: previewKey,
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    gradient: isStoryAvailable
                        ? (isWatch
                        ? StyleRes.disabledGreyGradient(opacity: .5)
                        : StyleRes.themeGradient)
                        : _kAvatarRingSolidOrange,
                  ),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Obx(() => HeroMode(
                      enabled: isHeroEnable.value,
                      child: Hero(
                        tag: 'profile-${user?.id}',
                        child: ClipOval(
                          child: CustomImage(
                            size: const Size(72, 72),
                            image: user?.isBlock == true
                                ? ''
                                : user?.profilePhoto?.addBaseURL(),
                            fullName: user?.fullname,
                          ),
                        ),
                      ),
                    )),
                  ),
                ),
                if (showEditBadge)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => controller.handlePublishOrMessageBtn(true),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Stats Columns
        // Expanded(
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //     children: List.generate(
        //       stats.length,
        //       (index) => Expanded(
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceAround,
        //           children: [
        //             InkWell(
        //               onTap: () => onTap(index),
        //               child: StatColumn(value: stats[index].value, label: stats[index].label),
        //             ),
        //             if (index != stats.length - 1) Container(height: 20, width: .5, color: textLightGrey(context)),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

// Individual Stat Column Widget
class StatColumn extends StatelessWidget {
  final num value;
  final String label;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const StatColumn({super.key, required this.value, required this.label, this.labelStyle, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toInt().numberFormat,
          style: valueStyle ??
              TextStyleCustom.unboundedMedium500(
                color: textDarkGrey(context),
                fontSize: 15,
              ),
        ),
        Text(label.capitalize ?? '',
            style: labelStyle ??
                TextStyleCustom.outFitLight300(
                  color: textLightGrey(context),
                  fontSize: 15,
                )),
      ],
    );
  }
}

class UserLinkView extends StatelessWidget {
  final User? user;

  const UserLinkView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    List<Link> links = user?.links ?? [];
    if (links.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: InkWell(
          onTap: () {
            user?.checkIsBlocked(() {
              if (links.length > 1) {
                Get.bottomSheet(UserLinkSheet(links: links),
                    isScrollControlled: true, barrierColor: blackPure(context).withValues(alpha: .7));
              } else {
                (links.first.url ?? '').lunchUrlWithHttps;
              }
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AssetRes.icLink, height: 20, width: 20, color: themeAccentSolid(context)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(shortUrl,
                    style: TextStyleCustom.outFitRegular400(fontSize: 15, color: themeAccentSolid(context))),
              )
            ],
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  String get shortUrl {
    List<Link> links = user?.links ?? [];
    String firstLink = links.first.url ?? '';
    String andMore = '';
    if (firstLink.length >= 40) {
      int endCount = links.length > 1 ? 25 : 35;
      firstLink = '${firstLink.substring(0, endCount)}...';
    }
    if (links.length > 1) {
      andMore = ' & ${links.length - 1} ${LKey.more.tr.toLowerCase()}';
    }
    return '$firstLink$andMore';
  }
}

class UserBioView extends StatelessWidget {
  final User? user;

  const UserBioView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if ((user?.bio ?? '').isEmpty) {
      return const SizedBox();
    }
    return Text(
      user?.bio ?? '',
      style: TextStyleCustom.outFitLight300(color: textLightGrey(context), fontSize: 16),
    );
  }
}

class UserButtonView extends StatelessWidget {
  final User? user;
  final ProfileScreenController controller;

  const UserButtonView({super.key, required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    User? user = controller.profileController.user;

    bool isMe = user?.id?.toInt() == SessionManager.instance.getUserID();
    bool isBlock = (user?.isBlock == true && user?.id != SessionManager.instance.getUserID());

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0, top: 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () => controller.handlePublishOrMessageBtn(true),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: BecomeHostButton()),
              ],
            ),
            const SizedBox(height: 10),
            const BecomeAgentButton(),
            if (SessionManager.instance.getUser()?.isAgent == 1) ...[
              const SizedBox(height: 10),
              AgentReferIdView(user: user),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, top: 10, left: 10, right: 10),
      child: Row(
        children: [
          Expanded(
            child: isBlock
                ? UnblockButton(onTap: () => controller.toggleBlockUnblock(true))
                : RowButton(controller: controller, isMe: isMe, user: user),
          ),
          const SizedBox(width: 8),
          Obx(
            () => CustomPopupMenuButton(
                items: [
                  MenuItem(user?.isBlock == true ? LKey.unBlock.tr : LKey.block.tr, () {
                    controller.toggleBlockUnblock(user?.isBlock ?? false);
                  }),
                  MenuItem(LKey.report.tr, () => controller.reportUser(user)),
                  if (SessionManager.instance.isModerator.value == 1)
                    MenuItem(user?.isFreez == 1 ? LKey.unFreeze.tr : LKey.freeze.tr,
                        () => controller.freezeUnfreezeUser(user?.isFreez == 1))
                ],
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1)),
                    color: bgGrey(context),
                  ),
                  child: Image.asset(AssetRes.icMore, height: 21, width: 21),
                )),
          )
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ColorRes.primaryColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class BecomeHostButton extends StatelessWidget {
  const BecomeHostButton({super.key});

  void _confirmBecomeHost(BuildContext context) {
    Get.bottomSheet(
      ConfirmationSheet(
        title: 'Become a Host',
        description: 'Are you sure you want to become a host? Your request will be sent for approval.',
        positiveText: 'Yes, Become Host',
        onTap: () => _requestBecomeHost(context),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _requestBecomeHost(BuildContext context) async {
    try {
      final result = await GiftWalletService.instance.requestBecomeHost();
      Get.snackbar(
        result.status == true ? 'Request Sent' : 'Request Failed',
        result.message ?? '',
        backgroundColor: result.status == true ? Colors.green : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (_) {
      Get.snackbar('Error', 'Something went wrong',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
    final bool isHost = user?.isHost == 1;

    return InkWell(
      onTap: isHost ? null : () => _confirmBecomeHost(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isHost
              ? null
              : const LinearGradient(colors: [ColorRes.primaryColor, ColorRes.orangeDark]),
          color: isHost ? Colors.grey.shade800 : null,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_rounded, color: isHost ? Colors.white54 : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              isHost ? 'Host' : 'Become Host',
              style: TextStyle(
                color: isHost ? Colors.white54 : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isHost) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class BecomeAgentButton extends StatelessWidget {
  const BecomeAgentButton({super.key});

  void _confirmBecomeAgent(BuildContext context) {
    Get.bottomSheet(
      ConfirmationSheet(
        title: 'Become an Agent',
        description: 'Are you sure you want to become an agent? Your request will be sent for approval.',
        positiveText: 'Yes, Become Agent',
        onTap: () => _requestBecomeAgent(context),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _requestBecomeAgent(BuildContext context) async {
    try {
      final result = await GiftWalletService.instance.requestBecomeAgent();
      Get.snackbar(
        result.status == true ? 'Request Sent' : 'Request Failed',
        result.message ?? '',
        backgroundColor: result.status == true ? Colors.green : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (_) {
      Get.snackbar('Error', 'Something went wrong',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
    final bool isAgent = user?.isAgent == 1;
    final int referralCount = user?.totalReferralCount ?? 0;
    final bool canBecomeAgent = !isAgent && referralCount >= 15;

    return InkWell(
      onTap: canBecomeAgent ? () => _confirmBecomeAgent(context) : null,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ColorRes.primaryColor.withValues(alpha: canBecomeAgent || isAgent ? 1 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic_rounded,
                color: (canBecomeAgent || isAgent) ? Colors.white : Colors.white38, size: 20),
            const SizedBox(width: 8),
            Text(
              isAgent ? 'Agent' : 'Become Agent',
              style: TextStyle(
                color: (canBecomeAgent || isAgent) ? Colors.white : Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isAgent) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            ],
            if (!isAgent) ...[
              const SizedBox(width: 4),
              Text('($referralCount/15)', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class AgentReferIdView extends StatelessWidget {
  final User? user;
  const AgentReferIdView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final referId = '${user?.fullname?.replaceAll(' ', '') ?? ''}${user?.id ?? ''}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Refer ID: ',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: referId,
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: referId));
              Get.snackbar('Copied', 'Refer ID copied to clipboard',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP);
            },
            child: const Icon(Icons.copy, color: Colors.orange, size: 18),
          ),
        ],
      ),
    );
  }
}

class NoUserFoundButton extends StatelessWidget {
  const NoUserFoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButtonCustom(
      onTap: () {},
      title: LKey.userNotFound.tr,
      btnHeight: 40,
      backgroundColor: bgMediumGrey(context),
      fontSize: 15,
      radius: 8,
      titleColor: textLightGrey(context),
      margin: const EdgeInsets.only(bottom: 10, left: 40, right: 40, top: 20),
    );
  }
}

class UnblockButton extends StatelessWidget {
  final VoidCallback onTap;

  const UnblockButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButtonCustom(
      onTap: onTap,
      title: LKey.unBlock.tr,
      fontSize: 16,
      backgroundColor: blueFollow(context),
      titleColor: whitePure(context),
      horizontalMargin: 0,
      btnHeight: 45,
    );
  }
}

class RowButton extends StatelessWidget {
  final bool isMe;
  final ProfileScreenController controller;
  final User? user;

  const RowButton({
    super.key,
    required this.isMe,
    required this.controller,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () {
              bool isFollowProgress = controller.isFollowUnFollowInProcess.value;
              Color textColor = user?.isFollowing == true ? Colors.white : whitePure(context);
              return TextButtonCustom(
                onTap: () async {
                  if (isMe) {
                    Get.to(() => SettingsScreen(onUpdateUser: controller.onUpdateUser));
                  } else {
                    if (!isFollowProgress) {
                      controller.followUnFollowUser();
                    }
                  }
                },
                title: isMe ? LKey.settings.tr : (user?.isFollowing == true ? LKey.unFollow.tr : LKey.follow.tr),
                fontSize: 16,
                backgroundColor: isMe ? ColorRes.primaryColor : (user?.isFollowing == true ? Colors.red : blueFollow(context)),
                titleColor: isMe ? Colors.black : textColor,
                horizontalMargin: 0,
                btnHeight: 45,
                child: isMe
                    ? null
                    : isFollowProgress
                        ? CupertinoActivityIndicator(radius: 10, color: textColor)
                        : null,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        if (isMe || user?.receiveMessage == 1)
          Expanded(
            child: TextButtonCustom(
                onTap: () => controller.handlePublishOrMessageBtn(isMe),
                title: isMe ? LKey.editProfile.tr : LKey.message.tr,
                fontSize: 16,
                backgroundColor: Colors.green,
                titleColor: Colors.white,
                horizontalMargin: 0,
                btnHeight: 45),
          ),
      ],
    );
  }
}

// Stat Item Model
class StatItem {
  final num value;
  final String label;

  StatItem({required this.value, required this.label});
}

class DiamondBalanceBadge extends StatefulWidget {
  @override
  State<DiamondBalanceBadge> createState() => DiamondBalanceBadgeState();
}

class DiamondBalanceBadgeState extends State<DiamondBalanceBadge> {
  int balance = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final wallet = await GiftWalletService.instance.fetchMyDiamondWallet();
      if (mounted) {
        setState(() => balance = wallet.data?.diamondBalance ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => DiamondPurchaseScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetRes.editDiamond, height: 16, width: 16),
            const SizedBox(width: 5),
            Text(
              '$balance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
