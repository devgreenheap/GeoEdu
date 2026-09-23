import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/coupon_model.dart';
import 'package:geoedu/model/general/level_badge_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/coupon_screen/coupon_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:get/get.dart';

class LevelScreenNew extends StatefulWidget {
  const LevelScreenNew({super.key});

  @override
  State<LevelScreenNew> createState() => _LevelScreenNewState();
}

class _LevelScreenNewState extends State<LevelScreenNew> {
  User? user;

  int currentLevel = 1;
  int currentXP = 0;
  int nextLevelXP = 0;
  int nextLevel = 2;

  // Level progress from API
  int currentHostFollowers = 0;
  int currentLiveComments = 0;
  int currentSendGifts = 0;
  int nextLevelHostFollowersRequired = 0;
  int nextLevelLiveCommentsRequired = 0;
  int nextLevelSendGiftsRequired = 0;
  int nextLevelHostFollowersRemaining = 0;
  int nextLevelLiveCommentsRemaining = 0;
  int nextLevelSendGiftsRemaining = 0;
  int nextLevelXpRemaining = 0;

  bool isLevelLoading = true;

  List<LevelBadge> badges = [];
  bool isBadgesLoading = true;

  List<Coupon> coupons = [];
  bool isCouponsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserAndInit();
    _fetchBadges();
    _fetchCoupons();
  }

  Future<void> _fetchUserAndInit() async {
    try {
      final freshUser = await UserService.instance.fetchUserDetails(
        userId: SessionManager.instance.getUserID(),
      );
      if (freshUser != null && mounted) {
        setState(() {
          user = freshUser;
          _initLevel();
          isLevelLoading = false;
        });
      } else {
        // Fallback to cached user
        if (mounted) {
          setState(() {
            user = SessionManager.instance.getUser();
            _initLevel();
            isLevelLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          user = SessionManager.instance.getUser();
          _initLevel();
          isLevelLoading = false;
        });
      }
    }
  }

  void _initLevel() {
    currentLevel = user?.level ?? 1;
    nextLevel = user?.nextUserLevel ?? (currentLevel + 1);
    currentXP = user?.currentXp ?? 0;
    nextLevelXP = user?.nextLevelXpRequired ?? 0;
    nextLevelXpRemaining = user?.nextLevelXpRemaining ?? 0;

    // Level progress stats from API
    currentHostFollowers = user?.currentHostFollowers ?? 0;
    currentLiveComments = user?.currentLiveComments ?? 0;
    currentSendGifts = user?.currentSendGifts ?? 0;
    nextLevelHostFollowersRequired = user?.nextLevelHostFollowersRequired ?? 0;
    nextLevelLiveCommentsRequired = user?.nextLevelLiveCommentsRequired ?? 0;
    nextLevelSendGiftsRequired = user?.nextLevelSendGiftsRequired ?? 0;
    nextLevelHostFollowersRemaining = user?.nextLevelHostFollowersRemaining ?? 0;
    nextLevelLiveCommentsRemaining = user?.nextLevelLiveCommentsRemaining ?? 0;
    nextLevelSendGiftsRemaining = user?.nextLevelSendGiftsRemaining ?? 0;
  }

  Future<void> _fetchBadges() async {
    try {
      final result = await CommonService.instance.fetchLevelBadges();
      if (result.status == true && result.data != null) {
        setState(() {
          badges = result.data!;
          isBadgesLoading = false;
        });
      } else {
        setState(() => isBadgesLoading = false);
      }
    } catch (_) {
      setState(() => isBadgesLoading = false);
    }
  }

  Future<void> _fetchCoupons() async {
    try {
      final result = await CommonService.instance.fetchCoupons();
      if (result.status == true && result.data != null) {
        setState(() {
          coupons = result.data!.where((c) => c.isActive == 1).toList();
          isCouponsLoading = false;
        });
      } else {
        setState(() => isCouponsLoading = false);
      }
    } catch (_) {
      setState(() => isCouponsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      appBar: AppBar(
        backgroundColor: ColorRes.blackPure,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: const Text(
          "My Levels",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLevelLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            /// ── LEVELS Banner ──
            _levelsBanner(),

            const SizedBox(height: 14),

            /// ── Current Level Card ──
            _currentLevelCard(),

            const SizedBox(height: 22),

            /// ── How to Level Up ──
            _sectionTitle("\u2753", "How to Level Up"),
            const SizedBox(height: 6),
            _levelUpTile(
              icon: Icons.chat_bubble_outline_rounded,
              bgColor: ColorRes.surfaceBackground,
              title: "Comment on live",
              progress: "$currentLiveComments/$nextLevelLiveCommentsRequired",
              remaining: nextLevelLiveCommentsRemaining,
              action: nextLevelLiveCommentsRemaining <= 0 ? _doneChip() : _progressChip(currentLiveComments, nextLevelLiveCommentsRequired),
            ),
            _thinDivider(),
            _levelUpTile(
              icon: Icons.person_add_alt_1_outlined,
              bgColor: ColorRes.surfaceBackground,
              title: "Host Followers",
              progress: "$currentHostFollowers/$nextLevelHostFollowersRequired",
              remaining: nextLevelHostFollowersRemaining,
              action: nextLevelHostFollowersRemaining <= 0 ? _doneChip() : _progressChip(currentHostFollowers, nextLevelHostFollowersRequired),
            ),
            _thinDivider(),
            _levelUpTile(
              icon: Icons.card_giftcard_rounded,
              bgColor: ColorRes.surfaceBackground,
              title: "Send Gifts",
              progress: "$currentSendGifts/$nextLevelSendGiftsRequired",
              remaining: nextLevelSendGiftsRemaining,
              action: nextLevelSendGiftsRemaining <= 0 ? _doneChip() : _giftNowChip(),
            ),
            _thinDivider(),
            _levelUpTile(
              icon: Icons.star_rounded,
              bgColor: ColorRes.green,
              title: "Total XP",
              progress: "$currentXP/$nextLevelXP",
              remaining: nextLevelXpRemaining,
              action: nextLevelXpRemaining <= 0 ? _doneChip() : _progressChip(currentXP, nextLevelXP),
            ),

            const SizedBox(height: 26),

            /// ── My Current Rewards ──
            _sectionTitleWithMore("\u{1F3C6}", "My Current Rewards"),
            const SizedBox(height: 10),
            _rewardsRow(),

            const SizedBox(height: 26),

            /// ── Rewards unlocked at Level N ──
            _sectionTitleWithMore("\u{1F513}", "Rewards unlocked at Level $nextLevel"),

            const SizedBox(height: 26),

            /// ── Badges as per level ──
            _sectionTitle("\u{1F396}\u{FE0F}", "Badges as per level"),
            const SizedBox(height: 10),
            _badgesList(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LEVELS BANNER
  // ═══════════════════════════════════════════════════════════════
  Widget _levelsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.only(top: 14, bottom: 18, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          /// "LEVELS" gold header
          const Text(
            "LEVELS",
            style: TextStyle(
              color: ColorRes.gold,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
          const SizedBox(height: 14),

          /// Three icon columns
          Row(
            children: [
              _bannerColumn("assets/images/badge.png", "Premium\nLevel Badge"),
              _bannerColumn("assets/images/gifts.png", "Rewards on\nevery Level"),
              _bannerColumn("assets/images/star.png", "Be more\nPopular"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerColumn(String asset, String label) {
    return Expanded(
      child: Column(
        children: [
          Image.asset(asset, width: 55, height: 55),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CURRENT LEVEL CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _currentLevelCard() {
    final double progress = nextLevelXP > 0
        ? (currentXP / nextLevelXP).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          /// Badge + 3D cube on the right
          Positioned(
            right: 70,
            top: -2,
            child: Image.asset("assets/images/badge.png", width: 48, height: 48),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Image.asset(
              AssetRes.levelDioIcon,
              width: 75,
              height: 75,
              opacity: const AlwaysStoppedAnimation(0.8),
            ),
          ),

          /// Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar + Level text
              Row(
                children: [
                  /// Profile photo with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 2),
                    ),
                    child: CustomImage(
                      size: const Size(52, 52),
                      image: (user?.profilePhoto ?? '').addBaseURL(),
                      fullName: user?.fullname,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Level",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Lv.$currentLevel",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// Progress bar
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: ColorRes.gold,
                      boxShadow: [
                        BoxShadow(color: ColorRes.gold.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// XP / Next level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "XP: $currentXP/$nextLevelXP",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Next: ",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: "Lv.$nextLevel",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HOW TO LEVEL UP
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionTitle(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelUpTile({
    required IconData icon,
    required Color bgColor,
    required String title,
    required String progress,
    required int remaining,
    required Widget action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          /// Circle icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),

          /// Title + Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  progress,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    "$remaining remaining",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          /// Action button
          action,
        ],
      ),
    );
  }

  Widget _doneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Done",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(width: 4),
          Icon(Icons.check, color: Colors.white.withValues(alpha: 0.45), size: 16),
        ],
      ),
    );
  }

  Widget _progressChip(int current, int required) {
    final double ratio = required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;
    final int percent = (ratio * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$percent%",
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _giftNowChip() {
    return GestureDetector(
      onTap: () {
        // TODO: Open gift sheet
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: ColorRes.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "Gift Now",
          style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _thinDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION TITLE WITH "More >"
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionTitleWithMore(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const CouponScreen()),
            child: const Row(
              children: [
                Text("More", style: TextStyle(color: Colors.white60, fontSize: 13)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, color: Colors.white60, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  REWARDS HORIZONTAL LIST
  // ═══════════════════════════════════════════════════════════════
  Widget _rewardsRow() {
    if (isCouponsLoading) {
      return const SizedBox(
        height: 95,
        child: Center(child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2)),
      );
    }
    if (coupons.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text('No coupons available', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
    }
    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: coupons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _rewardCard(coupons[index]),
      ),
    );
  }

  Widget _rewardCard(Coupon coupon) {
    return GestureDetector(
      onTap: () => Get.to(() => const CouponScreen()),
      child: Container(
        width: 115,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorRes.surfaceBackground),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/discount.png", width: 20, height: 20, color: ColorRes.gold),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    "${coupon.displayValue} Off",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              coupon.code ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: ColorRes.textDarkGrey, fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BADGES LIST
  // ═══════════════════════════════════════════════════════════════
  Widget _badgesList() {
    if (isBadgesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2)),
      );
    }
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: badges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _badgeCard(badges[index]),
    );
  }

  Widget _badgeCard(LevelBadge badge) {
    final bool isCurrentTier =
        currentLevel >= (badge.startLevel ?? 0) && currentLevel <= (badge.endLevel ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorRes.cardBackground,
        border: Border.all(
          color: isCurrentTier ? ColorRes.gold : ColorRes.surfaceBackground,
          width: isCurrentTier ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          /// Badge image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: badge.image ?? '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 50,
                height: 50,
                color: ColorRes.surfaceBackground,
                child: const Icon(Icons.shield, color: ColorRes.textDarkGrey, size: 24),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: ColorRes.surfaceBackground,
                child: const Icon(Icons.shield, color: ColorRes.textDarkGrey, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          /// Title + level range
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title ?? '',
                  style: TextStyle(
                    color: isCurrentTier ? ColorRes.gold : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Level ${badge.startLevel ?? 0} - ${badge.endLevel ?? 0}",
                  style: const TextStyle(
                    color: ColorRes.textDarkGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          /// Current indicator
          if (isCurrentTier)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorRes.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "You",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
