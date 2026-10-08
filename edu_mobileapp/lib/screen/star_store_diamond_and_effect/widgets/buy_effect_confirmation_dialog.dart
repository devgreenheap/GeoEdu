import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/model/star_store/effects_model.dart';
import 'package:geoedu/screen/effect_preview/effect_preview_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Modern, premium confirmation popup for purchasing Entry Effects.
/// Prevents accidental purchases by showing full breakdown:
/// - ✨ Purchase Effect?
/// - Effect name & preview
/// - Effect duration (e.g. 24 hours)
/// - Required price (e.g. 💎 100 Diamonds)
/// - Current balance & remaining balance after purchase
/// - Explicit Cancel & Yes, Purchase buttons with validation
class BuyEffectConfirmationDialog extends StatefulWidget {
  final EntryEffectModel effect;
  final int currentBalance;
  final Future<bool> Function() onConfirmPurchase;
  final VoidCallback? onTopUpDiamonds;

  const BuyEffectConfirmationDialog({
    super.key,
    required this.effect,
    required this.currentBalance,
    required this.onConfirmPurchase,
    this.onTopUpDiamonds,
  });

  static Future<void> show({
    required BuildContext context,
    required EntryEffectModel effect,
    required int currentBalance,
    required Future<bool> Function() onConfirmPurchase,
    VoidCallback? onTopUpDiamonds,
  }) {
    return Get.dialog<void>(
      BuyEffectConfirmationDialog(
        effect: effect,
        currentBalance: currentBalance,
        onConfirmPurchase: onConfirmPurchase,
        onTopUpDiamonds: onTopUpDiamonds,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
    );
  }

  @override
  State<BuyEffectConfirmationDialog> createState() =>
      _BuyEffectConfirmationDialogState();
}

class _BuyEffectConfirmationDialogState
    extends State<BuyEffectConfirmationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _durationText {
    final d = widget.effect.duration.trim();
    if (d.isNotEmpty) {
      return d.toLowerCase().contains('hour') || d.toLowerCase().contains('day')
          ? d
          : '$d hours';
    }
    if (widget.effect.durationHours != null &&
        widget.effect.durationHours! > 0) {
      return '${widget.effect.durationHours} hours';
    }
    return '24 hours';
  }

  void _handleYesPurchase() async {
    if (_isLoading) return;

    final price = widget.effect.currentPrice;
    final balance = widget.currentBalance;

    // 1. Balance validation
    if (balance < price) {
      Get.back(); // close confirmation dialog
      InsufficientDiamondsDialog.show(
        context: context,
        requiredDiamonds: price,
        currentBalance: balance,
        effectName: widget.effect.title,
        onGetDiamonds: widget.onTopUpDiamonds,
      );
      return;
    }

    // 2. Perform purchase
    setState(() => _isLoading = true);
    final success = await widget.onConfirmPurchase();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Get.back(); // close confirmation dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;
    final price = effect.currentPrice;
    final balance = widget.currentBalance;
    final isSufficient = balance >= price;
    final remainingAfter = isSufficient ? balance - price : 0;
    final shortBy = isSufficient ? 0 : price - balance;

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1DB954),
                    Color(0xFFFFB300),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(1.5),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: const Color(0xFF0E1210),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header: ✨ Purchase Effect? + ✕ Close ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFD700),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Purchase Effect?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Get.back(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Center Effect Identity Preview Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C17),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Effect preview icon with play button
                          GestureDetector(
                            onTap: effect.image.isNotEmpty
                                ? () => Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierColor:
                                            Colors.black.withValues(alpha: 0.7),
                                        pageBuilder: (context, anim, secAnim) {
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
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1DB954),
                                    Color(0xFFB8860B)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(1.2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  color: const Color(0xFF0E1210),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.asset(
                                        AssetRes.effectFlash,
                                        fit: BoxFit.contain,
                                        width: 48,
                                        height: 48,
                                      ),
                                    ),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Colors.black.withValues(alpha: 0.6),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Name and Duration
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  effect.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1DB954)
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1DB954)
                                          .withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        color: Color(0xFF1DB954),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _durationText,
                                        style: const TextStyle(
                                          color: Color(0xFF1DB954),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Balance & Pricing Breakdown Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            label: 'Required Price',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AssetRes.coinIcon,
                                    width: 16, height: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$price Diamonds',
                                  style: const TextStyle(
                                    color: ColorRes.gold,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              color: Colors.white12,
                              height: 1,
                            ),
                          ),
                          _buildDetailRow(
                            label: 'Current Balance',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AssetRes.coinIcon,
                                    width: 16, height: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$balance Diamonds',
                                  style: TextStyle(
                                    color: isSufficient
                                        ? Colors.white
                                        : const Color(0xFFFF5252),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              color: Colors.white12,
                              height: 1,
                            ),
                          ),
                          _buildDetailRow(
                            label: 'Remaining Balance',
                            valueWidget: isSufficient
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(AssetRes.coinIcon,
                                          width: 16, height: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$remainingAfter Diamonds',
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Short by $shortBy 💎',
                                    style: const TextStyle(
                                      color: Color(0xFFFF5252),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Clear Confirmation Message ──
                    Text(
                      'Are you sure you want to purchase this effect for 💎 $price Diamonds? Your diamond balance will be deducted immediately.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Two Buttons: Cancel & Yes, Purchase ──
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : () => Get.back(),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23),
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Yes, Purchase Button
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _handleYesPurchase,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFE6A800),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.black),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('💎',
                                            style: TextStyle(fontSize: 13)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Yes, Purchase',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        valueWidget,
      ],
    );
  }
}

/// Attractive modal displayed when user has insufficient diamonds.
class InsufficientDiamondsDialog extends StatelessWidget {
  final int requiredDiamonds;
  final int currentBalance;
  final String effectName;
  final VoidCallback? onGetDiamonds;

  const InsufficientDiamondsDialog({
    super.key,
    required this.requiredDiamonds,
    required this.currentBalance,
    required this.effectName,
    this.onGetDiamonds,
  });

  static Future<void> show({
    required BuildContext context,
    required int requiredDiamonds,
    required int currentBalance,
    required String effectName,
    VoidCallback? onGetDiamonds,
  }) {
    return Get.dialog<void>(
      InsufficientDiamondsDialog(
        requiredDiamonds: requiredDiamonds,
        currentBalance: currentBalance,
        effectName: effectName,
        onGetDiamonds: onGetDiamonds,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortBy = requiredDiamonds - currentBalance;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFFB300)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                blurRadius: 20,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: const Color(0xFF141012),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 26)),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Insufficient Diamonds 💎',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'You need $requiredDiamonds Diamonds to purchase $effectName, but your current balance is $currentBalance Diamonds (short by $shortBy 💎).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          onGetDiamonds?.call();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFE6A800)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Get Diamonds',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Attractive celebration popup displayed upon successful purchase.
class PurchaseEffectSuccessDialog extends StatelessWidget {
  final String effectName;
  final String durationText;
  final int updatedBalance;
  final VoidCallback? onViewMyEffects;

  const PurchaseEffectSuccessDialog({
    super.key,
    required this.effectName,
    required this.durationText,
    required this.updatedBalance,
    this.onViewMyEffects,
  });

  static Future<void> show({
    required BuildContext context,
    required String effectName,
    required String durationText,
    required int updatedBalance,
    VoidCallback? onViewMyEffects,
  }) {
    return Get.dialog<void>(
      PurchaseEffectSuccessDialog(
        effectName: effectName,
        durationText: durationText,
        updatedBalance: updatedBalance,
        onViewMyEffects: onViewMyEffects,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF00E676), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.35),
                blurRadius: 25,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: const Color(0xFF0E1410),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF1DB954)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 30)),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '🎉 Purchase Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: effectName,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' has been activated for '),
                      TextSpan(
                        text: durationText,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Updated balance pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AssetRes.coinIcon, width: 16, height: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Remaining Balance: $updatedBalance Diamonds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons: "View My Effects" & "Done"
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          onViewMyEffects?.call();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1DB954), Color(0xFF00E676)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'My Effects',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
