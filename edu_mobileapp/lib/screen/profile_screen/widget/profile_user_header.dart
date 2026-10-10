import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoedu/screen/leader_board/top_gifters_screen.dart';
import 'package:geoedu/screen/star_wallet_screen/star_wallet_screen.dart';
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
import 'package:geoedu/screen/profile_screen/profile_screen.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/screen/profile_screen/widget/profile_preview_interactive_screen.dart';
import 'package:geoedu/screen/profile_screen/widget/user_link_sheet.dart';
import 'package:geoedu/screen/profile_screen/widget/host_interview_recording_screen.dart';
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

        final bool isHost = user?.isHost == 1;
        final bannerName = (user?.fullname ?? (isHost ? 'HOST' : 'GIFTER')).toUpperCase();

        return Container(
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Orange Event Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, bottom: 44, left: 16, right: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF2200), Color(0xFFFF5500), Color(0xFFFF7A00)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '★  $bannerName  ★',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHost ? '★ Official Live Host ★' : '★ On GioEdu ★',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.black87, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Live Sessions & Highlights',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9500), Color(0xFFFF5E00)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9500).withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Gifter & Supporter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Overlapping Avatar and "Top Gifters" Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -38),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Profile Avatar with Glowing Gold/White Ring
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9900).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CustomImage(
                            size: const Size(86, 86),
                            image: user?.isBlock == true ? '' : user?.profilePhoto?.addBaseURL(),
                            fullName: user?.fullname,
                          ),
                        ),
                      ),

                      // Badges on the right of avatar: "Stars Wallet" & "Top Gifters"
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "Stars Wallet" Pill Button
                          GestureDetector(
                            onTap: () => Get.to(() => const StarWalletScreen()),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A1F18),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    AssetRes.editStar,
                                    height: 16,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFF9F0A),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Stars Wallet',
                                    style: TextStyle(
                                      color: Color(0xFFFF9F0A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // "Top Gifters" Pill Button
                          GestureDetector(
                            onTap: () => Get.to(() => const TopGiftersScreen()),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A1F18),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(AssetRes.medalIcon, height: 16),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Top Gifters',
                                    style: TextStyle(
                                      color: Color(0xFFFF9F0A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // User Info (Name + Verified Badge)
              Transform.translate(
                offset: const Offset(0, -26),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.fullname ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF2196F3),
                            size: 22,
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
                      if ((user?.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          user!.bio!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Followers & Following Dark Box
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
                      const SizedBox(height: 12),

                      // Primary Orange Follow Button
                      _ProfileMainFollowButton(
                        user: user,
                        isMe: isMe,
                        controller: controller,
                      ),
                      // "Similar Hosts To Follow" Section (Real Time Data - shown for Hosts)
                      if (isHost) ...[
                        _SimilarHostsToFollowSection(controller: controller),
                        const SizedBox(height: 8),
                      ],

                      UserLinkView(user: user),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMainFollowButton extends StatelessWidget {
  final User? user;
  final bool isMe;
  final ProfileScreenController controller;

  const _ProfileMainFollowButton({
    required this.user,
    required this.isMe,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Row(
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
      );
    }

    return Obx(() {
      final isFollowing = user?.isFollowing == true;
      final isProgress = controller.isFollowUnFollowInProcess.value;

      return GestureDetector(
        onTap: () {
          if (!isProgress) controller.followUnFollowUser();
        },
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: isFollowing
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFF4500), Color(0xFFFF6600)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: isFollowing ? const Color(0xFF2A2A2A) : null,
            border: isFollowing ? Border.all(color: Colors.white24) : null,
          ),
          alignment: Alignment.center,
          child: isProgress
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isFollowing) ...[
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

class _SimilarHostsToFollowSection extends StatelessWidget {
  final ProfileScreenController controller;

  const _SimilarHostsToFollowSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hosts = controller.similarHosts;
      final liveIds = controller.liveHostUserIds;

      if (hosts.isEmpty && controller.isSimilarHostsLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CupertinoActivityIndicator(color: Colors.white54),
          ),
        );
      }

      if (hosts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Similar Hosts To Follow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: hosts.length,
              itemBuilder: (context, index) {
                final host = hosts[index];
                final isLive = liveIds.contains(host.id);
                return _SimilarHostCard(
                  host: host,
                  isLive: isLive,
                  controller: controller,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }
}

class _SimilarHostCard extends StatelessWidget {
  final User host;
  final bool isLive;
  final ProfileScreenController controller;

  const _SimilarHostCard({
    required this.host,
    required this.isLive,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar with Live badge
          GestureDetector(
            onTap: () {
              if (isLive) {
                controller.openLiveStreamForHost(host);
              } else {
                Get.to(() => ProfileScreen(user: host));
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLive ? const Color(0xFFFF2200) : const Color(0xFFFF7A00),
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImage(
                      size: const Size(64, 64),
                      image: host.profilePhoto?.addBaseURL(),
                      fullName: host.fullname,
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Host Name
          GestureDetector(
            onTap: () => Get.to(() => ProfileScreen(user: host)),
            child: Text(
              host.fullname ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Follow Pill Button
          Obx(() {
            final isFollowing = host.isFollowing == true;
            final isLoading = controller.similarHostFollowLoading.contains(host.id);

            return GestureDetector(
              onTap: () => controller.toggleFollowSimilarHost(host),
              child: Container(
                width: double.infinity,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isFollowing ? const Color(0xFF333333) : const Color(0xFFFF4500),
                ),
                child: isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white, radius: 8)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isFollowing) ...[
                            const Icon(Icons.add, color: Colors.white, size: 14),
                            const SizedBox(width: 2),
                          ],
                          Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onFollowers,
              child: Column(
                children: [
                  Text(
                    (user?.followerCount ?? 0).toInt().numberFormat,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Followers',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 28, color: Colors.white12),
          Expanded(
            child: GestureDetector(
              onTap: onFollowing,
              child: Column(
                children: [
                  Text(
                    (user?.followingCount ?? 0).toInt().numberFormat,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Following',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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

class BecomeHostButton extends StatefulWidget {
  const BecomeHostButton({super.key});

  @override
  State<BecomeHostButton> createState() => _BecomeHostButtonState();
}

class _BecomeHostButtonState extends State<BecomeHostButton> {
  String _statusText = 'none'; // 'none', 'pending', 'accepted', 'rejected'

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final user = SessionManager.instance.getUser();
    if (user?.isHost == 1) {
      if (mounted) setState(() => _statusText = 'accepted');
      return;
    }

    final data = await GiftWalletService.instance.checkHostRequestStatus();
    if (mounted) {
      setState(() {
        if (data != null && data['status_text'] != null) {
          _statusText = data['status_text'].toString();
        } else {
          _statusText = 'none';
        }
      });
    }
  }

  void _onTap() {
    if (_statusText == 'accepted') {
      Get.snackbar(
        'Host Account',
        'You are an approved Host on GioEdu!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return;
    }

    if (_statusText == 'pending') {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1E28),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFB300).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFB300), size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Interview Under Review',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your 2-minute interview video has been submitted and is currently being reviewed by our admin team. You will be notified once reviewed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if (_statusText == 'rejected') {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1E28),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFF1744).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.cancel_rounded, color: Color(0xFFFF1744), size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Application Rejected',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your previous host application was not approved. You can record a new ~2-minute interview video to apply again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Get.back();
                      _openRecordingScreen();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Record New Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    _openRecordingScreen();
  }

  void _openRecordingScreen() async {
    final result = await Get.to(() => HostInterviewRecordingScreen(
      onSubmitted: () {
        _fetchStatus();
      },
    ));
    if (result == true) {
      _fetchStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
    final bool isHost = user?.isHost == 1 || _statusText == 'accepted';

    String label = 'Become Host';
    IconData icon = Icons.videocam_rounded;
    Color? bgColor;
    Gradient? gradient = const LinearGradient(colors: [ColorRes.primaryColor, ColorRes.orangeDark]);
    Border? border;

    if (isHost) {
      label = 'Host';
      icon = Icons.videocam_rounded;
      bgColor = Colors.grey.shade800;
      gradient = null;
    } else if (_statusText == 'pending') {
      label = 'Under Review';
      icon = Icons.hourglass_top_rounded;
      bgColor = const Color(0xFF2E2412);
      gradient = null;
      border = Border.all(color: const Color(0xFFFFB300), width: 1.2);
    } else if (_statusText == 'rejected') {
      label = 'Apply Again';
      icon = Icons.replay_rounded;
      bgColor = const Color(0xFF2C1318);
      gradient = null;
      border = Border.all(color: const Color(0xFFFF1744), width: 1.2);
    }

    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isHost
                  ? Colors.white54
                  : (_statusText == 'rejected'
                      ? const Color(0xFFFF5252)
                      : (_statusText == 'pending' ? const Color(0xFFFFB300) : Colors.white)),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isHost ? Colors.white54 : Colors.white,
                fontSize: 14.5,
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
  const DiamondBalanceBadge({super.key});

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
      onTap: () => Get.to(() => const DiamondPurchaseScreen()),
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
