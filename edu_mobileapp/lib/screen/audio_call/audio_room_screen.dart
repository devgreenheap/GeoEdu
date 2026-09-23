import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/level_badge.dart';
import 'package:geoedu/model/audio_call/audio_comment.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/audio_call/online_user.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/entry_effects_widget.dart'
    show GiftEffectWidget;
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_like_button.dart';
import 'package:geoedu/screen/diamond_purchase/diamond_purchase_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/audio_theme_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';

class AudioRoomScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = Get.put(
      AudioRoomController(room: room, isHost: isHost),
    );
    controller.onPkInviteReceived = (inviterHostId) =>
        _showPkInviteDialog(controller, inviterHostId);

    return Scaffold(
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
                        Colors.black.withOpacity(0.4), BlendMode.darken),
                  )
                : null,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(controller),
                Obx(() => controller.pkStatus.value == 'running'
                    ? _buildPkBattleBar(controller)
                    : const SizedBox.shrink()),
                const SizedBox(height: 10),
                // Host avatar
                _buildHostAvatar(controller),
                const SizedBox(height: 8),
                // Room name
                Obx(() => Text(
                      controller.roomName.value,
                      style: const TextStyle(
                        color: ColorRes.whitePure,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(height: 10),
                SizedBox(height: 136, child: _buildSeatGrid(controller)),
                Obx(() => controller.pinnedComment.value.isNotEmpty
                    ? _buildPinnedCommentBanner(controller)
                    : const SizedBox.shrink()),
                if (isHost) _buildPinCommentInput(controller),
                Expanded(child: _buildChatList(controller)),
                if (!isHost)
                  Obx(() => controller.isGiftBarOpen.value
                      ? _buildInlineGiftBar(controller)
                      : const SizedBox.shrink()),
                _buildChatInput(controller),
                _buildBottomRow(controller),
              ],
            ),
          ),
        );
          }),
          GiftEffectWidget(activeGifts: controller.activeGifts),
        ],
      ),
    );
  }

  Widget _buildHeader(AudioRoomController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomImage(
                          size: const Size(30, 30),
                          image: room.hostPhoto,
                          fullName: room.hostName,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(room.hostName ?? 'Host',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                        if (!isHost) ...[
                          const SizedBox(width: 6),
                          _AudioFollowButton(hostId: room.hostId),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _headerPill(children: [
                            const Text('🎁', style: TextStyle(fontSize: 11)),
                            Obx(() => Text(' ${controller.hostGiftCount.value}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                            const SizedBox(width: 6),
                            const Text('⭐', style: TextStyle(fontSize: 11)),
                            Obx(() => Text(' ${controller.hostStarTotal.value}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(width: 6),
                          if (isHost)
                            GestureDetector(
                              onTap: () => _showSetTargetDialog(controller),
                              child: Obx(() => _headerPill(children: [
                                    const Text('💎', style: TextStyle(fontSize: 11)),
                                    Text(
                                        controller.targetDiamonds.value > 0
                                            ? ' ${controller.hostStarTotal.value}/${controller.targetDiamonds.value}'
                                            : ' Target',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.edit, color: Colors.white70, size: 11),
                                  ])),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => Get.to(() => const DiamondPurchaseScreen())
                            ?.then((_) => controller.fetchDiamondBalanceIfNeeded(force: true)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(AssetRes.editDiamond, height: 12, width: 12),
                              const SizedBox(width: 4),
                              Obx(() => Text(
                                    '${controller.diamondBalance.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: ColorRes.liveRed, borderRadius: BorderRadius.circular(6)),
                        child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: 14),
                      Obx(() => Text(' ${controller.participantIds.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11))),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (isHost) {
                            controller.endRoom();
                          } else {
                            controller.leaveRoom();
                          }
                        },
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _AudioTimer(createdAt: room.createdAt),
                ],
              ),
            ],
          ),
          if (isHost) ...[
            const SizedBox(height: 8),
            _buildPromoGiftCard(controller),
          ],
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
      onTap: controller.openGiftBar,
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

  Widget _buildHostAvatar(AudioRoomController controller) {
    return Obx(() {
      final bool royal = controller.isRoyalMode.value;
      final Color accent = royal ? ColorRes.gold : ColorRes.primaryColor;
      return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 4,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.8),
                width: 4,
              ),
            ),
            child: CustomImage(
              size: const Size(72, 72),
              image: room.hostPhoto,
              radius: 36,
              fullName: room.hostName,
            ),
          ),
        ),
        if (royal)
          const Positioned(
            top: -8,
            child: Icon(Icons.workspace_premium,
                color: ColorRes.gold, size: 22),
          ),
      ],
    );
    });
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
    return Obx(() => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          reverse: true,
          itemCount: controller.comments.length,
          itemBuilder: (context, index) {
            final comment = controller.comments[controller.comments.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImage(
                    size: const Size(26, 26),
                    image: comment.senderPhoto?.addBaseURL(),
                    fullName: comment.senderName,
                    radius: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _buildCommentContent(controller, comment)),
                ],
              ),
            );
          },
        ));
  }

  Widget _buildCommentContent(AudioRoomController controller, AudioComment comment) {
    Widget nameRow(Widget trailing) => Row(
          children: [
            Flexible(
              child: Text(comment.senderName,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow(const SizedBox.shrink()),
            Text(comment.text ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        );
    }
  }

  Widget _buildChatInput(AudioRoomController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
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
                      controller: controller.textCommentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      onSubmitted: (_) => controller.sendTextComment(),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Write here..',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.sendTextComment,
                    child: const Icon(Icons.send_rounded, color: ColorRes.primaryColor, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.7,
            child: LiveStreamLikeButton(
              onLikeTap: (fn) => controller.onLikeTap = fn,
              onTap: controller.onLikeButtonTap,
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: count > 0
                  ? ColorRes.primaryColor
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.record_voice_over, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  count > 0 ? 'Requests ($count)' : 'Speaker Requests',
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
      });
    } else {
      return Obx(() {
        if (controller.isSpeaker.value) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: ColorRes.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, color: ColorRes.primaryColor, size: 18),
                SizedBox(width: 8),
                Text(
                  'You are a speaker',
                  style: TextStyle(
                    color: ColorRes.primaryColor,
                    fontSize: 13,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: controller.hasRequested.value
                  ? Colors.orange
                  : ColorRes.surfaceBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.hasRequested.value ? Icons.hourglass_top : Icons.front_hand,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.hasRequested.value ? 'Request Pending...' : 'Request to Speak',
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
      });
    }
  }

  Widget _buildInlineGiftBar(AudioRoomController controller) {
    return Obx(() {
      final Setting? setting = SessionManager.instance.getSettings();
      final List<Gift> allGifts = setting.allGiftsWithPen;
      final List<Gift> gifts = List<Gift>.from(allGifts);
      final favouriteId = controller.favouriteGiftId.value;
      if (favouriteId != null) {
        gifts.sort((a, b) => (a.id == favouriteId ? 0 : 1)
            .compareTo(b.id == favouriteId ? 0 : 1));
      }
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: ColorRes.cardBackground.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Send a gift to ${room.hostName ?? "host"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('${controller.diamondBalance.value}',
                    style: const TextStyle(
                        color: ColorRes.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.diamond, color: ColorRes.primaryColor, size: 14),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => controller.isGiftBarOpen.value = false,
                  child: const Icon(Icons.close, size: 18, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 94,
              child: gifts.isEmpty
                  ? const Center(
                      child: Text('No gifts available',
                          style: TextStyle(color: Colors.white38, fontSize: 12)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: gifts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final gift = gifts[index];
                        final isFavourite = gift.id != null &&
                            gift.id == controller.favouriteGiftId.value;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.sendGiftDirect(gift),
                          child: Container(
                            width: 66,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CustomImage(
                                      image: gift.image?.addBaseURL(),
                                      size: const Size(38, 38),
                                      radius: 6,
                                    ),
                                    if (isFavourite)
                                      const Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Icon(Icons.star,
                                            size: 14, color: ColorRes.gold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  gift.displayName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${gift.coinPrice ?? 0} Diamonds',
                                  style: const TextStyle(
                                      color: ColorRes.primaryColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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

  Widget _buildBottomRow(AudioRoomController controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildRequestButton(controller),
                if (isHost)
                  Obx(() => controller.pkStatus.value == 'running'
                      ? const SizedBox.shrink()
                      : _pillButton(
                          icon: Icons.bolt,
                          label: 'PK Battle',
                          color: ColorRes.primaryColor,
                          onTap: () => _showPkInviteListSheet(controller),
                        )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildRightIconColumn(controller),
        ],
      ),
    );
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
        if (isHost)
          _sideIcon(
              icon: Icons.call,
              label: 'Calls',
              onTap: () => _showRequestsSheet(controller))
        else
          _sideIcon(
              icon: Icons.card_giftcard,
              label: 'Gift',
              onTap: controller.openGiftBar),
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
    Share.share(
      'Join ${room.hostName ?? "my"} audio room "${controller.roomName.value}" live on GeoEdu now!',
      subject: 'Join this audio room',
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

  void _showFavouriteGiftSheet(AudioRoomController controller) {
    final Setting? setting = SessionManager.instance.getSettings();
    final List<Gift> gifts = setting.allGiftsWithPen;
    Get.bottomSheet(
      Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(Get.context!).size.height * 0.55),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Favourite Gift',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
                'This will be shown to viewers, which will help you get more gifts',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            Flexible(
              child: gifts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No gifts available',
                          style: TextStyle(color: Colors.white38)),
                    )
                  : Obx(() => GridView.builder(
                        shrinkWrap: true,
                        itemCount: gifts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.72),
                        itemBuilder: (context, index) {
                          final gift = gifts[index];
                          final isFavourite = gift.id != null &&
                              gift.id == controller.favouriteGiftId.value;
                          return GestureDetector(
                            onTap: () {
                              controller.setFavouriteGift(gift);
                              Get.back();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withValues(alpha: 0.05),
                                border: isFavourite
                                    ? Border.all(color: ColorRes.gold, width: 2)
                                    : null,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomImage(
                                    image: gift.image?.addBaseURL(),
                                    size: const Size(40, 40),
                                    radius: 6,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gift.displayName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${gift.coinPrice ?? 0} Diamonds',
                                    style: const TextStyle(
                                        color: ColorRes.primaryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : Colors.white,
          border: isFollowing ? Border.all(color: Colors.white54) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(isFollowing ? 'Following' : '+ Follow',
            style: TextStyle(fontSize: 11, color: isFollowing ? Colors.white : Colors.black)),
      ),
    );
  }
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
