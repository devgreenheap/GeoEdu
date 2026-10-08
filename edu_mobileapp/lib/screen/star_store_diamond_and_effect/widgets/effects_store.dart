import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/screen/effect_preview/effect_preview_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/Effectstoggle.dart';
import 'package:get/get.dart';

import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/buy_effect_confirmation_dialog.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../../model/star_store/effects_model.dart';

class EffectsStoreScreen extends StatefulWidget {
  final VoidCallback? onSwitchToDiamondStore;

  const EffectsStoreScreen({super.key, this.onSwitchToDiamondStore});

  @override
  State<EffectsStoreScreen> createState() => _EffectsStoreScreenState();
}

class _EffectsStoreScreenState extends State<EffectsStoreScreen> {
  List<EntryEffectModel> entryEffects = [];
  List<EntryEffectModel> myEffects = [];
  bool isLoading = true;
  bool isMyEffectsLoading = false;
  int selectedTab = 0;
  int diamondBalance = 0;

  @override
  void initState() {
    super.initState();
    fetchEntryEffects();
    fetchDiamondWallet();
  }

  Future<void> fetchDiamondWallet() async {
    try {
      final result = await GiftWalletService.instance.fetchMyDiamondWallet();
      if (result.data != null && mounted) {
        setState(() {
          diamondBalance = result.data!.diamondBalance ?? 0;
        });
      }
    } catch (e) {
      Loggers.error('fetchDiamondWallet error: $e');
    }
  }

  Future<void> fetchEntryEffects() async {
    try {
      final result = await GiftWalletService.instance.fetchEntryEffects();
      setState(() {
        entryEffects = result;
        isLoading = false;
      });
    } catch (e) {
      Loggers.error('fetchEntryEffects error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMyEntryEffects() async {
    setState(() => isMyEffectsLoading = true);
    try {
      final result = await GiftWalletService.instance.fetchMyEntryEffects();
      setState(() {
        myEffects = result;
        isMyEffectsLoading = false;
      });
    } catch (e) {
      Loggers.error('fetchMyEntryEffects error: $e');
      setState(() {
        isMyEffectsLoading = false;
      });
    }
  }

  /// Opens the attractive confirmation popup before purchasing.
  void _showPurchaseConfirmation(EntryEffectModel effect) async {
    if (diamondBalance == 0) {
      await fetchDiamondWallet();
    }
    if (!mounted) return;

    BuyEffectConfirmationDialog.show(
      context: context,
      effect: effect,
      currentBalance: diamondBalance,
      onTopUpDiamonds: widget.onSwitchToDiamondStore,
      onConfirmPurchase: () => _executePurchase(effect),
    );
  }

  Future<bool> _executePurchase(EntryEffectModel effect) async {
    if (effect.id == null) return false;
    try {
      final result = await GiftWalletService.instance.buyEntryEffect(
        entryEffectId: effect.id!,
        diamonds: effect.currentPrice,
      );
      if (result.status == true) {
        // 1. Immediately deduct diamonds locally
        setState(() {
          diamondBalance =
              (diamondBalance - effect.currentPrice).clamp(0, 999999999);
        });

        // 2. Refresh server wallet & purchased effects in background
        fetchDiamondWallet();
        fetchMyEntryEffects();

        // 3. Extract duration text
        String durationText = effect.duration.trim();
        if (durationText.isEmpty) {
          durationText =
              effect.durationHours != null && effect.durationHours! > 0
                  ? '${effect.durationHours} hours'
                  : '24 hours';
        } else if (!durationText.toLowerCase().contains('hour') &&
            !durationText.toLowerCase().contains('day')) {
          durationText = '$durationText hours';
        }

        // 4. Show clear celebration popup
        if (!mounted) return true;
        PurchaseEffectSuccessDialog.show(
          context: context,
          effectName: effect.title,
          durationText: durationText,
          updatedBalance: diamondBalance,
          onViewMyEffects: () {
            _onTabChanged(1); // Switch to "My Effects" tab
          },
        );

        return true;
      } else {
        Get.snackbar(
          'Purchase Failed',
          result.message ?? 'Something went wrong',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Loggers.error('buyEntryEffect error: $e');
      Get.snackbar(
        'Error',
        'Failed to purchase effect',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      selectedTab = index;
    });
    if (index == 1 && myEffects.isEmpty) {
      fetchMyEntryEffects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EffectsToggle(selectedIndex: selectedTab, onChanged: _onTabChanged),
        const SizedBox(height: 16),
        if (selectedTab == 0)
          _buildBuyEffects()
        else
          _buildMyEffects(),
      ],
    );
  }

  Widget _buildBuyEffects() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: ColorRes.gold),
        ),
      );
    }
    if (entryEffects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No effects available", style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBalanceBar(),
        const SizedBox(height: 12),
        _buildEffectsGrid(entryEffects, showBuyButton: true),
      ],
    );
  }

  Widget _buildBalanceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141916),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AssetRes.coinIcon, width: 18, height: 18),
              const SizedBox(width: 8),
              const Text(
                'Diamond Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$diamondBalance',
                style: const TextStyle(
                  color: ColorRes.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onSwitchToDiamondStore != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onSwitchToDiamondStore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFE6A800)],
                      ),
                    ),
                    child: const Text(
                      '+ Top Up',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyEffects() {
    if (isMyEffectsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: ColorRes.gold),
        ),
      );
    }
    if (myEffects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.auto_awesome, color: ColorRes.gold, size: 48),
              SizedBox(height: 12),
              Text(
                "No purchased effects yet",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "Buy an effect to make a stunning entrance!",
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return _buildEffectsGrid(myEffects, showBuyButton: false);
  }

  Widget _buildEffectsGrid(List<EntryEffectModel> effects, {required bool showBuyButton}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: effects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final effect = effects[index];
        return _EffectCard(
          effect: effect,
          showBuyButton: showBuyButton,
          onBuy: () => _showPurchaseConfirmation(effect),
        );
      },
    );
  }
}

// ─── Premium Effect Card ─────────────────────────────────────────────────────

class _EffectCard extends StatelessWidget {
  final EntryEffectModel effect;
  final bool showBuyButton;
  final VoidCallback onBuy;

  const _EffectCard({
    required this.effect,
    required this.showBuyButton,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outer glow border (green neon)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1DB954), Color(0xFFB8860B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1DB954).withOpacity(0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF0E1210),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Preview area ──────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: effect.image.isNotEmpty
                        ? () => Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: false,
                                barrierColor: Colors.black.withOpacity(.70),
                                pageBuilder: (context, animation, secondaryAnimation) {
                                  return EffectPreviewScreen(
                                    effectName: effect.title,
                                    assetUrl: effect.image,
                                    audio: effect.audio,
                                    isDefault: effect.isDefaultAudio,
                                  );
                                },
                              ),
                            )
                        : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Effect flash background image
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: Image.asset(
                              AssetRes.effectFlash,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Play button overlay
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Info + Buy area ───────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Effect name
                      if (effect.title.isNotEmpty)
                        Text(
                          effect.title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 5),

                      // Price row: 🔴 100  (strikethrough original)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Red diamond icon (coin)
                          Image.asset(AssetRes.coinIcon, width: 18, height: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${effect.currentPrice}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorRes.gold,
                            ),
                          ),
                          if (effect.originalPrice > effect.currentPrice) ...[
                            const SizedBox(width: 5),
                            Text(
                              '${effect.originalPrice}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Duration
                      if (effect.duration.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          effect.duration,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Buy button (full width, gold)
                      if (showBuyButton)
                        GestureDetector(
                          onTap: onBuy,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFE6A800)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Buy  ›',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                      else
                        // "My Effects" — show active badge or time remaining
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1DB954),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            effect.isExpired
                                ? 'Expired'
                                : (effect.expiresAt != null
                                    ? effect.remainingTimeDisplay
                                    : 'Active'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: effect.isExpired
                                  ? Colors.white38
                                  : const Color(0xFF1DB954),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Discount badge (top-right)
        if (showBuyButton && effect.discountPercent > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: ColorRes.likeRed,
              ),
              child: Text(
                '${effect.discountPercent}% off',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── SVGA preview widget (unchanged) ─────────────────────────────────────────

class SvgaPreview extends StatefulWidget {
  final String assetPath;
  final bool isNetwork;

  const SvgaPreview({super.key, required this.assetPath, this.isNetwork = false});

  @override
  State<SvgaPreview> createState() => _SvgaPreviewState();
}

class _SvgaPreviewState extends State<SvgaPreview> with TickerProviderStateMixin {
  late SVGAAnimationController _controller;
  final SVGAParser _parser = SVGAParser.shared;

  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    try {
      final videoItem = widget.isNetwork
          ? await _parser.decodeFromURL(widget.assetPath)
          : await _parser.decodeFromAssets(widget.assetPath);

      if (!mounted) return;
      videoItem.audios.clear();

      _controller.videoItem = videoItem;
      _controller.repeat();
    } catch (e) {
      Loggers.error('SVGA load error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SVGAImage(
        _controller,
        fit: BoxFit.contain,
        clearsAfterStop: true,
        allowDrawingOverflow: false,
      ),
    );
  }
}
