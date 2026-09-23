import 'dart:async';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/service/network_helper/network_helper.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/level_badge.dart';
import 'package:geoedu/common/widget/text_button_custom.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/gift_sheet/send_gift_sheet.dart' show GiftType;
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class LiveStreamHostTopView extends StatelessWidget {
  final LivestreamScreenController controller;

  const LiveStreamHostTopView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        Livestream stream = controller.liveData.value;
        bool isVisible = controller.isViewVisible.value;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: isVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _HostInfoBlock(controller: controller)),
                      _TopRightBlock(controller: controller, stream: stream),
                    ],
                  ),
                  if (controller.isHost) ...[
                    const SizedBox(height: 8),
                    _PromoGiftCard(controller: controller),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Top-left: host avatar/name/level, 🎁/⭐ pill, 💎 Target pill.
class _HostInfoBlock extends StatelessWidget {
  final LivestreamScreenController controller;

  const _HostInfoBlock({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hostUser = controller.liveData.value.hostUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomImage(
              size: const Size(34, 34),
              image: hostUser?.profile?.addBaseURL(),
              fullName: hostUser?.fullname,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(hostUser?.fullname ?? hostUser?.username ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            if ((hostUser?.level ?? 0) > 0) ...[
              const SizedBox(width: 4),
              LevelBadge(level: hostUser?.level, navigateOnTap: false),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Pill(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 11)),
                Text(' ${controller.hostGiftCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                const Text('⭐', style: TextStyle(fontSize: 11)),
                Text(' ${(controller.hostUserState?.totalCoin ?? 0).numberFormat}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 6),
            if (controller.isHost)
              GestureDetector(
                onTap: () => _showSetTargetDialog(context),
                child: _Pill(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 11)),
                    Text(
                        controller.targetDiamonds.value > 0
                            ? ' ${(controller.hostUserState?.totalCoin ?? 0).numberFormat}/${controller.targetDiamonds.value.numberFormat}'
                            : ' Target',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    const Icon(Icons.edit, color: Colors.white70, size: 11),
                  ],
                ),
              ),
          ],
        ),
        if (controller.targetDiamonds.value > 0) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 120,
              height: 4,
              child: LinearProgressIndicator(
                value: controller.targetProgress,
                backgroundColor: Colors.white24,
                color: ColorRes.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showSetTargetDialog(BuildContext context) {
    final textController = TextEditingController(
        text: controller.targetDiamonds.value > 0
            ? controller.targetDiamonds.value.toString()
            : '');
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
              final value = int.tryParse(textController.text.trim()) ?? 0;
              controller.setTargetDiamonds(value);
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Small dark rounded pill used for the stat rows in the top-left block.
class _Pill extends StatelessWidget {
  final List<Widget> children;

  const _Pill({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Promo gift card — the real, highest-priced gift from the catalog, tagged
/// "New" only when it was genuinely added recently.
class _PromoGiftCard extends StatelessWidget {
  final LivestreamScreenController controller;

  const _PromoGiftCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final gift = controller.featuredGift;
    if (gift == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => controller.onGiftTap(GiftType.livestream),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
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
            CustomImage(size: const Size(28, 28), image: gift.image?.addBaseURL(), fullName: gift.title, radius: 6),
            const SizedBox(width: 6),
            Image.asset(AssetRes.coinIcon, height: 14, width: 14),
            const SizedBox(width: 3),
            Text('${gift.coinPrice ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Top-right: LIVE badge, watching count, network status, timer, stop, new
/// followers this session.
class _TopRightBlock extends StatefulWidget {
  final LivestreamScreenController controller;
  final Livestream stream;

  const _TopRightBlock({required this.controller, required this.stream});

  @override
  State<_TopRightBlock> createState() => _TopRightBlockState();
}

class _TopRightBlockState extends State<_TopRightBlock> {
  late final Stream<int> _ticker;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectionSub;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
    _connectionSub = NetworkHelper().onConnectionChange.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final startedAt = widget.stream.createdAt;
    if (startedAt == null) return '00:00:00';
    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startedAt));
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    int count = widget.stream.watchingCount ?? 0;
    int watchingCount = count >= 0 ? count : 0;
    final newFollowers = controller.hostUserState?.followersGained.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: ColorRes.liveRed, borderRadius: BorderRadius.circular(6)),
              child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.remove_red_eye_rounded, color: Colors.white70, size: 13),
            Text(' ${watchingCount.numberFormat}', style: const TextStyle(color: Colors.white, fontSize: 11)),
            const SizedBox(width: 6),
            Icon(_isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: _isOnline ? Colors.white70 : ColorRes.liveRed, size: 15),
            const SizedBox(width: 6),
            if (controller.isHost)
              InkWell(
                onTap: controller.onStopButtonTap,
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 4),
        StreamBuilder<int>(
          stream: _ticker,
          builder: (context, snapshot) => Text(_formatElapsed(),
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()])),
        ),
        if (newFollowers > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20)),
            child: Text('👤+ $newFollowers', style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ],
    );
  }
}

class StopLiveStreamSheet extends StatelessWidget {
  final VoidCallback onTap;
  final String? title;
  final String? description;
  final String? positiveText;

  const StopLiveStreamSheet(
      {super.key,
        required this.onTap,
        this.title,
        this.description,
        this.positiveText});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          width: double.infinity,
          decoration: const ShapeDecoration(
              gradient: LinearGradient(colors: [
                ColorRes.cardBackground,
                ColorRes.blackPure,
              ]),
              // color: whitePure(context),
              shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius.vertical(
                      top:
                      SmoothRadius(cornerRadius: 40, cornerSmoothing: 1)))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: .5,
                  color: textLightGrey(context),
                  width: 100,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                title ?? LKey.endStreamTitle.tr,
                style: TextStyleCustom.unboundedRegular400(
                    fontSize: 15, color: whitePure(context)),
              ),
              Text(
                description ?? LKey.endStreamMessage.tr,
                style: TextStyleCustom.outFitLight300(
                    fontSize: 17, color: whitePure(context)),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButtonCustom(
                        onTap: Get.back,
                        title: LKey.cancel.tr,
                        backgroundColor: bgMediumGrey(context)),
                  ),
                  Expanded(
                      child: TextButtonCustom(
                          onTap: () {
                            Get.back();
                            onTap();
                          },
                          title: positiveText ?? LKey.yes.tr,
                          backgroundColor: Colors.red,
                          titleColor: whitePure(context),
                          horizontalMargin: 5)),
                ],
              ),
              SizedBox(height: AppBar().preferredSize.height),
            ],
          ),
        )
      ],
    );
  }
}

class LiveStreamBorderButton extends StatelessWidget {
  final Color? backgroundColor;
  final String title;
  final String imageIcon;
  final Color? imageColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const LiveStreamBorderButton(
      {super.key,
        this.backgroundColor,
        required this.title,
        this.imageIcon = '',
        this.imageColor,
        this.onTap,
        this.shadow});

  @override
  Widget build(BuildContext context) {
    double width = Get.width / 5.5;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 22,
        width: width,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 30),
            side: BorderSide(
              color: whitePure(context).withValues(alpha: .6),
            ),
          ),
          shadows: shadow,
          color: backgroundColor ?? blackPure(context).withValues(alpha: .2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            if (imageIcon.isNotEmpty)
              Image.asset(imageIcon, height: 16, width: 16, color: imageColor),
            Text(title,
                style: TextStyleCustom.outFitRegular400(
                    color: whitePure(context))),
          ],
        ),
      ),
    );
  }
}

class LiveStreamCircleBorderButton extends StatelessWidget {
  final String image;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Size? size;
  final Color? iconColor;
  final Color? borderColor;
  final Color? bgColor;
  final double? iconSize;
  final bool? hastext;
  const LiveStreamCircleBorderButton({
    super.key,
    required this.image,
    this.margin,
    this.onTap,
    this.size,
    this.iconColor,
    this.borderColor,
    this.iconSize,
    this.bgColor,
    this.hastext = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticManager.shared.light();
        onTap?.call();
      },
      child: Container(
        height: size?.height ?? null,
        width: size?.width ?? null,
        margin: margin,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          // gradient: LinearGradient(colors: [
          //   Color(0xFF6F88E8),
          //   Color(0xFF273A57),
          // ]),
          shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(cornerRadius: 30),
              side: BorderSide(
                color: borderColor ?? whitePure(context).withValues(alpha: .3),
              )),
          color: (bgColor ?? blackPure(context)).withValues(alpha: .1),
        ),
        child: hastext == true ? Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                image,
                height: iconSize ?? 20,
                width: iconSize ?? 20,
                color: iconColor ?? whitePure(context).withValues(alpha: .3),
              ),
              Text("Members",style: TextStyle(color: ColorRes.whitePure,fontSize: 9),)
            ]
        ):  Image.asset(
          image,
          height: iconSize ?? 20,
          width: iconSize ?? 20,
          color: iconColor ?? whitePure(context).withValues(alpha: .3),
        ),
      ),
    );
  }
}

final livestreamShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: .15),
    offset: const Offset(0, 2),
    blurRadius: 5,
  ),
];
