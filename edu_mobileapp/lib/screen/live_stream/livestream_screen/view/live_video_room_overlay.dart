import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/view/livestream_view.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requests_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/followers_gained_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_host_more_sheet.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/live_room/live_share_sheet.dart';
import 'package:geoedu/common/widget/live_summary_dialog.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_comment.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_like_button.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/other_lives_side_panel.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/video_room_gift_category_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_beauty_filter_sheet.dart';
import 'package:geoedu/screen/report_sheet/report_sheet.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/room_top_gifters_sheet.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/utilities/app_res.dart';

/// Unified Modern Overlay for Video Live Rooms (Host & Audience).
/// Replicates the proven rich aesthetics and functionality of the Audio Call room:
/// - Sleek Top Header (Back arrow with exit confirmation, Host avatar with gold stroke,
///   name + premium badge, star/diamond counter, Follow button, LIVE pill, viewers, settings,
///   close, top 3 medals, and "Lives >" button)
/// - Left Floating Gift Card (featured gift with 50% discount badge and 1-tap Send)
/// - Mid-right Floating Join Call button
/// - Pinned Comment Banner & Host Pin Comment Input
/// - Top Gifter Pill
/// - Compact Chat & System Events (with "Wave 👋" for host, gifts, share banner)
/// - Horizontal Quick Gift Bar with 1-tap direct sending
/// - Modern Bottom Bar with pill input, "New" badge, Mic toggle, Flip camera, Share, Gift, and Likes
/// - Slide-out "OtherLivesSidePanel" on "Lives >" tap or swipe left
class LiveVideoRoomOverlay extends StatefulWidget {
  final LivestreamScreenController controller;
  final bool isHost;
  final VoidCallback onBackOrClose;

  const LiveVideoRoomOverlay({
    super.key,
    required this.controller,
    required this.isHost,
    required this.onBackOrClose,
  });

  @override
  State<LiveVideoRoomOverlay> createState() => _LiveVideoRoomOverlayState();
}

class _LiveVideoRoomOverlayState extends State<LiveVideoRoomOverlay> {
  bool _showOtherLives = false;
  final ScrollController _chatScrollController = ScrollController();
  int _prevCommentCount = 0;
  Timer? _liveDurationTimer;
  int _elapsedSeconds = 0;
  final RxInt _hostTargetDiamonds = 500.obs;
  final Set<String> _wavedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _startLiveTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollChatToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _liveDurationTimer?.cancel();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _startLiveTimer() {
    final createdAt = widget.controller.liveData.value.createdAt ??
        DateTime.now().millisecondsSinceEpoch;
    final diffSec =
        ((DateTime.now().millisecondsSinceEpoch - createdAt) / 1000).floor();
    _elapsedSeconds = diffSec > 0 ? diffSec : 0;
    _liveDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String get _formattedDuration {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _scrollChatToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        final maxScroll = _chatScrollController.position.maxScrollExtent;
        if (animated) {
          _chatScrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _chatScrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _handleBackOrClose() {
    showEndLiveConfirmation(
      context: context,
      title: widget.isHost ? 'End Live' : 'Leave Live',
      message: widget.isHost
          ? 'Are you sure you want to end this live?'
          : 'Are you sure you want to leave this live?',
      confirmText: widget.isHost ? 'End Live' : 'Leave',
      cancelText: 'Cancel',
      onConfirm: widget.onBackOrClose,
    );
  }

  void _shareLive() {
    final hostUser = widget.controller.effectiveHostUser ??
        widget.controller.liveData.value.hostUser;
    LiveShareSheet.show(
      context: context,
      hostName: hostUser?.fullname ?? 'Host',
      hostPhotoUrl: hostUser?.profile?.addBaseURL(),
      currentUserName: widget.controller.myUser.value?.fullname ?? 'User',
      currentUserPhotoUrl:
          widget.controller.myUser.value?.profilePhoto?.addBaseURL(),
      shareLink: AppRes.playStoreLink,
      isAudio: false,
      isHost: widget.isHost,
    );
  }

  void _showMoreSheet() {
    final controller = widget.controller;
    if (!widget.isHost) {
      // Audience settings sheet
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1E28),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_rounded,
                      color: Color(0xFFFF9500), size: 24),
                  title: const Text('Members',
                      style: TextStyle(color: Colors.white, fontSize: 14.5)),
                  subtitle: const Text('View host, co-hosts and audience in this live',
                      style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                  onTap: () {
                    Get.back();
                    Get.bottomSheet(
                      const MembersSheet(isHost: false),
                      isScrollControlled: true,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.white),
                  title: const Text('Report Live Stream',
                      style: TextStyle(color: Colors.white, fontSize: 14.5)),
                  onTap: () {
                    Get.back();
                    final hostId = controller.liveData.value.hostId;
                    Get.bottomSheet(
                      ReportSheet(id: hostId, reportType: ReportType.user),
                      isScrollControlled: true,
                    );
                  },
                ),
                if ((controller.liveData.value.coHostIds ?? []).contains(controller.myUserId))
                  ListTile(
                    leading: const Icon(Icons.call_end_rounded, color: Color(0xFFFF7A19)),
                    title: const Text('Leave Call',
                        style: TextStyle(color: Color(0xFFFF7A19), fontSize: 14.5, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Disconnect from video call and remain in room',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    onTap: () {
                      Get.back();
                      controller.leaveCoHostCall();
                    },
                  ),
                ListTile(
                  leading:
                      const Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF5252)),
                  title: const Text('Leave Live Room',
                      style: TextStyle(color: Color(0xFFFF5252), fontSize: 14.5)),
                  onTap: () {
                    Get.back();
                    _handleBackOrClose();
                  },
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    LiveHostMoreSheet.show(
      context: context,
      controller: controller,
      onShare: _shareLive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (widget.isHost) {
      return Stack(
        children: [
          _buildHostLiveLayout(controller),
          if (_showOtherLives) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showOtherLives = false;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
            OtherLivesSidePanel(
              currentAudioHostId: controller.liveData.value.hostId,
              onClose: () {
                setState(() {
                  _showOtherLives = false;
                });
              },
            ),
          ],
        ],
      );
    }

    return Stack(
      children: [
        // Main Overlay with gestures
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -250 && !_showOtherLives) {
              setState(() {
                _showOtherLives = true;
              });
            }
          },
          child: SafeArea(
            child: KeyboardAvoider(
              child: Column(
                children: [
                  // 1. Sleek Top Header
                  _buildHeader(controller),

                  // 2. Left Floating Gift Card (Audience)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFloatingGiftCard(controller),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 3. Middle-Lower: Pin comment + Top gifter + Chat + Floating Join Call
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPinnedCommentBanner(controller),
                        Obx(() => (widget.isHost && controller.isPinInputOpen.value)
                            ? _buildPinCommentInput(controller)
                            : const SizedBox.shrink()),
                        _buildTopGifterPill(controller),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 125,
                          child: _buildChatList(controller),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 4. PK Battle Start Action (Host when co-host connected)
                  _buildStartBattlePrompt(controller),

                  // 5. Quick Gift 1-tap Bar (Audience)
                  _buildQuickGiftBar(controller),

                  // 6. Modern Bottom Bar
                  _buildBottomBar(controller),
                ],
              ),
            ),
          ),
        ),

        // Slide-out OtherLivesSidePanel on "Lives >" tap or swipe left
        if (_showOtherLives) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _showOtherLives = false;
                });
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          OtherLivesSidePanel(
            currentAudioHostId: controller.liveData.value.hostId,
            onClose: () {
              setState(() {
                _showOtherLives = false;
              });
            },
          ),
        ],
      ],
    );
  }

  // =============================================================
  // REDESIGNED HOST LIVE SCREEN (Matching Reference Image)
  // =============================================================

  Widget _buildHostLiveLayout(LivestreamScreenController controller) {
    return SafeArea(
      child: Column(
        children: [
          // 1. Top Header: Avatar + Name + ● LIVE + 👁 Count ... 📶 Wifi + ✕ Close
          _buildHostTopHeader(controller),

          // 2. Sub-Header: [🎁 | ⭐] & [💎 Target: ✏️] ... [Timer] [👤+ count]
          _buildHostSubHeader(controller),

          const SizedBox(height: 10),

          // 3. Mid-Upper: Left Active Gift Card & Right Dashed Accept Call Card
          _buildHostCardsRow(controller),

          const Spacer(),

          // 4. Middle-Lower: Pinned Song Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHostMusicBar(controller),
            ),
          ),

          const SizedBox(height: 8),

          // 5. Chat & Right-Side Controls: Join notifications + [Calls, Themes, More]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 190,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _buildHostJoinNotificationsAndChat(controller),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                _buildHostRightVerticalControls(controller),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 6. Bottom Bar: Requests (0) & PK Battle
          _buildHostBottomBar(controller),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHostTopHeader(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Obx(() {
        final stream = controller.liveData.value;
        final hostUser = controller.effectiveHostUser ?? stream.hostUser;
        final hostName = hostUser?.fullname ?? hostUser?.username ?? 'Host';
        final hostPhoto = hostUser?.profile?.addBaseURL();
        final watchingCount = stream.watchingCount ?? 0;

        return Row(
          children: [
            CustomImage(
              size: const Size(36, 36),
              image: hostPhoto,
              radius: 18,
              strokeWidth: 2,
              strokeColor: const Color(0xFFFFB300),
              fullName: hostName,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hostName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '● LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.remove_red_eye_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 3),
                Text(
                  '$watchingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.wifi_rounded,
              color: Color(0xFF00E676),
              size: 18,
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: _handleBackOrClose,
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHostSubHeader(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Obx(() {
        final coins = (controller.hostUserState?.totalCoin ?? 0).toInt();
        final giftCount = controller.hostGiftCount;
        final followersCount =
            controller.hostUserState?.followersGained.length ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          color: Color(0xFFFF5252), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '$giftCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 1, height: 10, color: Colors.white30),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => _showHostTargetDialog(controller),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded,
                            color: Color(0xFFBA68C8), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          _hostTargetDiamonds.value > 0
                              ? 'Target: ${_hostTargetDiamonds.value}'
                              : 'Target: ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.edit_rounded,
                            color: Colors.white70, size: 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => FollowersGainedSheet.show(context, controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '$followersCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHostCardsRow(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHostActiveGiftCard(controller),
          _buildHostAcceptCallCard(controller),
        ],
      ),
    );
  }

  Widget _buildHostActiveGiftCard(LivestreamScreenController controller) {
    return Obx(() {
      final topGift = controller.featuredGift ??
          (controller.availableGifts.isNotEmpty
              ? controller.availableGifts.first
              : null);
      final diamondPrice = topGift?.coinPrice ?? 148;
      final giftImage = topGift?.image?.addBaseURL();

      return GestureDetector(
        onTap: () => VideoRoomGiftCategorySheet.show(
          context: context,
          controller: controller,
        ),
        child: Container(
          width: 74,
          height: 98,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: giftImage != null
                        ? CustomImage(
                            size: const Size(40, 40),
                            image: giftImage,
                            fit: BoxFit.contain,
                          )
                        : const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFFF4081),
                            size: 34,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: Color(0xFFBA68C8), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '$diamondPrice',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHostAcceptCallCard(LivestreamScreenController controller) {
    return GestureDetector(
      onTap: () {
        CallRequestsSheet.show(context);
      },
      child: Container(
        width: 88,
        height: 98,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: Colors.white.withValues(alpha: 0.75),
            strokeWidth: 1.5,
            radius: 14,
            dash: 5,
            gap: 4,
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(height: 4),
                Text(
                  'Accept Call',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHostMusicBar(LivestreamScreenController controller) {
    return Obx(() {
      final stream = controller.liveData.value;
      final hostUser = controller.effectiveHostUser ?? stream.hostUser;
      final hostName = hostUser?.fullname ?? hostUser?.username ?? 'Host';
      final hostPhoto = hostUser?.profile?.addBaseURL();

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_rounded,
              color: Color(0xFF00E676), size: 15),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showMusicOrTopicSheet(controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomImage(
                    size: const Size(18, 18),
                    image: hostPhoto,
                    radius: 9,
                    fullName: hostName,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Text(
                      '$hostName : Songs 🎶',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHostJoinNotificationsAndChat(
      LivestreamScreenController controller) {
    return Obx(() {
      final joinedComments = controller.comments
          .where((c) => c.commentType == LivestreamCommentType.joined)
          .toList();

      final joinItems = joinedComments.isNotEmpty
          ? joinedComments.map((c) {
              final user = c.senderUser;
              return {
                'id': c.senderId ?? '',
                'name': user?.fullname ?? user?.username ?? 'User',
                'photo': user?.profile?.addBaseURL(),
              };
            }).toList()
          : controller.audienceList.take(4).map((u) {
              final user = u.user;
              return {
                'id': '${user?.userId ?? u.userId}',
                'name': user?.fullname ?? user?.username ?? 'Viewer',
                'photo': user?.profile?.addBaseURL(),
              };
            }).toList();

      final otherComments = controller.comments
          .where((c) => c.commentType != LivestreamCommentType.joined)
          .toList();

      return ListView(
        controller: _chatScrollController,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          ...joinItems.map((item) {
            final id = item['id'] as String;
            final name = item['name'] as String;
            final photo = item['photo'] as String?;
            final isWaved = _wavedUserIds.contains(id);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: CustomImage(
                      size: const Size(32, 32),
                      image: photo,
                      fullName: name,
                      radius: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF29B6F6),
                              size: 13,
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'has joined the Chatroom',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      HapticManager.shared.light();
                      setState(() {
                        _wavedUserIds.add(id);
                      });
                      controller.sendWaveTo(name);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isWaved
                            ? const Color(0xFF00E676).withValues(alpha: 0.25)
                            : const Color(0xFF2C3243).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWaved
                              ? const Color(0xFF00E676)
                              : Colors.white24,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isWaved ? 'Waved 👋' : 'Wave 👋',
                        style: TextStyle(
                          color:
                              isWaved ? const Color(0xFF00E676) : Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          ...otherComments.reversed.map((comment) {
            final senderUser = comment.senderUser;
            final senderName =
                senderUser?.fullname ?? senderUser?.username ?? 'User';
            final senderPhoto = senderUser?.profile?.addBaseURL();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImage(
                    size: const Size(20, 20),
                    image: senderPhoto,
                    fullName: senderName,
                    radius: 10,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCommentContent(
                        controller, comment, senderName),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildHostRightVerticalControls(
      LivestreamScreenController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            CallRequestsSheet.show(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: const Icon(Icons.weekend_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 3),
              const Text(
                'Calls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticManager.shared.light();
            LiveBeautyFilterSheet.show(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 3),
              const Text(
                'Themes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticManager.shared.light();
            _showMoreSheet();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: const Icon(Icons.more_vert_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 3),
              const Text(
                'More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHostBottomBar(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Obx(() {
        final requestCount = controller.requestList.length;

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  CallRequestsSheet.show(context);
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6E00), Color(0xFFFF3D00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.weekend_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Requests ($requestCount)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticManager.shared.light();
                  _handlePKBattleTap(controller);
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1E28),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFAB47BC), Color(0xFFEC407A)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Battle',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _handlePKBattleTap(LivestreamScreenController controller) {
    final stream = controller.liveData.value;
    final hasCoHost = (stream.coHostIds ?? []).isNotEmpty;
    if (hasCoHost) {
      controller.startBattle();
    } else {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1E28),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Text('PK Battle',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'To start a PK Battle, invite a co-host or accept a call first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6E00),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () {
                  Get.back();
                  Get.bottomSheet(const MembersSheet(isHost: true),
                      isScrollControlled: true);
                },
                icon: const Icon(Icons.people_alt_rounded, color: Colors.white),
                label: const Text('Invite / Accept Co-host',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }
  }

  void _showHostTargetDialog(LivestreamScreenController controller) {
    final textController = TextEditingController(
      text:
          _hostTargetDiamonds.value > 0 ? '${_hostTargetDiamonds.value}' : '',
    );
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1B1E28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.diamond_rounded,
                      color: Color(0xFFBA68C8), size: 22),
                  SizedBox(width: 8),
                  Text('Set Live Target',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Set your diamond goal for this live session.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [100, 500, 1000, 5000].map((preset) {
                  return GestureDetector(
                    onTap: () {
                      textController.text = '$preset';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('💎 $preset',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter diamond target',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6E00),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final val =
                          int.tryParse(textController.text.trim()) ?? 0;
                      _hostTargetDiamonds.value = val;
                      Get.back();
                    },
                    child: const Text('Save',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMusicOrTopicSheet(LivestreamScreenController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF1B1E28),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Live Music & Songs 🎶',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.music_note_rounded,
                  color: Color(0xFFFFB300), size: 24),
              title: const Text('Current Playlist / Topic',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(
                controller.liveData.value.topicName ??
                    controller.liveData.value.description ??
                    'Songs 🎶',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded,
                  color: Color(0xFF00E676), size: 24),
              title: const Text('Change Background Music',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // -------------------------------------------------------------
  // Header Component (Audience View)
  // -------------------------------------------------------------
  Widget _buildHeader(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Obx(() {
        final stream = controller.liveData.value;
        final hostUser = controller.effectiveHostUser ?? stream.hostUser;
        final hostName = hostUser?.fullname ?? hostUser?.username ?? 'Host';
        final hostPhoto = hostUser?.profile?.addBaseURL();
        final hostId = stream.hostId;
        final watchingCount = stream.watchingCount ?? 0;
        final coins = (controller.hostUserState?.totalCoin ?? 0).toInt();

        return Column(
          children: [
            // Row 1: Host avatar + Name + ● LIVE + 👁 Viewers + ⚙️ Settings + ✕ Close
            Row(
              children: [
                CustomImage(
                  size: const Size(36, 36),
                  image: hostPhoto,
                  radius: 18,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFFFFB300),
                  fullName: hostName,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // LIVE badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '● LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Viewers count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            watchingCount >= 0 ? '$watchingCount' : '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.isHost) ...[
                  const SizedBox(width: 4),
                  // Host quick mic
                  GestureDetector(
                    onTap: () => controller.toggleMic(null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: !controller.isAudioOn.value
                            ? const Color(0xFFFF1744).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isAudioOn.value
                            ? Icons.mic_rounded
                            : Icons.mic_off_rounded,
                        color: !controller.isAudioOn.value
                            ? const Color(0xFFFF1744)
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Host video camera toggle (turn camera on/off)
                  GestureDetector(
                    onTap: () => controller.toggleVideo(null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: !controller.isVideoOn.value
                            ? const Color(0xFFFF1744).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isVideoOn.value
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        color: !controller.isVideoOn.value
                            ? const Color(0xFFFF1744)
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                // Gear / Settings icon
                GestureDetector(
                  onTap: _showMoreSheet,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 4),
                // Close button
                GestureDetector(
                  onTap: _handleBackOrClose,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 2: (Host level + 🎁 pill + Follow) on left, (Medal + "Lives >") on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => RoomTopGiftersSheet.show(
                        context: context,
                        roomId: controller.liveData.value.roomID,
                        hostId: controller.liveData.value.hostId,
                        isAudio: false,
                        videoController: controller,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Colors.black, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              coins > 0 ? '$coins' : '1',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => RoomTopGiftersSheet.show(
                        context: context,
                        roomId: controller.liveData.value.roomID,
                        hostId: controller.liveData.value.hostId,
                        isAudio: false,
                        videoController: controller,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎁', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 2),
                            Text(
                              '${controller.hostGiftCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text('|',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 10)),
                            ),
                            const Text('⭐', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 2),
                            Text(
                              (controller.hostUserState?.totalCoin ?? 0).numberFormat,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.isHost) ...[
                      const SizedBox(width: 6),
                      _VideoFollowButton(hostId: hostId),
                    ],
                  ],
                ),
                _buildTopContributorsHeader(controller),
              ],
            ),
          ],
        );
      }),
    );
  }

  // -------------------------------------------------------------
  // Top Contributors Medals & "Lives >"
  // -------------------------------------------------------------
  Widget _buildTopContributorsHeader(LivestreamScreenController controller) {
    return Obx(() {
      final members = controller.audienceMemberList.take(3).toList();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (members.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => RoomTopGiftersSheet.show(
                context: context,
                roomId: controller.liveData.value.roomID,
                hostId: controller.liveData.value.hostId,
                isAudio: false,
                videoController: controller,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(members.length.clamp(0, 1), (index) {
                final m = members[index];
                final user = m.getUser(controller.firestoreController.users);
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFD700), width: 1.5),
                        ),
                        child: CustomImage(
                          size: const Size(22, 22),
                          image: user?.profile?.addBaseURL(),
                          radius: 11,
                          fullName: user?.fullname ?? 'Viewer',
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showOtherLives = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Lives >',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // -------------------------------------------------------------
  // Left Floating Gift Card
  // -------------------------------------------------------------
  Widget _buildFloatingGiftCard(LivestreamScreenController controller) {
    return Obx(() {
      final gift = controller.featuredGift ??
          (controller.availableGifts.isNotEmpty
              ? controller.availableGifts.first
              : null);
      final bool isLocked = !widget.isHost &&
          (controller.isGiftAnimating.value ||
              controller.activeGifts.isNotEmpty);
      return GestureDetector(
        onTap: () {
          if (widget.isHost) {
            controller.showFavouriteGiftSheet(context);
          } else if (gift != null) {
            if (isLocked) return;
            controller.sendGiftDirect(gift);
          } else {
            VideoRoomGiftCategorySheet.show(
              context: context,
              controller: controller,
            );
          }
        },
        child: Container(
          width: 66,
          height: 98,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '0/3',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              CustomImage(
                size: const Size(38, 38),
                image: gift?.image?.addBaseURL(),
                radius: 6,
                fit: BoxFit.contain,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Send',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }





  // -------------------------------------------------------------
  // PK Battle Start Action (Host when co-host is connected)
  // -------------------------------------------------------------
  Widget _buildStartBattlePrompt(LivestreamScreenController controller) {
    if (!widget.isHost) return const SizedBox.shrink();
    return Obx(() {
      final stream = controller.liveData.value;
      final hasCoHost = controller.streamViews.length >= 2 ||
          (stream.coHostIds != null && stream.coHostIds!.isNotEmpty);
      final isBattleRunning = stream.battleType == BattleType.running ||
          stream.battleType == BattleType.waiting;
      final canStartBattle = hasCoHost &&
          !isBattleRunning &&
          (controller.setting?.liveBattle ?? 1) == 1;

      if (!canStartBattle) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: GestureDetector(
            onTap: () {
              HapticManager.shared.medium();
              controller.startBattle();
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1744), Color(0xFFFF8A00)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    LKey.startBattle.tr.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // Pinned Comment Banner & Host Pin Comment Input
  // -------------------------------------------------------------
  Widget _buildPinnedCommentBanner(LivestreamScreenController controller) {
    return Obx(() {
      final pinned = controller.pinnedComment.value;
      if (pinned.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.35),
              width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: Color(0xFFFFB300), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pinned,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (widget.isHost)
              GestureDetector(
                onTap: controller.clearPinnedComment,
                child:
                    const Icon(Icons.close, color: Colors.white54, size: 16),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPinCommentInput(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                  width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.pinCommentController,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onSubmitted: (_) => controller.submitPinnedComment(),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Type your pin comment here…',
                      hintStyle:
                          TextStyle(color: Colors.white38, fontSize: 12.5),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: controller.submitPinnedComment,
                  child: const Icon(Icons.push_pin_outlined,
                      color: Color(0xFFFFB300), size: 18),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => controller.isPinInputOpen.value = false,
                  child: const Icon(Icons.close,
                      color: Colors.white54, size: 16),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 3, left: 4),
            child: Text(
              'Comments will be pinned to top',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Top Gifter Pill
  // -------------------------------------------------------------
  Widget _buildTopGifterPill(LivestreamScreenController controller) {
    return Obx(() {
      final topUser = controller.topGifterName.value.trim();
      if (topUser.isEmpty) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => RoomTopGiftersSheet.show(
          context: context,
          roomId: controller.liveData.value.roomID,
          hostId: controller.liveData.value.hostId,
          isAudio: false,
          videoController: controller,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB300),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.black, size: 11),
              ),
              const SizedBox(width: 4),
              Text(
                '$topUser - Top Gifter',
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // Chat & Real-Time Events List
  // -------------------------------------------------------------
  Widget _buildChatList(LivestreamScreenController controller) {
    return Obx(() {
      final comments = controller.comments;
      final stream = controller.liveData.value;
      final hostUser = controller.effectiveHostUser ?? stream.hostUser;
      final hostName = hostUser?.fullname ?? hostUser?.username ?? 'Host';
      final hostPhoto = hostUser?.profile?.addBaseURL();
      final title = stream.description ?? stream.topicName ?? 'प्यार के तराने 🎵';

      // Auto-scroll to latest message at the bottom whenever new comments arrive
      if (comments.length != _prevCommentCount) {
        _prevCommentCount = comments.length;
        _scrollChatToBottom();
      }

      return ListView(
        controller: _chatScrollController,
        padding: EdgeInsets.zero,
        reverse: false,
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Host Bio / Status Pinned bubble (matching screenshot)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomImage(
                    size: const Size(18, 18),
                    image: hostPhoto,
                    fullName: hostName,
                    radius: 9,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hostName,
                    style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.music_note_rounded,
                      color: Color(0xFFFFB300), size: 12),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      title.isNotEmpty ? title : 'प्यार के तराने 🎵',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Share banner
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.reply_rounded,
                        color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Share this LIVE room with your friends.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _shareLive,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Host Interaction Call banner (Audience and Host)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CustomImage(
                    size: const Size(20, 20),
                    image: hostPhoto,
                    fullName: hostName,
                    radius: 10,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: widget.isHost ? 'Live Room ' : '$hostName ',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: widget.isHost
                                ? 'Manage co-hosts & calls'
                                : 'said Hi to you! Request Call',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      HapticManager.shared.light();
                      if (widget.isHost) {
                        Get.bottomSheet(
                          const MembersSheet(isHost: true),
                          isScrollControlled: true,
                        );
                      } else {
                        controller.onVideoRequestSend(controller.liveData.value);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...comments.reversed.map((comment) {
            final senderUser = comment.senderUser;
            final senderName =
                senderUser?.fullname ?? senderUser?.username ?? 'User';
            final senderPhoto = senderUser?.profile?.addBaseURL();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImage(
                    size: const Size(22, 22),
                    image: senderPhoto,
                    fullName: senderName,
                    radius: 11,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCommentContent(
                        controller, comment, senderName),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildCommentContent(LivestreamScreenController controller,
      LivestreamComment comment, String senderName) {
    final myUserId = controller.myUserId;
    final isMe = comment.senderId == myUserId;
    final displayName = isMe ? 'You' : senderName;

    Widget nameRow(Widget trailing) => Row(
          children: [
            Flexible(
              child: Text(displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            trailing,
          ],
        );

    switch (comment.commentType) {
      case LivestreamCommentType.joined:
        return nameRow(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('joined the room',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            if (widget.isHost) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.sendWaveTo(senderName),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Wave 👋',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ],
        ));

      case LivestreamCommentType.joinedCoHost:
        return nameRow(const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('joined the call 📞',
                style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ));

      case LivestreamCommentType.leftCoHost:
        return nameRow(const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('left the call 📴',
                style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ));

      case LivestreamCommentType.gift:
        final gift = comment.gift;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow(const SizedBox.shrink()),
            Row(
              children: [
                if (gift?.image != null)
                  CustomImage(
                      size: const Size(22, 22),
                      image: gift!.image?.addBaseURL(),
                      radius: 4),
                const SizedBox(width: 4),
                Text(
                  'sent ${gift?.displayName ?? "a gift"} · ${gift?.coinPrice ?? 0} 💎',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        );

      case LivestreamCommentType.text:
      default:
        final text = comment.comment ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow(const SizedBox.shrink()),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 11.5)),
          ],
        );
    }
  }

  // -------------------------------------------------------------
  // Horizontal Quick Gift 1-Tap Bar
  // -------------------------------------------------------------
  Widget _buildQuickGiftBar(LivestreamScreenController controller) {
    return Obx(() {
      final gifts = controller.availableGifts;
      if (gifts.isEmpty) return const SizedBox.shrink();
      final bool isLocked = !widget.isHost &&
          (controller.isGiftAnimating.value ||
              controller.activeGifts.isNotEmpty);

      return Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 6),
        child: IgnorePointer(
          ignoring: isLocked,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isLocked ? 0.45 : 1.0,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: gifts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final gift = gifts[index];
                final price = gift.coinPrice ?? 0;
                String priceStr = price >= 1000
                    ? '${(price / 1000).toStringAsFixed(1)}K'
                    : '$price';

                String? tag;
                if (gift.displayName.toLowerCase().contains('love') ||
                    gift.title?.toLowerCase().contains('love') == true) {
                  tag = 'Love';
                }

                return GestureDetector(
                  onTap: isLocked
                      ? null
                      : () {
                          if (widget.isHost) {
                            controller.setFavouriteGift(gift);
                          } else {
                            controller.sendGiftDirect(gift);
                          }
                        },
                  child: SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            CustomImage(
                              size: const Size(40, 40),
                              image: gift.image?.addBaseURL(),
                              fit: BoxFit.contain,
                              radius: 4,
                            ),
                            if (tag != null)
                              Positioned(
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_rounded,
                                color: Color(0xFFE040FB), size: 11),
                            const SizedBox(width: 2),
                            Text(
                              priceStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // Sleek Bottom Bar (Unified for Host & Audience)
  // -------------------------------------------------------------
  Widget _buildBottomBar(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
      child: Row(
        children: [
          // "Say Hi!" input pill with "New" badge
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller.textCommentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      onSubmitted: (_) => controller.onTextCommentSend(),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Say Hi!',
                        hintStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.onTextCommentSend,
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFFFF7A19), size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Co-Host mic toggle if in call (audience side)
          if (!widget.isHost)
            Obx(() {
              final isCoHost = (controller.liveData.value.coHostIds ?? [])
                  .contains(controller.myUserId);
              if (!isCoHost) return const SizedBox.shrink();
              final isAudioOn = controller.isAudioOn.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.toggleMic(null),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: !isAudioOn
                          ? const Color(0xFFFF1744).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: !isAudioOn
                            ? const Color(0xFFFF1744)
                            : Colors.white24,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      isAudioOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      color: !isAudioOn
                          ? const Color(0xFFFF1744)
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),

          // Share button
          GestureDetector(
            onTap: _shareLive,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.reply_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Gift button: sets favourite gift for Host, opens sheet for Viewer
          GestureDetector(
            onTap: () {
              if (widget.isHost) {
                controller.showFavouriteGiftSheet(context);
              } else {
                VideoRoomGiftCategorySheet.show(
                  context: context,
                  controller: controller,
                );
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: Color(0xFFFF7A19), size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Heart like button
          Obx(() => LiveStreamLikeButton(
            likeCount: controller.liveData.value.likeCount ?? 0,
            size: 38,
            onLikeTap: (fn) => controller.onLikeTap = fn,
            onTap: controller.onLikeButtonTap,
          )),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Self-Contained Video Follow Button
// -------------------------------------------------------------
class _VideoFollowButton extends StatefulWidget {
  final int? hostId;

  const _VideoFollowButton({required this.hostId});

  @override
  State<_VideoFollowButton> createState() => _VideoFollowButtonState();
}

class _VideoFollowButtonState extends State<_VideoFollowButton> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.hostId == null) return;
    final user =
        await UserService.instance.fetchUserDetails(userId: widget.hostId);
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    if (_user?.id == null) return;
    final userId = _user!.id!;
    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: 'video_host_$userId')) {
      followController =
          Get.find<FollowController>(tag: 'video_host_$userId');
      followController.updateUser(_user);
    } else {
      followController =
          Get.put(FollowController(_user.obs), tag: 'video_host_$userId');
    }
    final updated = await followController.followUnFollowUser();
    if (updated != null && mounted) {
      setState(() {
        _user = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || widget.hostId == null) {
      return const SizedBox.shrink();
    }
    final isFollowing = _user?.isFollowing ?? false;
    if (isFollowing) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A00), Color(0xFFFF5200)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 10),
            SizedBox(width: 2),
            Text(
              'Follow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
