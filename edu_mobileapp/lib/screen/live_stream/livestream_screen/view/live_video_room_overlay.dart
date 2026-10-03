import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/live_room/live_share_sheet.dart';
import 'package:geoedu/common/widget/live_summary_dialog.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_comment.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/call_requested_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_like_button.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/members_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/other_lives_side_panel.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/video_room_gift_category_sheet.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_beauty_filter_sheet.dart';
import 'package:geoedu/screen/report_sheet/report_sheet.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
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
    final hostUser = widget.controller.liveData.value.hostUser;
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

    // Host Settings & Management sheet
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Live Settings & Management',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // 1. Members & Calls (Requests, Audience, Invited, Co-hosts)
              ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        color: Color(0xFFFF9500), size: 24),
                    Obx(() {
                      if (controller.requestList.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF1744),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 15, minHeight: 15),
                          alignment: Alignment.center,
                          child: Text(
                            '${controller.requestList.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                title: const Text('Members & Requests',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold)),
                subtitle: Obx(() => Text(
                  controller.requestList.isNotEmpty
                      ? '${controller.requestList.length} join request(s) waiting'
                      : 'Requests, Audience, Invited & Co-hosts',
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                )),
                onTap: () {
                  Get.back();
                  Get.bottomSheet(
                    const MembersSheet(isHost: true),
                    isScrollControlled: true,
                  );
                },
              ),

              // 2. Start PK Battle (Host with connected co-host)
              Obx(() {
                final stream = controller.liveData.value;
                final hasCoHost = controller.streamViews.length >= 2 ||
                    (stream.coHostIds != null && stream.coHostIds!.isNotEmpty);
                final isBattleRunning = stream.battleType == BattleType.running ||
                    stream.battleType == BattleType.waiting;
                if (!hasCoHost || isBattleRunning) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.sports_kabaddi_rounded,
                      color: Color(0xFFFF1744), size: 24),
                  title: const Text('Start PK Battle',
                      style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold)),
                  subtitle: const Text('Challenge connected co-host to a PK battle',
                      style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                  onTap: () {
                    Get.back();
                    HapticManager.shared.medium();
                    controller.startBattle();
                  },
                );
              }),

              ListTile(
                leading: const Icon(Icons.push_pin_outlined,
                    color: Color(0xFFFFB300)),
                title: const Text('Pin a Comment',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Keep an announcement at the top of chat',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                onTap: () {
                  Get.back();
                  controller.isPinInputOpen.value = true;
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard_rounded,
                    color: Color(0xFFFF7A19)),
                title: const Text('Set Favourite Gift',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Highlight a gift for your audience to send',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                onTap: () {
                  Get.back();
                  controller.showFavouriteGiftSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.face_retouching_natural_rounded,
                    color: Color(0xFFFFB300)),
                title: const Text('Beauty & Filters',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Smooth skin, Brighten, Blush, Sharpen',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                onTap: () {
                  Get.back();
                  LiveBeautyFilterSheet.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flip_camera_ios_rounded,
                    color: Color(0xFF00ADB5)),
                title: const Text('Flip Camera',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Get.back();
                  controller.toggleFlipCamera();
                },
              ),
              ListTile(
                leading: Obx(() => Icon(
                    controller.isAudioOn.value
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    color: controller.isAudioOn.value
                        ? Colors.white
                        : const Color(0xFFFF5252))),
                title: Obx(() => Text(
                    controller.isAudioOn.value ? 'Mute Microphone' : 'Unmute Microphone',
                    style: const TextStyle(color: Colors.white, fontSize: 14))),
                onTap: () {
                  Get.back();
                  controller.toggleMic(null);
                },
              ),
              const Divider(color: Colors.white12, height: 16),
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined,
                    color: Color(0xFFFF5252)),
                title: const Text('End Live Stream',
                    style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold)),
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
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

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
                          child: Stack(
                            children: [
                              Positioned.fill(
                                right: 68,
                                child: _buildChatList(controller),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 2,
                                child: _buildFloatingJoinCallButton(controller),
                              ),
                            ],
                          ),
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

  // -------------------------------------------------------------
  // Header Component
  // -------------------------------------------------------------
  Widget _buildHeader(LivestreamScreenController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Obx(() {
        final stream = controller.liveData.value;
        final hostUser = stream.hostUser;
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
                const SizedBox(width: 6),
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
                const SizedBox(width: 6),
                // Close button
                GestureDetector(
                  onTap: _handleBackOrClose,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 2: (Host level + Follow) on left, (Medal + "Lives >") on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
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
            Row(
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
    if (widget.isHost) return const SizedBox.shrink();
    return Obx(() {
      final gift = controller.featuredGift ??
          (controller.availableGifts.isNotEmpty
              ? controller.availableGifts.first
              : null);
      final bool isLocked = controller.isGiftAnimating.value ||
          controller.activeGifts.isNotEmpty;
      return GestureDetector(
        onTap: () {
          if (gift != null) {
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
                    'New',
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
  // Floating Join Call Button (Right side)
  // -------------------------------------------------------------
  Widget _buildFloatingJoinCallButton(LivestreamScreenController controller) {
    return Obx(() {
      final liveData = controller.liveData.value;
      final isBattleOn = liveData.type == LivestreamType.battle;
      final isCoHost =
          (liveData.coHostIds ?? []).contains(controller.myUserId);

      if (isBattleOn || liveData.isRestrictToJoin != 0) {
        return const SizedBox.shrink();
      }

      final pendingCount = controller.requestList.length;

      String label = 'Join Call';
      IconData icon = Icons.video_call_rounded;
      Color bgColor = Colors.white;
      Color iconColor = const Color(0xFF1E1E24);
      Color textColor = const Color(0xFF1E1E24);
      bool showRedDot = true;

      if (widget.isHost) {
        if (pendingCount == 0) return const SizedBox.shrink();
        label = 'Calls ($pendingCount)';
        icon = Icons.people_alt_rounded;
        bgColor = const Color(0xFFFF9500);
        iconColor = Colors.white;
        textColor = Colors.white;
        showRedDot = false;
      } else if (isCoHost) {
        label = 'In Call';
        icon = Icons.videocam_rounded;
        bgColor = const Color(0xFFFFB300);
        iconColor = Colors.black;
        textColor = Colors.black;
        showRedDot = false;
      } else {
        final myState = controller.liveUsersStates
            .firstWhereOrNull((u) => u.userId == controller.myUserId);
        final isRequested =
            myState?.type == LivestreamUserType.requested;
        if (isRequested) {
          label = 'Requested';
          icon = Icons.hourglass_top_rounded;
          bgColor = const Color(0xFFFF9500);
          iconColor = Colors.white;
          textColor = Colors.white;
          showRedDot = false;
        }
      }

      return GestureDetector(
        onTap: () {
          HapticManager.shared.light();
          if (widget.isHost) {
            Get.bottomSheet(
              const MembersSheet(isHost: true),
              isScrollControlled: true,
            );
          } else if (isCoHost) {
            controller.toggleMic(null);
          } else {
            final myState = controller.liveUsersStates
                .firstWhereOrNull((u) => u.userId == controller.myUserId);
            final isRequested =
                myState?.type == LivestreamUserType.requested;
            if (isRequested) {
              CallRequestedSheet.show(context);
            } else {
              controller.onVideoRequestSend(liveData);
            }
          }
        },
        child: Container(
          width: 56,
          height: 54,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (showRedDot)
                Positioned(
                  top: 6,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF1744),
                      shape: BoxShape.circle,
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
      final topUser = controller.topGifterName.value.isNotEmpty
          ? controller.topGifterName.value
          : 'Aman';

      return Container(
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
      final hostUser = stream.hostUser;
      final hostName = hostUser?.fullname ?? hostUser?.username ?? 'Host';
      final hostPhoto = hostUser?.profile?.addBaseURL();
      final title = stream.description ?? stream.topicName ?? 'प्यार के तराने 🎵';

      return ListView(
        padding: EdgeInsets.zero,
        reverse: true,
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

          // 3. Host Interaction Call banner (Audience only)
          if (!widget.isHost)
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
                              text: '$hostName ',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: 'said Hi to you! Request Call',
                              style: TextStyle(
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
                        controller.onVideoRequestSend(controller.liveData.value);
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
      case LivestreamCommentType.joinedCoHost:
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
  // Horizontal Quick Gift 1-Tap Bar (Audience)
  // -------------------------------------------------------------
  Widget _buildQuickGiftBar(LivestreamScreenController controller) {
    if (widget.isHost) return const SizedBox.shrink();
    return Obx(() {
      final gifts = controller.availableGifts;
      if (gifts.isEmpty) return const SizedBox.shrink();
      final bool isLocked = controller.isGiftAnimating.value ||
          controller.activeGifts.isNotEmpty;

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
                      : () => controller.sendGiftDirect(gift),
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
  // Sleek Bottom Bar
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

          if (widget.isHost) ...[
            // Host Mic Toggle
            Obx(() {
              final isAudioOn = controller.isAudioOn.value;
              return GestureDetector(
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
                    color: !isAudioOn ? const Color(0xFFFF1744) : Colors.white,
                    size: 20,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),

            // Host Flip Camera
            GestureDetector(
              onTap: controller.toggleFlipCamera,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(
                  Icons.flip_camera_ios_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 8),

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

            // Gift button: sets favourite gift for this live!
            GestureDetector(
              onTap: () => controller.showFavouriteGiftSheet(context),
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
          ] else ...[
            // Co-Host mic toggle if in call
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
                      color:
                          !isAudioOn ? const Color(0xFFFF1744) : Colors.white,
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

            // Gift button: opens category gift sheet
            GestureDetector(
              onTap: () => VideoRoomGiftCategorySheet.show(
                context: context,
                controller: controller,
              ),
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
