import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/level_badge.dart';
import 'package:geoedu/common/manager/share_manager.dart';
import 'package:geoedu/common/widget/live_room/live_share_sheet.dart';
import 'package:geoedu/model/audio_call/audio_comment.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';

import 'package:geoedu/model/audio_call/online_user.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/entry_effects_widget.dart'
    show GiftEffectWidget;
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_like_button.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
import 'package:geoedu/utilities/audio_theme_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';

import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_start_countdown_overlay.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/other_lives_side_panel.dart';

class AudioRoomScreen extends StatefulWidget {
  final AudioRoom room;
  final bool isHost;

  const AudioRoomScreen({
    super.key,
    required this.room,
    required this.isHost,
  });

  // Kept as an alias so existing call sites in this file don't need to
  // change — real source of truth is now AudioThemeRes.presets, shared
  // with the Go-Live setup screen's theme-card gallery.
  static const List<List<Color>> themePresets = AudioThemeRes.presets;

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  bool _showCountdown = true;
  bool _showOtherLives = false;
  late final AudioRoomController controller;

  AudioRoom get room => widget.room;
  bool get isHost => widget.isHost;
  List<List<Color>> get themePresets => AudioRoomScreen.themePresets;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AudioRoomController(room: widget.room, isHost: widget.isHost),
    );
    controller.onPkInviteReceived = (inviterHostId) =>
        _showPkInviteDialog(controller, inviterHostId);
    if (!widget.isHost) {
      _showCountdown = false;
    }
  }

  void showSnackBar(String message) {
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isHost) {
          controller.endRoom();
        } else {
          controller.leaveRoom();
        }
      },
      child: Scaffold(
        backgroundColor: ColorRes.blackPure,
        body: Stack(
          children: [
            Obx(() {
          final bgUrl = controller.backgroundImage.value.isNotEmpty
              ? controller.backgroundImage.value.addBaseURL()
              : null;
          final themeColors = controller.themeIndex.value != null &&
                  controller.themeIndex.value! < themePresets.length
              ? themePresets[controller.themeIndex.value!]
              : themePresets[0];
          return Container(
            decoration: BoxDecoration(
              gradient: bgUrl == null
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: themeColors,
                    )
                  : null,
              image: bgUrl != null
                  ? DecorationImage(
                      image: NetworkImage(bgUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                    )
                  : null,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Top Header: Punam + Follow, LIVE, viewers, settings, close, top contributors, Lives >
                  _buildHeader(controller),

                  // PK battle bar (if active)
                  Obx(() => controller.pkStatus.value == 'running'
                      ? _buildPkBattleBar(controller)
                      : const SizedBox.shrink()),

                  // Top cards row: Left Floating Gift Mission (0/3 50% Send) & Right Dashed Join Call card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFloatingGiftCard(controller),
                        _buildDashedJoinCallCard(controller),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Stage: Host Avatar (gold ring) + Soundwave Audio Visualizer (||||)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHostAvatar(controller),
                      const SizedBox(height: 10),
                      const _AudioWaveVisualizer(),
                    ],
                  ),

                  // Extra speakers mini row (if multiple participants are speaking)
                  _buildSpeakersMiniRow(controller),

                  Obx(() => controller.pinnedComment.value.isNotEmpty
                      ? _buildPinnedCommentBanner(controller)
                      : const SizedBox.shrink()),

                  if (isHost) _buildPinCommentInput(controller),

                  const Spacer(),

                  // 3. Middle-lower area: Top gifter badge + Chat & Event list + Floating Join Call
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopGifterPill(controller),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 120, // Compact height matching reference screenshot
                          child: Stack(
                            children: [
                              Positioned.fill(
                                right: 68,
                                child: _buildChatList(controller),
                              ),
                              // Floating Join Call white squircle button on the right
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

                  // 4. Horizontal Gift Quick Bar (Rose 💎3, Love 💎9, Car 💎298, Castle 💎2.5K...)
                  _buildQuickGiftBar(controller),

                  // 5. Bottom Input & Action Bar (Say Hi!, Share, Gift, Heart)
                  _buildBottomBar(controller),
                ],
              ),
            ),
          );
            }),
            GiftEffectWidget(activeGifts: controller.activeGifts),
            if (_showOtherLives) ...[
              // Barrier dismiss on tap outside
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _showOtherLives = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              OtherLivesSidePanel(
                currentAudioHostId: room.hostId,
                onClose: () {
                  setState(() {
                    _showOtherLives = false;
                  });
                },
              ),
            ],
            if (_showCountdown && widget.isHost)
              LiveStartCountdownOverlay(
                isVideo: false,
                onFinished: () {
                  if (mounted) {
                    setState(() {
                      _showCountdown = false;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGiftersHeader(AudioRoomController controller) {
    return Obx(() {
      final participants = controller.participants.take(3).toList();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (participants.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(participants.length, (index) {
                final p = participants[index];
                final medalColor = index == 0
                    ? const Color(0xFFFFD700)
                    : (index == 1
                        ? const Color(0xFFC0C0C0)
                        : const Color(0xFFCD7F32));
                return Container(
                  margin: const EdgeInsets.only(right: 3),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: medalColor, width: 1.5),
                        ),
                        child: CustomImage(
                          size: const Size(22, 22),
                          image: p.profilePhoto,
                          radius: 11,
                          fullName: p.fullname,
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: medalColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 6,
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
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _showOtherLives = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
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

  void _showTopGiftersSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Contributors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${controller.participantIds.length} viewers',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final list = controller.participants;
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No contributors yet',
                        style: TextStyle(color: Colors.white54)),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length > 5 ? 5 : list.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12, height: 16),
                itemBuilder: (context, index) {
                  final user = list[index];
                  final rankColor = index == 0
                      ? const Color(0xFFFFD700)
                      : (index == 1
                          ? const Color(0xFFC0C0C0)
                          : (index == 2
                              ? const Color(0xFFCD7F32)
                              : Colors.white54));
                  return Row(
                    children: [
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomImage(
                        size: const Size(36, 36),
                        image: user.profilePhoto,
                        radius: 18,
                        fullName: user.fullname,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.fullname ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium,
                                color: Color(0xFFFFD700), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${500 - index * 100}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildHeader(AudioRoomController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Host avatar + name + star count + Follow button
          Expanded(
            child: Row(
              children: [
                CustomImage(
                  size: const Size(36, 36),
                  image: room.hostPhoto,
                  radius: 18,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFFFFB300),
                  fullName: room.hostName,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              room.hostName ?? 'Punam',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.workspace_premium,
                              color: Color(0xFFFFB300), size: 14),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bar_chart_rounded,
                                    color: Color(0xFFFF7A19), size: 12),
                                const SizedBox(width: 3),
                                Obx(() => Text(
                                      '${controller.hostStarTotal.value > 0 ? controller.hostStarTotal.value : 6}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          if (!isHost) ...[
                            const SizedBox(width: 6),
                            _AudioFollowButton(hostId: room.hostId),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Row 1 (LIVE, Viewers, Settings, Close) + Row 2 (Top contributors + Lives >)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LIVE badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
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
                      Obx(() => Text(
                            '${controller.participantIds.isNotEmpty ? controller.participantIds.length : 10}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(width: 6),
                  // Settings gear
                  GestureDetector(
                    onTap: () => _showThemesSheet(controller),
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 6),
                  // Close
                  GestureDetector(
                    onTap: () {
                      if (isHost) {
                        controller.endRoom();
                      } else {
                        controller.leaveRoom();
                      }
                    },
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildTopGiftersHeader(controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerPill({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildPromoGiftCard(AudioRoomController controller) {
    final gift = controller.featuredGift;
    if (gift == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: controller.isHost
          ? () => _showFavouriteGiftSheet(controller)
          : () => _showCategoryGiftsSheet(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.featuredGiftIsNew)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: ColorRes.primaryColor, borderRadius: BorderRadius.circular(4)),
                child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            CustomImage(size: const Size(26, 26), image: gift.image?.addBaseURL(), fullName: gift.title, radius: 6),
            const SizedBox(width: 6),
            const Icon(Icons.diamond, color: ColorRes.primaryColor, size: 13),
            const SizedBox(width: 3),
            Text('${gift.coinPrice ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showSetTargetDialog(AudioRoomController controller) {
    final textController = TextEditingController(
        text: controller.targetDiamonds.value > 0 ? controller.targetDiamonds.value.toString() : '');
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorRes.cardBackground,
        title: const Text('Set Diamond Target', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'e.g. 5000', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.setTargetDiamonds(int.tryParse(textController.text.trim()) ?? 0);
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGiftCard(AudioRoomController controller) {
    if (isHost) return const SizedBox.shrink();
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
            _showCategoryGiftsSheet(controller);
          }
        },
        child: Container(
          width: 64,
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CustomImage(
                    size: const Size(36, 36),
                    image: gift?.image?.addBaseURL(),
                    radius: 6,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '50%',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                '0/3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A00), Color(0xFFFF5200)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5200).withValues(alpha: 0.4),
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

  Widget _buildDashedJoinCallCard(AudioRoomController controller) {
    // The host is already in the room and hosting, so they must never see a Join Call card
    if (isHost) return const SizedBox.shrink();

    return Obx(() {
      final isSpeaker = controller.isSpeaker.value;
      final hasRequested = controller.hasRequested.value;

      String label = 'Join Call';
      IconData icon = Icons.video_call_rounded;
      Color iconColor = Colors.white;

      if (isSpeaker) {
        label = 'In Call';
        icon = Icons.mic;
        iconColor = const Color(0xFFFFB300);
      } else if (hasRequested) {
        label = 'Requested';
        icon = Icons.hourglass_top_rounded;
        iconColor = const Color(0xFFFF9500);
      }

      return GestureDetector(
        onTap: () {
          if (isSpeaker) {
            controller.toggleMute();
          } else if (hasRequested) {
            controller.showSnackBar('Join Call request is pending host approval');
          } else {
            controller.requestToSpeak();
          }
        },
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: hasRequested
                ? const Color(0xFFFF9500)
                : Colors.white.withValues(alpha: 0.7),
            dashWidth: 4,
            dashSpace: 3,
            strokeWidth: 1.2,
            radius: 16,
          ),
          child: Container(
            width: 66,
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasRequested
                        ? const Color(0xFFFF9500)
                        : (isSpeaker ? const Color(0xFFFFB300) : Colors.white),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHostAvatar(AudioRoomController controller) {
    return Obx(() {
      final bool royal = controller.isRoyalMode.value;
      const Color accent = Color(0xFFFFB300);
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent,
                  width: 2.5,
                ),
              ),
              child: CustomImage(
                size: const Size(84, 84),
                image: room.hostPhoto,
                radius: 42,
                fullName: room.hostName,
              ),
            ),
          ),
          if (royal)
            const Positioned(
              top: -10,
              child: Icon(Icons.workspace_premium,
                  color: Color(0xFFFFB300), size: 22),
            ),
        ],
      );
    });
  }

  Widget _buildSpeakersMiniRow(AudioRoomController controller) {
    return Obx(() {
      final speakerIds = controller.speakerIds
          .where((id) => id != room.hostId)
          .toList();
      if (speakerIds.isEmpty) return const SizedBox.shrink();
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(top: 4),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: speakerIds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, index) {
            final userId = speakerIds[index];
            final participant = controller.participants
                .where((p) => p.userId == userId)
                .firstOrNull;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomImage(
                  size: const Size(36, 36),
                  image: participant?.profilePhoto,
                  radius: 18,
                  strokeWidth: 1.5,
                  strokeColor: const Color(0xFFFFB300),
                  fullName: participant?.fullname,
                ),
                Text(
                  participant?.fullname ?? 'Speaker',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildTopGifterPill(AudioRoomController controller) {
    return Obx(() {
      final topUser = controller.topGifterName.value;
      if (topUser.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const Icon(Icons.workspace_premium,
                color: Color(0xFFFFB300), size: 14),
            const SizedBox(width: 4),
            Text(
              '$topUser - Top Gifter',
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFloatingJoinCallButton(AudioRoomController controller) {
    return Obx(() {
      final isSpeaker = controller.isSpeaker.value;
      final hasRequested = controller.hasRequested.value;
      final pendingCount = controller.requestIds.length;

      String label = 'Join Call';
      IconData icon = Icons.video_call_rounded;
      Color iconColor = const Color(0xFF1E1E24);
      Color bgColor = Colors.white;

      if (isHost) {
        // Host is already hosting, never show "Join Call". Only show if there are pending requests to manage.
        if (pendingCount == 0) return const SizedBox.shrink();
        label = 'Calls ($pendingCount)';
        icon = Icons.people_alt_rounded;
      } else if (isSpeaker) {
        label = 'In Call';
        icon = Icons.mic;
        bgColor = const Color(0xFFFFB300);
      } else if (hasRequested) {
        label = 'Requested';
        icon = Icons.hourglass_top_rounded;
        bgColor = const Color(0xFFFF9500);
      }

      return GestureDetector(
        onTap: () {
          if (isHost) {
            _showRequestsSheet(controller);
          } else if (isSpeaker) {
            controller.toggleMute();
          } else if (hasRequested) {
            controller.showSnackBar('Join Call request is pending host approval');
          } else {
            controller.requestToSpeak();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                if ((isHost && pendingCount > 0) || (!isHost && hasRequested))
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isHost ? const Color(0xFFFF1744) : const Color(0xFFFF9500),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: hasRequested ? const Color(0xFFFF9500) : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickGiftBar(AudioRoomController controller) {
    if (isHost) return const SizedBox.shrink();
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
                  onTap: isLocked ? null : () => controller.sendGiftDirect(gift),
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

  Widget _buildBottomBar(AudioRoomController controller) {
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
                      onSubmitted: (_) => controller.sendTextComment(),
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
                    onTap: controller.sendTextComment,
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFFFF7A19), size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isHost) ...[
            // Host Mute/Unmute Mic Button
            Obx(() {
              final isMuted = controller.isMuted.value;
              return GestureDetector(
                onTap: controller.toggleMute,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isMuted
                        ? const Color(0xFFFF1744).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMuted ? const Color(0xFFFF1744) : Colors.white24,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: isMuted ? const Color(0xFFFF1744) : Colors.white,
                    size: 20,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            // Host Switch Audio Route (Speaker / Earpiece)
            Obx(() {
              final isSpeakerOn = controller.isSpeakerOn.value;
              return GestureDetector(
                onTap: controller.toggleSpeaker,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Icon(
                    isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.phone_in_talk_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            // Share button
            GestureDetector(
              onTap: () => _shareRoom(controller),
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
            // Heart like button
            LiveStreamLikeButton(
              onLikeTap: (fn) => controller.onLikeTap = fn,
              onTap: controller.onLikeButtonTap,
            ),
          ] else ...[
            // Speaker Mute/Unmute if approved speaker
            Obx(() {
              if (!controller.isSpeaker.value) return const SizedBox.shrink();
              final isMuted = controller.isMuted.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: controller.toggleMute,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isMuted
                          ? const Color(0xFFFF1744).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isMuted ? const Color(0xFFFF1744) : Colors.white24,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: isMuted ? const Color(0xFFFF1744) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
            // Share button
            GestureDetector(
              onTap: () => _shareRoom(controller),
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
            // Gift button (Listeners send to host)
            GestureDetector(
              onTap: () => _showCategoryGiftsSheet(controller),
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
            LiveStreamLikeButton(
              onLikeTap: (fn) => controller.onLikeTap = fn,
              onTap: controller.onLikeButtonTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinnedCommentBanner(AudioRoomController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: ColorRes.gold, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => Text(controller.pinnedComment.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12))),
          ),
          if (isHost)
            GestureDetector(
              onTap: controller.clearPinnedComment,
              child: const Icon(Icons.close, color: Colors.white54, size: 16),
            )
          else
            const Icon(Icons.expand_more, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _buildPinCommentInput(AudioRoomController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.pinCommentController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    onSubmitted: (_) => controller.submitPinnedComment(),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Type your pin comment here…',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: controller.submitPinnedComment,
                  child: const Icon(Icons.push_pin_outlined, color: ColorRes.gold, size: 18),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 3, left: 4),
            child: Text('Comments will be pinned to top',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(AudioRoomController controller) {
    return Obx(() {
      final comments = controller.comments;
      return ListView(
        padding: EdgeInsets.zero,
        reverse: true,
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.reply_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Share this LIVE room with your friends.',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _shareRoom(controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Share',
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...comments.reversed.map((comment) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImage(
                    size: const Size(22, 22),
                    image: comment.senderPhoto?.addBaseURL(),
                    fullName: comment.senderName,
                    radius: 11,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _buildCommentContent(controller, comment)),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildCommentContent(AudioRoomController controller, AudioComment comment) {
    final myUserId = controller.myUser?.id ?? SessionManager.instance.getUserID();
    final myUsername = (controller.myUser?.username ?? SessionManager.instance.getUser()?.username ?? '').toLowerCase().trim();
    final isMe = (comment.senderId > 0 && comment.senderId == myUserId) ||
        (myUsername.isNotEmpty && comment.senderName.toLowerCase().trim() == myUsername);
    final displayName = isMe ? 'You' : comment.senderName;

    Widget nameRow(Widget trailing) => Row(
          children: [
            Flexible(
              child: Text(displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            if ((comment.senderLevel ?? 0) > 0) ...[
              const SizedBox(width: 4),
              LevelBadge(level: comment.senderLevel, navigateOnTap: false),
            ],
            const SizedBox(width: 6),
            trailing,
          ],
        );

    switch (comment.type) {
      case AudioCommentType.joined:
        return nameRow(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('joined the room', style: TextStyle(color: Colors.white54, fontSize: 11)),
            if (isHost) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.sendWave(comment.senderName),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Wave 👋', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ],
        ));
      case AudioCommentType.gift:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow(const SizedBox.shrink()),
            Row(
              children: [
                CustomImage(size: const Size(22, 22), image: comment.giftImage?.addBaseURL(), radius: 4),
                const SizedBox(width: 4),
                Text('sent ${comment.giftName} · ${comment.giftCoinPrice ?? 0} 💎',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        );
        
      case AudioCommentType.text:
        final text = comment.text ?? '';
        final isCallReq = text.contains('Join Call');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow(isCallReq && isHost
                ? GestureDetector(
                    onTap: () {
                      if (comment.senderId > 0) {
                        controller.acceptSpeaker(comment.senderId);
                      } else {
                        _showRequestsSheet(controller);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9500),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Accept',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                : const SizedBox.shrink()),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 11.5)),
          ],
        );
    }
  }

  Widget _buildChatInput(AudioRoomController controller) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.textCommentController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => controller.sendTextComment(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Write here...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.sendTextComment,
            child: const Icon(Icons.send_rounded, color: Color(0xFFFF7A19), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid(AudioRoomController controller) {
    return Obx(() {
      final speakerIds = controller.speakerIds;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AudioRoomController.maxSpeakerSeats,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (_, index) {
            final userId = index < speakerIds.length ? speakerIds[index] : null;
            final participant = userId == null
                ? null
                : controller.participants
                    .where((p) => p.userId == userId)
                    .firstOrNull;
            return _buildSeatTile(index, participant, controller);
          },
        ),
      );
    });
  }

  Widget _buildSeatTile(
      int index, OnlineUser? participant, AudioRoomController controller) {
    final seatLabel = 'No.${index + 1}';

    if (participant == null) {
      return Obx(() {
        final isLocked = controller.lockedSeatIndices.contains(index);
        final canRequest = !isHost && !isLocked && !controller.isSpeaker.value;
        return GestureDetector(
          onTap: isHost
              ? () => _showEmptySeatHostMenu(controller, index)
              : (canRequest && !controller.hasRequested.value
                  ? controller.requestToSpeak
                  : null),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorRes.cardBackground,
                  border: Border.all(
                    color: ColorRes.gold,
                    width: 2,
                  ),
                ),
                child: Icon(isLocked ? Icons.lock : Icons.chair_alt,
                    color: ColorRes.gold, size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                seatLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      });
    }

    final hasRequested = controller.requestIds.contains(participant.userId);
    return Obx(() {
      final isMuted = controller.mutedSpeakerIds.contains(participant.userId);
      return GestureDetector(
        onTap: isHost
            ? () => _showOccupiedSeatHostMenu(controller, participant, isMuted)
            : null,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorRes.primaryColor,
                      width: 4,
                    ),
                  ),
                  child: CustomImage(
                    size: const Size(48, 48),
                    image: participant.profilePhoto,
                    radius: 24,
                    fullName: participant.fullname,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor:
                        isMuted ? ColorRes.liveRed : ColorRes.primaryColor,
                    child: Icon(isMuted ? Icons.mic_off : Icons.mic,
                        size: 12, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              participant.fullname ?? 'User',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasRequested)
              const Text('requested',
                  style: TextStyle(color: Colors.orange, fontSize: 8)),
          ],
        ),
      );
    });
  }

  void _showEmptySeatHostMenu(
      AudioRoomController controller, int seatIndex) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final isLocked = controller.lockedSeatIndices.contains(seatIndex);
                return ListTile(
                  leading: Icon(isLocked ? Icons.lock_open : Icons.lock,
                      color: ColorRes.gold),
                  title: Text(isLocked ? 'Unlock Seat' : 'Lock Seat',
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    controller.toggleLockSeat(seatIndex);
                  },
                );
              }),
              ListTile(
                leading: const Icon(Icons.person_add, color: ColorRes.primaryColor),
                title: const Text('Invite a Listener', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  _showInviteListenerSheet(controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteListenerSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.5),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Invite to Speak',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Flexible(
              child: Obx(() {
                final listeners = controller.participants
                    .where((p) => !controller.speakerIds.contains(p.userId))
                    .toList();
                if (listeners.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No listeners available to invite',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: listeners.length,
                  itemBuilder: (context, index) {
                    final user = listeners[index];
                    return ListTile(
                      leading: CustomImage(
                        size: const Size(36, 36),
                        image: user.profilePhoto,
                        radius: 18,
                        fullName: user.fullname,
                      ),
                      title: Text(user.fullname ?? 'User',
                          style: const TextStyle(color: Colors.white)),
                      trailing: TextButton(
                        onPressed: () {
                          Get.back();
                          if (user.userId != null) controller.acceptSpeaker(user.userId!);
                        },
                        child: const Text('Invite', style: TextStyle(color: ColorRes.primaryColor)),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showOccupiedSeatHostMenu(
      AudioRoomController controller, OnlineUser participant, bool isMuted) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isMuted ? Icons.mic : Icons.mic_off,
                    color: ColorRes.primaryColor),
                title: Text(isMuted ? 'Unmute' : 'Mute',
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  if (participant.userId != null) {
                    controller.toggleMuteParticipant(participant.userId!);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: ColorRes.liveRed),
                title: const Text('Remove from Seat', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  _showRevokeSeatDialog(controller, participant);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPkInviteDialog(
      AudioRoomController controller, int inviterHostId) async {
    String inviterName = 'Host $inviterHostId';
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseConst.audioRooms)
          .doc(inviterHostId.toString())
          .get();
      if (doc.exists) {
        inviterName = doc.data()?['host_name'] ?? inviterName;
      }
    } catch (_) {}

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorRes.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$inviterName invited you to a PK Battle',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.rejectPkBattle();
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.acceptPkBattle();
            },
            child:
                const Text('Accept', style: TextStyle(color: ColorRes.primaryColor)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildPkBattleBar(AudioRoomController controller) {
    return Obx(() {
      final opponent = controller.opponentRoom.value;
      final myCoins = controller.myPkCoins.value;
      final theirCoins = controller.opponentPkCoins.value;
      final total = myCoins + theirCoins == 0 ? 1 : myCoins + theirCoins;
      final remaining = controller.pkRemainingSeconds.value;
      final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
      final seconds = (remaining % 60).toString().padLeft(2, '0');

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CustomImage(
                  size: const Size(36, 36),
                  image: room.hostPhoto,
                  radius: 18,
                  fullName: room.hostName,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        final myWidth = barWidth * myCoins / total;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(height: 8, color: Colors.white24),
                              Row(
                                children: [
                                  Container(
                                      height: 8,
                                      width: myWidth,
                                      color: const Color(0xffFF4D6D)),
                                  Container(
                                      height: 8,
                                      width: barWidth - myWidth,
                                      color: ColorRes.green1),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                CustomImage(
                  size: const Size(36, 36),
                  image: opponent?.hostPhoto,
                  radius: 18,
                  fullName: opponent?.hostName,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$myCoins', style: const TextStyle(color: Colors.white)),
                Text('$minutes:$seconds',
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
                Text('$theirCoins', style: const TextStyle(color: Colors.white)),
              ],
            ),
            if (isHost)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton(
                  onPressed: controller.endPkBattle,
                  child: const Text('End Battle',
                      style: TextStyle(color: ColorRes.liveRed, fontSize: 12)),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showPkInviteListSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(Get.context!).size.height * 0.5),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Invite to PK Battle',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<AudioRoom>>(
                future: controller.fetchOtherLiveHosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: ColorRes.primaryColor)),
                    );
                  }
                  final hosts = snapshot.data ?? [];
                  if (hosts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No other live hosts right now',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: hosts.length,
                    itemBuilder: (context, index) {
                      final host = hosts[index];
                      return ListTile(
                        leading: CustomImage(
                          size: const Size(40, 40),
                          image: host.hostPhoto,
                          radius: 20,
                          fullName: host.hostName,
                        ),
                        title: Text(host.hostName ?? 'Host',
                            style: const TextStyle(color: Colors.white)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            controller.invitePkBattle(host.hostId!);
                            controller.showSnackBar(
                                'Invite sent to ${host.hostName ?? "host"}');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: ColorRes.primaryColor),
                          child: const Text('Invite',
                              style: TextStyle(color: Colors.black)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeSeatDialog(
      AudioRoomController controller, OnlineUser participant) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorRes.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${participant.fullname ?? "user"} from seat?',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (participant.userId != null) {
                controller.revokeSpeaker(participant.userId!);
              }
            },
            child: const Text('Remove',
                style: TextStyle(color: ColorRes.liveRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(AudioRoomController controller) {
    if (isHost) {
      return Obx(() {
        final count = controller.requestIds.length;
        return GestureDetector(
          onTap: () => _showRequestsSheet(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: count > 0
                  ? ColorRes.primaryColor
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.record_voice_over, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  count > 0 ? 'Requests ($count)' : 'Speaker Requests',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    } else {
      return Obx(() {
        if (controller.isSpeaker.value) {
          return Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: ColorRes.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: ColorRes.primaryColor, width: 1.2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: ColorRes.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'You are a speaker',
                  style: TextStyle(
                    color: ColorRes.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return GestureDetector(
          onTap: controller.hasRequested.value ? null : controller.requestToSpeak,
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  controller.hasRequested.value ? Icons.hourglass_top : Icons.front_hand,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.hasRequested.value ? 'Request Pending...' : 'Request to Speak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  Widget _buildInlineGiftBar(AudioRoomController controller) {
    return Obx(() {
      final gifts = controller.availableGifts.isNotEmpty
          ? controller.availableGifts
          : (SessionManager.instance.getSettings()?.availableGifts ?? []);

      if (gifts.isEmpty && controller.availableGifts.isEmpty) {
        CommonService.instance.fetchGlobalSettings().then((_) {
          final fresh = SessionManager.instance.getSettings();
          if (fresh != null && fresh.availableGifts.isNotEmpty) {
            controller.availableGifts.value = fresh.availableGifts;
          }
        });
      }

      final favouriteId = controller.favouriteGiftId.value;
      final sortedGifts = List<Gift>.from(gifts);
      if (favouriteId != null) {
        sortedGifts.sort((a, b) => (a.id == favouriteId ? 0 : 1)
            .compareTo(b.id == favouriteId ? 0 : 1));
      }

      return Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: ColorRes.cardBackground.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Send a gift to ${room.hostName ?? "host"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await Get.to(() => StarStoreDiamondScreen(
                          onPurchaseCompleted: () {
                            Get.back(); // return to audio room
                            controller.fetchDiamondBalance();
                          },
                        ));
                    controller.fetchDiamondBalance();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Obx(() => Text(
                              '${controller.diamondBalance.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 10),
                              SizedBox(width: 2),
                              Text(
                                'Buy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 106,
              child: sortedGifts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: ColorRes.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: sortedGifts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final gift = sortedGifts[index];
                        final isFavourite =
                            gift.id != null && gift.id == favouriteId;

                        String? badgeText;
                        if (gift.categoryName != null &&
                            gift.categoryName!.isNotEmpty) {
                          badgeText = gift.categoryName;
                        } else if (gift.createdAt != null &&
                            DateTime.now().difference(gift.createdAt!).inDays <=
                                7) {
                          badgeText = 'New';
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: (controller.isGiftAnimating.value ||
                                  controller.activeGifts.isNotEmpty)
                              ? null
                              : () => controller.sendGiftDirect(gift),
                          child: Container(
                            width: 76,
                            height: 104,
                            decoration: BoxDecoration(
                              color: isFavourite
                                  ? const Color(0xFF2E221B)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: isFavourite
                                  ? Border.all(color: ColorRes.gold, width: 2)
                                  : Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      width: 1),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      height: 16,
                                      child: badgeText != null
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: badgeText
                                                        .toLowerCase()
                                                        .contains('love')
                                                    ? const Color(0xFFE91E63)
                                                    : const Color(0xFFFFB300),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: CustomImage(
                                          image: gift.image?.addBaseURL(),
                                          size: const Size(50, 50),
                                          fit: BoxFit.contain,
                                          radius: 4,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.diamond,
                                            color: Colors.white, size: 12),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${gift.coinPrice ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                                if (isFavourite)
                                  const Positioned(
                                    top: 5,
                                    right: 6,
                                    child: Icon(Icons.star,
                                        size: 14, color: ColorRes.gold),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMainBottomSection(AudioRoomController controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChatInput(controller),
                    if (!isHost) ...[
                      const SizedBox(height: 8),
                      _buildInlineGiftBar(controller),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildRightIconColumn(controller),
            ],
          ),
          const SizedBox(height: 10),
          _buildBottomRow(controller),
        ],
      ),
    );
  }

  Widget _buildBottomRow(AudioRoomController controller) {
    if (isHost) {
      return Row(
        children: [
          Expanded(child: _buildRequestButton(controller)),
          Obx(() => controller.pkStatus.value == 'running'
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _pillButton(
                    icon: Icons.bolt,
                    label: 'PK Battle',
                    color: ColorRes.primaryColor,
                    onTap: () => _showPkInviteListSheet(controller),
                  ),
                )),
        ],
      );
    } else {
      return _buildRequestButton(controller);
    }
  }

  Widget _pillButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRightIconColumn(AudioRoomController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final canSpeak = isHost || controller.isSpeaker.value;
          if (!canSpeak) return const SizedBox.shrink();
          return Column(
            children: [
              _sideIcon(
                  icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                  label: controller.isMuted.value ? 'Unmute' : 'Mute',
                  iconColor: controller.isMuted.value ? ColorRes.liveRed : Colors.white,
                  onTap: controller.toggleMute),
              const SizedBox(height: 10),
            ],
          );
        }),
        Transform.scale(
          scale: 0.72,
          child: LiveStreamLikeButton(
            onLikeTap: (fn) => controller.onLikeTap = fn,
            onTap: controller.onLikeButtonTap,
          ),
        ),
        const SizedBox(height: 10),
        if (isHost)
          _sideIcon(
              icon: Icons.call,
              label: 'Calls',
              onTap: () => _showRequestsSheet(controller))
        else
          _sideIcon(
              icon: Icons.card_giftcard,
              label: 'Gift',
              onTap: () => _showCategoryGiftsSheet(controller)),
        const SizedBox(height: 10),
        _sideIcon(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareRoom(controller)),
        const SizedBox(height: 10),
        _sideIcon(
            icon: Icons.more_horiz,
            label: 'More',
            onTap: () => _showMoreSheet(controller)),
      ],
    );
  }

  Widget _sideIcon(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _shareRoom(AudioRoomController controller) {
    final myUser = SessionManager.instance.getUser();
    final shareLink = ShareManager.shared.getLink(key: ShareKeys.user, value: room.hostId ?? -1);
    LiveShareSheet.show(
      context: Get.context!,
      hostName: room.hostName ?? 'Host',
      hostPhotoUrl: room.hostPhoto,
      currentUserName: myUser?.fullname ?? myUser?.username ?? 'You',
      currentUserPhotoUrl: myUser?.profilePhoto,
      shareLink: shareLink,
      isAudio: true,
      isHost: isHost,
    );
  }

  void _showThemesSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Themes',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < AudioRoomScreen.themePresets.length; i++)
                    GestureDetector(
                      onTap: () {
                        controller.setTheme(i);
                        Get.back();
                      },
                      child: Obx(() => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AudioRoomScreen.themePresets[i],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: controller.themeIndex.value == i &&
                                      controller.backgroundImage.value.isEmpty
                                  ? Border.all(color: ColorRes.gold, width: 2)
                                  : null,
                            ),
                          )),
                    ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      controller.changeBackgroundImage();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate,
                          color: Colors.white70, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final canSpeak = isHost || controller.isSpeaker.value;
                if (!canSpeak) return const SizedBox.shrink();
                return ListTile(
                  leading: Icon(
                      controller.isMuted.value ? Icons.mic_off : Icons.mic,
                      color: ColorRes.primaryColor),
                  title: Text(controller.isMuted.value ? 'Unmute' : 'Mute',
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    controller.toggleMute();
                  },
                );
              }),
              Obx(() => ListTile(
                    leading: Icon(
                        controller.isSpeakerOn.value
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: ColorRes.primaryColor),
                    title: Text(
                        controller.isSpeakerOn.value ? 'Speaker On' : 'Speaker Off',
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Get.back();
                      controller.toggleSpeaker();
                    },
                  )),
              Obx(() => controller.musicUrls.isNotEmpty
                  ? ListTile(
                      leading: Icon(
                          controller.isMusicPlaying.value
                              ? Icons.music_note
                              : Icons.music_off,
                          color: ColorRes.primaryColor),
                      title: Text(
                          controller.isMusicPlaying.value ? 'Pause Music' : 'Play Music',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${controller.musicUrls.length} tracks',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                      trailing: controller.musicUrls.length > 1
                          ? IconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white70),
                              onPressed: controller.skipToNextTrack,
                            )
                          : null,
                      onTap: () {
                        Get.back();
                        controller.toggleMusic();
                      },
                      onLongPress: isHost
                          ? () {
                              Get.back();
                              _showRemoveMusicDialog(controller);
                            }
                          : null,
                    )
                  : const SizedBox.shrink()),
              if (isHost)
                ListTile(
                  leading: const Icon(Icons.celebration, color: ColorRes.primaryColor),
                  title: const Text('Fun Centre', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    _showFunCentreSheet(controller);
                  },
                ),
              if (isHost)
                ListTile(
                  leading: const Icon(Icons.palette, color: ColorRes.primaryColor),
                  title: const Text('Background', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    _showThemesSheet(controller);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.call_end, color: ColorRes.liveRed),
                title: Text(isHost ? 'End Room' : 'Leave Room',
                    style: const TextStyle(color: ColorRes.liveRed)),
                onTap: () {
                  Get.back();
                  if (isHost) {
                    controller.endRoom();
                  } else {
                    controller.leaveRoom();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestsSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.5,
        ),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Speaker Requests',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Flexible(
              child: Obx(() {
                if (controller.requestIds.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No pending requests',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.requestIds.length,
                  itemBuilder: (context, index) {
                    final userId = controller.requestIds[index];
                    final participant = controller.participants
                        .where((p) => p.userId == userId)
                        .firstOrNull;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CustomImage(
                            size: const Size(40, 40),
                            image: participant?.profilePhoto,
                            radius: 20,
                            fullName: participant?.fullname,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              participant?.fullname ?? 'User $userId',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.acceptSpeaker(userId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: ColorRes.primaryColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Accept',
                                  style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => controller.rejectSpeaker(userId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Reject',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            // Active speakers section
            Obx(() {
              if (controller.speakerIds.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Active Speakers',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...controller.speakerIds.map((userId) {
                    final participant = controller.participants
                        .where((p) => p.userId == userId)
                        .firstOrNull;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: ColorRes.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: ColorRes.primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              participant?.fullname ?? 'User $userId',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.revokeSpeaker(userId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Revoke',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showFunCentreSheet(AudioRoomController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Fun Centre',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.music_note, color: ColorRes.primaryColor),
                title:
                    const Text('My Music', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Change the room\'s background music',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Get.back();
                  controller.changeMusic();
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard, color: ColorRes.primaryColor),
                title: const Text('Favourite Gift',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Highlight one gift to your viewers',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Get.back();
                  _showFavouriteGiftSheet(controller);
                },
              ),
              Obx(() => ListTile(
                    leading: const Icon(Icons.workspace_premium,
                        color: ColorRes.gold),
                    title: const Text('Royal Mode',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        'Show a gold crown badge on your room',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: Switch(
                      value: controller.isRoyalMode.value,
                      onChanged: (_) => controller.toggleRoyalMode(),
                      activeColor: ColorRes.gold,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryGiftsSheet(AudioRoomController controller) {
    if (isHost) {
      showSnackBar('Hosts cannot send gifts to themselves');
      return;
    }
    controller.fetchDiamondBalanceIfNeeded(force: true);
    Get.bottomSheet(
      _AudioRoomGiftCategorySheet(controller: controller, room: room),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  void _showFavouriteGiftSheet(AudioRoomController controller) {
    final initialGifts = controller.availableGifts.isNotEmpty
        ? controller.availableGifts
        : (SessionManager.instance.getSettings()?.availableGifts ?? []);

    final Rx<Gift?> selectedGift = Rx<Gift?>(null);
    final currentFavId = controller.favouriteGiftId.value;
    if (currentFavId != null) {
      selectedGift.value =
          initialGifts.firstWhereOrNull((g) => g.id == currentFavId);
    }
    selectedGift.value ??= initialGifts.isNotEmpty ? initialGifts.first : null;

    if (controller.availableGifts.isEmpty) {
      CommonService.instance.fetchGlobalSettings().then((_) {
        final fresh = SessionManager.instance.getSettings();
        if (fresh != null && fresh.availableGifts.isNotEmpty) {
          controller.availableGifts.value = fresh.availableGifts;
          if (selectedGift.value == null &&
              controller.availableGifts.isNotEmpty) {
            selectedGift.value = controller.availableGifts.first;
          }
        }
      });
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Favourite Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white70, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'This will be shown to viewers, which will help you get more gifts',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Obx(() {
              final gifts = controller.availableGifts.isNotEmpty
                  ? controller.availableGifts
                  : (SessionManager.instance.getSettings()?.availableGifts ?? []);

              if (gifts.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorRes.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              if (selectedGift.value == null && gifts.isNotEmpty) {
                final favId = controller.favouriteGiftId.value;
                selectedGift.value =
                    gifts.firstWhereOrNull((g) => g.id == favId) ?? gifts.first;
              }

              return SizedBox(
                height: 102,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: gifts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final gift = gifts[index];
                    return Obx(() {
                      final isSelected = selectedGift.value?.id != null &&
                          selectedGift.value?.id == gift.id;

                      String? badgeText;
                      if (gift.categoryName != null &&
                          gift.categoryName!.isNotEmpty) {
                        badgeText = gift.categoryName;
                      } else if (gift.createdAt != null &&
                          DateTime.now().difference(gift.createdAt!).inDays <= 7) {
                        badgeText = 'New';
                      }

                      return GestureDetector(
                        onTap: () => selectedGift.value = gift,
                        child: Container(
                          width: 76,
                          height: 102,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2E221B)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFFFF7A19), width: 2)
                                : Border.all(
                                    color: Colors.transparent, width: 2),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    height: 16,
                                    child: badgeText != null
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: badgeText
                                                      .toLowerCase()
                                                      .contains('love')
                                                  ? const Color(0xFFE91E63)
                                                  : const Color(0xFFFFB300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: CustomImage(
                                        image: gift.image?.addBaseURL(),
                                        size: const Size(50, 50),
                                        fit: BoxFit.contain,
                                        radius: 4,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.diamond,
                                          color: Colors.white, size: 12),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${gift.coinPrice ?? 0}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (selectedGift.value != null) {
                    controller.setFavouriteGift(selectedGift.value!);
                    Get.back();
                  }
                },
                child: const Text(
                  'Set Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () {
                  controller.removeFavouriteGift();
                  Get.back();
                },
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Remove Favourite Gift',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showRemoveMusicDialog(AudioRoomController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorRes.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Music',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Do you want to remove the background music?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.removeMusic();
            },
            child: const Text('Remove',
                style: TextStyle(color: ColorRes.liveRed)),
          ),
        ],
      ),
    );
  }

}

/// Real follow toggle for the audio room header — fetches the host's
/// current follow state once, then uses the same FollowController path
/// the rest of the app uses, so it never drifts from the real state.
class _AudioFollowButton extends StatefulWidget {
  final int? hostId;

  const _AudioFollowButton({required this.hostId});

  @override
  State<_AudioFollowButton> createState() => _AudioFollowButtonState();
}

class _AudioFollowButtonState extends State<_AudioFollowButton> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.hostId == null) return;
    final user = await UserService.instance.fetchUserDetails(userId: widget.hostId);
    if (mounted) setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    if (_user?.id == null) return;
    final userId = _user!.id!;
    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: 'audio_$userId')) {
      followController = Get.find<FollowController>(tag: 'audio_$userId');
      followController.updateUser(_user);
    } else {
      followController = Get.put(FollowController(_user.obs), tag: 'audio_$userId');
    }
    final updated = await followController.followUnFollowUser();
    if (mounted && updated != null) setState(() => _user = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || widget.hostId == SessionManager.instance.getUserID()) {
      return const SizedBox.shrink();
    }
    final isFollowing = _user?.isFollowing ?? false;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          gradient: isFollowing
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFFF5200)],
                ),
          color: isFollowing ? Colors.white.withValues(alpha: 0.15) : null,
          border: isFollowing ? Border.all(color: Colors.white24) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isFollowing ? 'Following' : '+ Follow',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AudioWaveVisualizer extends StatefulWidget {
  const _AudioWaveVisualizer();

  @override
  State<_AudioWaveVisualizer> createState() => _AudioWaveVisualizerState();
}

class _AudioWaveVisualizerState extends State<_AudioWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (index) {
            final phase = index * (math.pi / 3);
            final wave = (math.sin(t + phase).abs() * 0.7) + 0.3;
            final height = 8.0 + (wave * 16.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace ||
      radius != oldDelegate.radius;
}

class _AudioTimer extends StatefulWidget {
  final int? createdAt;

  const _AudioTimer({required this.createdAt});

  @override
  State<_AudioTimer> createState() => _AudioTimerState();
}

class _AudioTimerState extends State<_AudioTimer> {
  late final Stream<int> _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);

  String _formatElapsed() {
    final startedAt = widget.createdAt;
    if (startedAt == null) return '00:00:00';
    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startedAt));
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, snapshot) =>
          Text(_formatElapsed(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

class _AudioRoomGiftCategorySheet extends StatefulWidget {
  final AudioRoomController controller;
  final AudioRoom room;

  const _AudioRoomGiftCategorySheet({
    required this.controller,
    required this.room,
  });

  @override
  State<_AudioRoomGiftCategorySheet> createState() =>
      _AudioRoomGiftCategorySheetState();
}

class _AudioRoomGiftCategorySheetState
    extends State<_AudioRoomGiftCategorySheet> {
  String _selectedCategory = 'All';

  List<String> _extractCategories(List<Gift> gifts) {
    final categories = <String>['All'];

    // 1. From settings.giftCategories
    final adminCats =
        SessionManager.instance.getSettings()?.giftCategories ?? [];
    for (final c in adminCats) {
      final name = c.name?.trim();
      if (name != null && name.isNotEmpty && !categories.contains(name)) {
        categories.add(name);
      }
    }

    // 2. From gift objects (categoryName from tbl_gift_categories join)
    for (final g in gifts) {
      final name = g.categoryName?.trim();
      if (name != null && name.isNotEmpty && !categories.contains(name)) {
        categories.add(name);
      }
    }

    // 3. Guarantee the admin categories requested: Food, Gold, Farms
    for (final fallback in ['Food', 'Gold', 'Farms']) {
      if (!categories.contains(fallback)) {
        categories.add(fallback);
      }
    }

    return categories;
  }

  bool _giftMatchesCategory(Gift gift, String category) {
    if (category == 'All') return true;

    final target = category.toLowerCase().trim();
    final catName = (gift.categoryName ?? '').toLowerCase().trim();
    if (catName.isNotEmpty && catName == target) return true;

    final title = (gift.title ?? gift.displayName).toLowerCase().trim();
    if (title.contains(target)) return true;

    if (target == 'food') {
      return title.contains('food') ||
          title.contains('samosa') ||
          title.contains('chai') ||
          title.contains('tea') ||
          title.contains('coffee') ||
          title.contains('burger') ||
          title.contains('pizza') ||
          title.contains('cake') ||
          title.contains('chocolate') ||
          title.contains('meal') ||
          title.contains('drink') ||
          title.contains('candy') ||
          title.contains('fruit') ||
          title.contains('apple') ||
          title.contains('ice cream');
    } else if (target == 'gold') {
      return title.contains('gold') ||
          title.contains('coin') ||
          title.contains('crown') ||
          title.contains('ferrari') ||
          title.contains('car') ||
          title.contains('diamond') ||
          title.contains('luxury') ||
          title.contains('palace') ||
          title.contains('castle') ||
          title.contains('ring') ||
          title.contains('watch') ||
          title.contains('trophy');
    } else if (target == 'farms') {
      return title.contains('farm') ||
          title.contains('rose') ||
          title.contains('flower') ||
          title.contains('tree') ||
          title.contains('plant') ||
          title.contains('horse') ||
          title.contains('cow') ||
          title.contains('sheep') ||
          title.contains('hen') ||
          title.contains('bird') ||
          title.contains('grass') ||
          title.contains('animal');
    }

    return false;
  }

  List<Gift> _filterGifts(List<Gift> gifts) {
    if (_selectedCategory == 'All') return gifts;
    return gifts.where((g) => _giftMatchesCategory(g, _selectedCategory)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allGifts = widget.controller.availableGifts.isNotEmpty
          ? widget.controller.availableGifts
          : (SessionManager.instance.getSettings()?.availableGifts ?? []);

      final bool isLocked = widget.controller.isGiftAnimating.value ||
          widget.controller.activeGifts.isNotEmpty;

      final categories = _extractCategories(allGifts);
      final filteredGifts = _filterGifts(allGifts);

      return Container(
        height: Get.height * 0.56,
        decoration: BoxDecoration(
          color: const Color(0xFF10131B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag indicator bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Top Bar: "Send Gifts" | Diamond Balance | "Recharge >"
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Send Gifts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    // Diamond Balance
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.controller.diamondBalance.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.diamond_rounded,
                          color: Color(0xFFBA68C8),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Recharge > button
                    InkWell(
                      onTap: () async {
                        await Get.to(() => StarStoreDiamondScreen(
                              onPurchaseCompleted: () {
                                Get.back(); // return directly back to audio room
                                widget.controller.fetchDiamondBalance();
                              },
                            ));
                        widget.controller.fetchDiamondBalance();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D87), Color(0xFFE040FB)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D87).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Recharge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Category Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF2D87), Color(0xFFE040FB)],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF2D87)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Gifts Grid
              Expanded(
                child: IgnorePointer(
                  ignoring: isLocked,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLocked ? 0.45 : 1.0,
                    child: filteredGifts.isEmpty
                        ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard_rounded,
                                color: Colors.white24, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'No gifts in $_selectedCategory',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredGifts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final gift = filteredGifts[index];
                          final price = gift.coinPrice ?? 0;
                          String priceStr = price >= 1000
                              ? '${(price / 1000).toStringAsFixed(1)}K'
                              : '$price';

                          String? badgeText;
                          Color badgeColor = const Color(0xFFE91E63);
                          final dName = gift.displayName.toLowerCase();
                          if (dName.contains('love') ||
                              dName.contains('heart') ||
                              (gift.categoryName
                                      ?.toLowerCase()
                                      .contains('love') ==
                                  true)) {
                            badgeText = 'Love';
                            badgeColor = const Color(0xFFE91E63);
                          } else if (dName.contains('new') ||
                              (gift.createdAt != null &&
                                  DateTime.now()
                                          .difference(gift.createdAt!)
                                          .inDays <=
                                      7)) {
                            badgeText = 'New';
                            badgeColor = const Color(0xFF00E676);
                          }

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isLocked
                                ? null
                                : () => widget.controller.sendGiftDirect(gift),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Top Badge
                                  SizedBox(
                                    height: 14,
                                    child: badgeText != null
                                        ? Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  const SizedBox(height: 2),
                                  // Gift Image
                                  Expanded(
                                    child: Center(
                                      child: CustomImage(
                                        size: const Size(46, 46),
                                        image: gift.image?.addBaseURL(),
                                        fit: BoxFit.contain,
                                        radius: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Gift Name
                                  Text(
                                    gift.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Diamond Price (Number followed by Purple Diamond)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        priceStr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.diamond_rounded,
                                        color: Color(0xFFBA68C8),
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

