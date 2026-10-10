import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_comment.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/last_round_indicator_widget.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class BattleView extends StatefulWidget {
  final bool isAudience;
  final LivestreamScreenController controller;
  final EdgeInsets? margin;

  const BattleView({
    super.key,
    this.isAudience = false,
    required this.controller,
    this.margin,
  });

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  @override
  void initState() {
    super.initState();
    widget.controller.battleRunning();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveBattleOverlayWidget(
            isAudience: widget.isAudience,
            controller: widget.controller,
            margin: widget.margin,
          ),
        ],
      ),
    );
  }
}

class LiveBattleOverlayWidget extends StatefulWidget {
  final bool isAudience;
  final LivestreamScreenController controller;
  final EdgeInsets? margin;

  const LiveBattleOverlayWidget({
    super.key,
    this.isAudience = false,
    required this.controller,
    this.margin,
  });

  @override
  State<LiveBattleOverlayWidget> createState() =>
      _LiveBattleOverlayWidgetState();
}

class _LiveBattleOverlayWidgetState extends State<LiveBattleOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Livestream stream = widget.controller.liveData.value;
      final List<LivestreamUserState> userStates =
          widget.controller.liveUsersStates;
      final List<AppUser> liveUsers =
          widget.controller.firestoreController.users;
      final List<StreamView> streamViews = widget.controller.streamViews;

      // 1. Host
      final hostStreamId = '${stream.hostId}';
      final LivestreamUserState? hostState = userStates.firstWhereOrNull(
            (e) => '${e.userId}' == hostStreamId,
          ) ??
          (streamViews.isNotEmpty
              ? userStates.firstWhereOrNull(
                  (e) => '${e.userId}' == streamViews[0].streamId)
              : null);
      final AppUser? hostUser = hostState?.getUser(liveUsers) ?? stream.hostUser;

      // 2. Opponent (accepted PK call participant)
      final opponentUserId = stream.pkOpponentId;
      LivestreamUserState? coHostState;
      if (opponentUserId != null) {
        coHostState = userStates.firstWhereOrNull(
          (e) => e.userId == opponentUserId,
        );
      } else if (streamViews.length > 1) {
        coHostState = userStates.firstWhereOrNull(
          (e) => '${e.userId}' == streamViews[1].streamId,
        );
      }
      final AppUser? coHostUser =
          coHostState?.getUser(liveUsers) ?? widget.controller.pkOpponentUser.value;

      // Diamond scores for host & opponent
      final int hostDiamonds = hostState?.currentBattleCoin ?? 0;
      final int opponentDiamonds = coHostState?.currentBattleCoin ?? 0;

      // Stream Views for both participants
      final hostStreamView = streamViews
              .firstWhereOrNull((v) => v.streamId == hostStreamId) ??
          (streamViews.isNotEmpty ? streamViews[0] : null);
      final opponentStreamView = (opponentUserId != null
              ? streamViews
                  .firstWhereOrNull((v) => v.streamId == '$opponentUserId')
              : null) ??
          (streamViews.length > 1
              ? streamViews
                  .firstWhereOrNull((v) => v.streamId != hostStreamId)
              : null);

      // Check if audience has switched to viewing the opponent
      final bool isAudienceSwapped = widget.isAudience &&
          widget.controller.selectedBattleHostId.value != null &&
          widget.controller.selectedBattleHostId.value == opponentUserId;

      // Primary (Left) vs Secondary (Right)
      final leftUser = isAudienceSwapped ? coHostUser : hostUser;
      final rightUser = isAudienceSwapped ? hostUser : coHostUser;
      final leftStreamView =
          isAudienceSwapped ? opponentStreamView : hostStreamView;
      final rightStreamView =
          isAudienceSwapped ? hostStreamView : opponentStreamView;

      final int leftScore =
          isAudienceSwapped ? opponentDiamonds : hostDiamonds;
      final int rightScore =
          isAudienceSwapped ? hostDiamonds : opponentDiamonds;

      final List<StreamView> displayStreamViews = [
        if (leftStreamView != null) leftStreamView,
        if (rightStreamView != null) rightStreamView,
      ];

      return SafeArea(
        bottom: false,
        child: Container(
          width: Get.width,
          margin: widget.margin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top split video section
              SizedBox(
                height: Get.height / 2.7,
                width: Get.width,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Side-by-side video feeds
                    Positioned.fill(
                      child: Row(
                        children: List.generate(
                          displayStreamViews.length,
                          (index) {
                            final streamView = displayStreamViews[index];
                            final targetUserId = index == 0
                                ? (leftUser?.userId)
                                : (rightUser?.userId);

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.isAudience &&
                                      targetUserId != null) {
                                    widget.controller
                                        .switchBattleHost(targetUserId);
                                  } else {
                                    widget.controller
                                        .toggleBattleFocus(index);
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: LiveStreamUserView(
                                        isNameAndSpeakerVisible: false,
                                        controller: widget.controller,
                                        streamingView: streamView,
                                      ),
                                    ),
                                    // User Name pill at bottom of each video
                                    Positioned(
                                      bottom: 6,
                                      left: index == 0 ? 8 : null,
                                      right: index == 1 ? 8 : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (index == 0
                                                  ? leftUser?.fullname ??
                                                      leftUser?.username
                                                  : rightUser?.fullname ??
                                                      rightUser?.username) ??
                                              '',
                                          style: TextStyleCustom.outFitSemiBold600(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // "Last Round" floating indicator pinned near top center
                    if (stream.lastRoundResult != null)
                      Positioned(
                        top: 10,
                        child: LastRoundIndicatorWidget(
                          lastRoundResult: stream.lastRoundResult,
                        ),
                      ),

                    // 10s countdown animation
                    BuildLastTenSecondView(controller: widget.controller),
                  ],
                ),
              ),

              // Horizontal PK Progress Bar with crystal texture & centered 3D diamond
              BuildPkProgressBar(
                red: leftScore,
                blue: rightScore,
              ),

              // Compact Score Cards & Centered VS / Timer Capsule (matching screenshot 4)
              BuildPkScoreAndTimerSection(
                controller: widget.controller,
                leftScore: leftScore,
                rightScore: rightScore,
                leftUser: leftUser,
                rightUser: rightUser,
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Crystal gradient progress bar with sword circular badges and centered 3D diamond
class BuildPkProgressBar extends StatelessWidget {
  final int red;
  final int blue;

  const BuildPkProgressBar({super.key, required this.red, required this.blue});

  @override
  Widget build(BuildContext context) {
    final width = Get.width;
    final total = red + blue == 0 ? 1 : red + blue;
    final redWidth = (width * red) / total;
    final blueWidth = (width * blue) / total;

    return SizedBox(
      height: 24,
      width: width,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Gradient split bar
          Row(
            children: [
              AnimatedContainer(
                height: 12,
                width: redWidth,
                duration: const Duration(milliseconds: 250),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                  ),
                ),
              ),
              AnimatedContainer(
                height: 12,
                width: blueWidth,
                duration: const Duration(milliseconds: 250),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE040FB), Color(0xFFFF4081)],
                  ),
                ),
              ),
            ],
          ),

          // Left Cyan Sword Badge
          Positioned(
            left: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00E5FF),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Text('⚔️', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),

          // Right Pink Sword Badge
          Positioned(
            right: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4081), Color(0xFFE040FB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF4081),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🗡️', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),

          // Center 3D Purple Diamond
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F1D36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE040FB).withOpacity(0.55),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.diamond_rounded,
                color: Color(0xFFD500F9),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Score cards with Rank 3-2-1 and 1-2-3 frames, centered VS, and timer capsule
class BuildPkScoreAndTimerSection extends StatelessWidget {
  final LivestreamScreenController controller;
  final int leftScore;
  final int rightScore;
  final AppUser? leftUser;
  final AppUser? rightUser;

  const BuildPkScoreAndTimerSection({
    super.key,
    required this.controller,
    required this.leftScore,
    required this.rightScore,
    this.leftUser,
    this.rightUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Dark Score Card (Rank 3, 2, 1)
          Expanded(
            child: _buildSideCard(
              context,
              score: leftScore,
              isLeft: true,
              user: leftUser,
            ),
          ),

          // Center Section: VS Badge + Red/Dark Timer Capsule
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // VS Badge
                Image.asset(
                  AssetRes.icBattleVs,
                  width: 36,
                  height: 36,
                ),
                const SizedBox(height: 3),

                // Countdown Timer Capsule
                Obx(() {
                  final remaining = controller.remainingBattleSeconds.value;
                  final duration = Duration(seconds: remaining);
                  final minutes = duration.inMinutes;
                  final seconds = duration.inSeconds % 60;
                  final timeStr =
                      "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
                  final isLowTime = remaining <= 10 && remaining > 0;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLowTime
                          ? const Color(0xFFFF1744)
                          : const Color(0xFF221F3D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLowTime
                            ? const Color(0xFFFF5252)
                            : Colors.white.withOpacity(0.12),
                        width: 0.8,
                      ),
                      boxShadow: isLowTime
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF1744).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      timeStr,
                      style: TextStyleCustom.outFitBold700(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Right Dark Score Card (Rank 1, 2, 3)
          Expanded(
            child: _buildSideCard(
              context,
              score: rightScore,
              isLeft: false,
              user: rightUser,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideCard(
    BuildContext context, {
    required int score,
    required bool isLeft,
    required AppUser? user,
  }) {
    // Get top contributors for this user
    final topContributors = _getTopContributorsForUser(user?.userId);

    // Left order: Rank 3, Rank 2, Rank 1
    // Right order: Rank 1, Rank 2, Rank 3
    final rankAssets = isLeft
        ? [AssetRes.rank3, AssetRes.rank2, AssetRes.rank1]
        : [AssetRes.rank1, AssetRes.rank2, AssetRes.rank3];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row of 3 Ranking frames
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final rankAsset = rankAssets[index];
              final contributor = topContributors.length > index
                  ? topContributors[index]
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Supporter avatar if present
                      if (contributor != null)
                        ClipOval(
                          child: CustomImage(
                            size: const Size(18, 18),
                            radius: 9,
                            image: contributor.profile?.addBaseURL(),
                            fullName: contributor.fullname,
                          ),
                        ),
                      // Rank ring frame badge
                      Image.asset(
                        rankAsset,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),

          // Diamond icon + Score count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.diamond_rounded,
                color: Color(0xFFE040FB),
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: TextStyleCustom.outFitBold700(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AppUser> _getTopContributorsForUser(int? userId) {
    if (userId == null) return [];
    final Map<int, int> supporterCoins = {};
    for (final c in controller.comments) {
      if (c.commentType == LivestreamCommentType.gift &&
          c.receiverId == userId &&
          c.senderId != null) {
        supporterCoins[c.senderId!] = (supporterCoins[c.senderId!] ?? 0) +
            (c.gift?.coinPrice?.toInt() ?? 1);
      }
    }
    final sorted = supporterCoins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<AppUser> users = [];
    for (final entry in sorted.take(3)) {
      final u = controller.firestoreController.users
          .firstWhereOrNull((user) => user.userId == entry.key);
      if (u != null) users.add(u);
    }
    return users;
  }
}

class BuildLastTenSecondView extends StatefulWidget {
  final LivestreamScreenController controller;

  const BuildLastTenSecondView({super.key, required this.controller});

  @override
  State<BuildLastTenSecondView> createState() => _BuildLastTenSecondViewState();
}

class _BuildLastTenSecondViewState extends State<BuildLastTenSecondView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Livestream stream = widget.controller.liveData.value;
      final bool isBattleEnd = stream.battleType == BattleType.end;
      final int leftSecond = widget.controller.remainingBattleSeconds.value;

      if (leftSecond == 0 || isBattleEnd) {
        return const SizedBox();
      }
      if (leftSecond <= 10) {
        return Align(
          alignment: const Alignment(0, -0.2),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Container(
              height: 140,
              width: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: <Color>[
                    whitePure(context).withValues(alpha: 0),
                    whitePure(context).withValues(alpha: .5)
                  ],
                  transform:
                      GradientRotation(2 * pi * _animationController.value),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '$leftSecond',
                  style: TextStyleCustom.unboundedBlack900(
                    color: whitePure(context),
                    fontSize: 85,
                  ),
                  key: ValueKey<int>(leftSecond),
                ),
              ),
            ),
          ),
        );
      }
      return const SizedBox();
    });
  }
}