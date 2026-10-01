import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/what_are_diamonds.dart';

import '../../../model/star_store/diamond_pack_model.dart';
import '../../star_score/widgets/diamond_purchase_bottom.dart';

class DiamondStore extends StatefulWidget {
  final VoidCallback? onPurchaseCompleted;

  const DiamondStore({super.key, this.onPurchaseCompleted});

  @override
  State<DiamondStore> createState() => _DiamondStoreState();
}

class _DiamondStoreState extends State<DiamondStore> {
  List<DiamondPackModel> diamondPacks = [];
  bool isLoading = true;
  int diamondBalance = 0;

  @override
  void initState() {
    super.initState();
    fetchDiamondPackages();
    fetchDiamondWallet();
  }

  Future<void> fetchDiamondPackages() async {
    try {
      final result = await GiftWalletService.instance.fetchDiamondPackages();
      result.sort((a, b) {
        final aPrice = (a.discountedPrice != null && a.discountedPrice! > 0)
            ? a.discountedPrice!
            : (a.originalPrice != null && a.originalPrice! > 0
                ? a.originalPrice!
                : (a.diamonds?.toDouble() ?? 0.0));
        final bPrice = (b.discountedPrice != null && b.discountedPrice! > 0)
            ? b.discountedPrice!
            : (b.originalPrice != null && b.originalPrice! > 0
                ? b.originalPrice!
                : (b.diamonds?.toDouble() ?? 0.0));
        final cmp = aPrice.compareTo(bPrice);
        if (cmp != 0) return cmp;
        return (a.diamonds ?? 0).compareTo(b.diamonds ?? 0);
      });
      if (mounted) {
        setState(() {
          diamondPacks = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchDiamondWallet() async {
    try {
      final result = await GiftWalletService.instance.fetchMyDiamondWallet();
      Loggers.info('Diamond wallet response: status=${result.status}, data=${result.data}');
      if (result.data != null && mounted) {
        setState(() {
          diamondBalance = result.data!.diamondBalance ?? 0;
        });
      }
    } catch (e) {
      Loggers.error('fetchDiamondWallet error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HERO BALANCE CARD
        _buildHeroBalanceCard(),

        const SizedBox(height: 14),

        // 2. "WHAT ARE DIAMONDS ?" CARD
        _buildWhatAreDiamondsCard(),

        const SizedBox(height: 18),

        // 3. "BUY DIAMONDS" SECTION TITLE
        _buildSectionHeader(),

        const SizedBox(height: 12),

        // 4. DIAMOND PACKAGES LIST
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: CircularProgressIndicator(color: Color(0xFFFFB300)),
            ),
          )
        else if (diamondPacks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Text(
                "No packages available",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: diamondPacks.length,
            itemBuilder: (context, index) {
              return _buildDiamondPackCard(diamondPacks[index], index);
            },
          ),

        const SizedBox(height: 20),

        // 5. TRUST BADGES FOOTER
        _buildTrustBadgesRow(),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Top Golden Balance Card with 3D Treasure Chest
  Widget _buildHeroBalanceCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 138),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.24),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const RadialGradient(
          center: Alignment(-0.6, -0.4),
          radius: 1.5,
          colors: [
            Color(0xFF332008),
            Color(0xFF1E1304),
            Color(0xFF0F0902),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Faint background crown watermark
          Positioned(
            top: 10,
            left: 140,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                "assets/images/gold_diamond.png",
                width: 90,
                height: 90,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Balance Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your\nBalance",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2E8F0),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/gold_diamond.png",
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$diamondBalance",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 38),
                        child: Text(
                          "Diamonds",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: 3D Overflowing Treasure Chest
                Image.asset(
                  "assets/images/treasure_chest_gold.png",
                  width: 135,
                  height: 105,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "What are Diamonds ?" Sleek Dark Card
  Widget _buildWhatAreDiamondsCard() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          barrierColor: Colors.black54,
          backgroundColor: Colors.transparent,
          builder: (context) => const WhatAreDiamondBottom(),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF6B4EE6).withValues(alpha: 0.45),
            width: 1.2,
          ),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A122B),
              Color(0xFF100D1C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Left: Golden Diamond Icon in circular dark pill
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF261908),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.diamond_outlined,
                color: Color(0xFFFFB300),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Title & Explanation
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "What are Diamonds ?",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Use diamonds to send gifts and support your favorite hosts.",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white60,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Chevron Button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Header: "Buy Diamonds"
  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              "assets/images/gold_diamond.png",
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                text: "Buy ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                children: [
                  TextSpan(
                    text: "Diamonds",
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Get more diamonds and enjoy exclusive gifts",
          style: TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  /// Individual Diamond Package Card with Neon Glow & 3D Assets
  Widget _buildDiamondPackCard(DiamondPackModel diamondPack, int index) {
    final originalPrice = diamondPack.originalPrice ?? 0;
    final discountedPrice = diamondPack.discountedPrice ?? 0;
    final int percentOff = originalPrice > 0
        ? (((originalPrice - discountedPrice) / originalPrice) * 100).round().clamp(0, 99)
        : 0;

    // Cycle through 3 distinct themes matching reference screenshot:
    // 0 = Cyan / Blue
    // 1 = Purple / Magenta (Popular)
    // 2 = Gold / Amber (Best Value)
    final int themeIndex = index % 3;

    final Color borderColor;
    final Color shadowColor;
    final List<Color> bgGradient;
    final String defaultAsset;
    final Color diamondIconColor;
    final List<Color> buttonGradient;
    final Color buttonTextColor;
    final String? badgeText;
    final Widget? badgeIcon;

    if (themeIndex == 0) {
      // Cyan Theme
      borderColor = const Color(0xFF00E5FF);
      shadowColor = const Color(0xFF00E5FF);
      bgGradient = [const Color(0xFF082035), const Color(0xFF061320)];
      defaultAsset = "assets/images/diamonds_blue_pack.png";
      diamondIconColor = const Color(0xFF00E5FF);
      buttonGradient = [const Color(0xFFFFB300), const Color(0xFFFF8F00)];
      buttonTextColor = const Color(0xFF1A1000);
      badgeText = null;
      badgeIcon = null;
    } else if (themeIndex == 1) {
      // Purple Theme
      borderColor = const Color(0xFFE040FB);
      shadowColor = const Color(0xFFE040FB);
      bgGradient = [const Color(0xFF280B38), const Color(0xFF12051C)];
      defaultAsset = "assets/images/diamonds_purple_pack.png";
      diamondIconColor = const Color(0xFFE040FB);
      buttonGradient = [const Color(0xFFE040FB), const Color(0xFFC026D3)];
      buttonTextColor = Colors.white;
      badgeText = "Popular";
      badgeIcon = const Text("🔥", style: TextStyle(fontSize: 12));
    } else {
      // Gold Theme
      borderColor = const Color(0xFFFFB300);
      shadowColor = const Color(0xFFFFB300);
      bgGradient = [const Color(0xFF332208), const Color(0xFF160E03)];
      defaultAsset = "assets/images/treasure_chest_gold.png";
      diamondIconColor = const Color(0xFFFFB300);
      buttonGradient = [const Color(0xFFFFB300), const Color(0xFFFF8F00)];
      buttonTextColor = const Color(0xFF1A1000);
      badgeText = "Best Value";
      badgeIcon = const Text("👑", style: TextStyle(fontSize: 12));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Tappable Container
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                barrierColor: Colors.black54,
                backgroundColor: Colors.transparent,
                builder: (_) => DiamondPurchaseBottom(
                  diamonds: '${diamondPack.diamonds ?? 0}',
                  offerPrice: '${diamondPack.discountedPrice ?? 0}',
                  price: '${diamondPack.originalPrice ?? 0}',
                  diamondPackId: diamondPack.id,
                  onPurchaseSuccess: () {
                    fetchDiamondWallet();
                    widget.onPurchaseCompleted?.call();
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: bgGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.20),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left: 3D Pack Image
                  SizedBox(
                    width: 76,
                    height: 64,
                    child: diamondPack.image != null && diamondPack.image!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: diamondPack.image!.addBaseURL(),
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Image.asset(defaultAsset, fit: BoxFit.contain),
                            errorWidget: (_, __, ___) => Image.asset(defaultAsset, fit: BoxFit.contain),
                          )
                        : Image.asset(defaultAsset, fit: BoxFit.contain),
                  ),

                  const SizedBox(width: 12),

                  // Middle: Diamond Quantity & Label
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.diamond_rounded,
                          color: diamondIconColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${diamondPack.diamonds ?? 0}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              "Diamonds",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right: "Buy for ₹X >" Gradient Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(colors: buttonGradient),
                      boxShadow: [
                        BoxShadow(
                          color: buttonGradient.first.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Buy for ",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: buttonTextColor.withValues(alpha: 0.85),
                          ),
                        ),
                        if (percentOff > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              "₹${originalPrice.toInt()}",
                              style: TextStyle(
                                fontSize: 11,
                                color: buttonTextColor.withValues(alpha: 0.6),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        Text(
                          "₹${discountedPrice.toInt()}",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: buttonTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: buttonTextColor,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-right Badge (e.g. "🔥 Popular" or "👑 Best Value" or "X% Off")
          if (badgeText != null || percentOff > 0)
            Positioned(
              top: -9,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF14071C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.9),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null) ...[
                      badgeIcon,
                      const SizedBox(width: 4),
                    ],
                    Text(
                      badgeText ?? "$percentOff% OFF",
                      style: TextStyle(
                        fontSize: 10.5,
                        color: themeIndex == 1
                            ? const Color(0xFFFF80DF)
                            : const Color(0xFFFFD54F),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
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

  /// 4-Column Trust Badges Row at Bottom
  Widget _buildTrustBadgesRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 100% Secure Payments
          _TrustBadgeItem(
            icon: Icons.verified_user_outlined,
            title: "100% Secure\nPayments",
          ),
          // 2. Instant Top Up
          _TrustBadgeItem(
            icon: Icons.bolt_rounded,
            title: "Instant\nTop Up",
          ),
          // 3. Exclusive Gifts
          _TrustBadgeItem(
            icon: Icons.card_giftcard_rounded,
            title: "Exclusive\nGifts",
          ),
          // 4. Trusted by 10 Crore+ Indians
          _TrustBadgeItem(
            icon: Icons.groups_rounded,
            title: "Trusted by\n10 Crore+ Indians 🇮🇳",
          ),
        ],
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TrustBadgeItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFD54F),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
