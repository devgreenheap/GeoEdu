import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/model/gift_wallet/gift_profit_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/star_wallet_screen/category_gift_history_screen.dart';
import 'package:geoedu/screen/star_wallet_screen/star_conversion_history_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

class StarWalletScreen extends StatefulWidget {
  const StarWalletScreen({super.key});

  @override
  State<StarWalletScreen> createState() => _StarWalletScreenState();
}

class _StarWalletScreenState extends State<StarWalletScreen>
    with SingleTickerProviderStateMixin {
  User? user;
  List<GiftProfitItem> giftProfits = [];
  bool isLoadingProfit = true;
  double coinValue = 1.0;
  String currency = '₹';
  int minRedeemCoins = 1;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    user = SessionManager.instance.getUser();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fetchFreshData();
    _fetchGiftProfit();
    _fetchConversionInfo();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _fetchFreshData() async {
    User? freshUser =
        await UserService.instance.fetchUserDetails(userId: user?.id);
    if (freshUser != null && mounted) {
      setState(() {
        user = freshUser;
        SessionManager.instance.setUser(freshUser);
      });
    }
  }

  Future<void> _fetchGiftProfit() async {
    try {
      final response = await GiftWalletService.instance.fetchGiftProfit();
      if (mounted) {
        setState(() {
          giftProfits = response.data ?? [];
          isLoadingProfit = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingProfit = false);
    }
  }

  Future<void> _fetchConversionInfo() async {
    try {
      final info = await GiftWalletService.instance.fetchConversionRateInfo();
      if (mounted && info.isNotEmpty) {
        setState(() {
          if (info['coin_value'] != null) {
            coinValue = (info['coin_value'] as num).toDouble();
          }
          if (info['currency'] != null) {
            currency = info['currency'].toString();
          }
          if (info['min_redeem_coins'] != null) {
            minRedeemCoins = (info['min_redeem_coins'] as num).toInt();
          }
        });
      }
    } catch (_) {}
  }

  int _getProfitForCategory(String name) {
    for (final p in giftProfits) {
      if ((p.categoryName ?? '').toLowerCase() == name.toLowerCase()) {
        return p.totalCoins ?? 0;
      }
    }
    return 0;
  }

  GiftProfitItem _getOrCreateProfitItem(String name, int defaultId) {
    for (final p in giftProfits) {
      if ((p.categoryName ?? '').toLowerCase() == name.toLowerCase()) {
        return p;
      }
    }
    return GiftProfitItem(
      categoryId: defaultId,
      categoryName: name,
      totalCoins: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Stack(
        children: [
          // Ambient cosmic background glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.45),
                  radius: 1.1,
                  colors: [
                    Color(0xFF241C10),
                    Color(0xFF10121C),
                    Color(0xFF090A10),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Cosmic sparkles & glowing particle waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CosmicBackgroundPainter(_sparkleController.value),
                );
              },
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    color: ColorRes.gold,
                    backgroundColor: const Color(0xFF161922),
                    onRefresh: () async {
                      await Future.wait([
                        _fetchFreshData(),
                        _fetchGiftProfit(),
                        _fetchConversionInfo(),
                      ]);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildHeroStarPodium(),
                          const SizedBox(height: 16),
                          _buildGiftProfitSection(),
                          const SizedBox(height: 16),
                          _buildConvertStarsToMoneyCard(),
                          const SizedBox(height: 16),
                          _buildRequestConversionButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top App Bar
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
          const Text(
            'Star Wallet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          IconButton(
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
    );
  }

  // 2. Hero 3D Star on Podium
  Widget _buildHeroStarPodium() {
    final lifetimeStars =
        user?.coinCollectedLifetime ?? user?.coinWallet ?? 0;

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Orbital golden rings
              CustomPaint(
                size: const Size(220, 180),
                painter: _OrbitalRingsPainter(),
              ),

              // Glowing podium base
              Positioned(
                bottom: 8,
                child: Container(
                  width: 140,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5A4418),
                        Color(0xFF1E1608),
                      ],
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(140, 28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Giant glowing 3D star token
              Positioned(
                bottom: 24,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFF7C2),
                        Color(0xFFFFCA28),
                        Color(0xFFF57F17),
                        Color(0xFFB76200),
                      ],
                      stops: [0.0, 0.45, 0.85, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withOpacity(0.6),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFF9C4),
                      width: 3.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFE082),
                            Color(0xFFFFA000),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withOpacity(0.8),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 52,
                          shadows: [
                            Shadow(
                              color: Color(0xFFB76200),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Title: Star Shop
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFF2A3), Color(0xFFFFC043)],
          ).createShader(bounds),
          child: const Text(
            'Star Shop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Subtitle: Lifetime Earnings
        Text(
          'Lifetime Earnings',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$lifetimeStars Stars',
          style: TextStyle(
            color: ColorRes.gold.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 3. Gift Profit Section with Category Cards
  Widget _buildGiftProfitSection() {
    final foodCoins = _getProfitForCategory('Food');
    final goldCoins = _getProfitForCategory('Gold');
    final farmsCoins = _getProfitForCategory('Farms');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Gift Profit + View History >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: Colors.black87, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Gift Profit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showHistorySelectionMenu,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'View History',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Food Category Card (Wine / Burgundy theme)
          _buildCategoryProfitCard(
            categoryName: 'Food',
            subtitle: 'Gifts Profit from Food category',
            coins: foodCoins,
            gradientColors: const [Color(0xFF38151D), Color(0xFF220C12)],
            borderColor: const Color(0xFFE74C3C).withOpacity(0.35),
            iconContainerColor: const Color(0xFF8B2535),
            coinTextColor: const Color(0xFFFF5252),
            arrowCircleColor: const Color(0xFF4A1A24),
            iconWidget: const Icon(Icons.cake_rounded,
                color: Color(0xFFFFB4BC), size: 24),
            onTap: () async {
              await Get.to(() => CategoryGiftHistoryScreen(
                    category: _getOrCreateProfitItem('Food', 1),
                  ));
              _fetchGiftProfit();
              _fetchFreshData();
            },
          ),
          const SizedBox(height: 10),

          // Gold Category Card (Bronze / Amber theme)
          _buildCategoryProfitCard(
            categoryName: 'Gold',
            subtitle: 'Gifts Profit from Gold category',
            coins: goldCoins,
            gradientColors: const [Color(0xFF382B12), Color(0xFF221A0A)],
            borderColor: const Color(0xFFF1C40F).withOpacity(0.35),
            iconContainerColor: const Color(0xFF7A5812),
            coinTextColor: const Color(0xFFFFD700),
            arrowCircleColor: const Color(0xFF4A3812),
            iconWidget: const Icon(Icons.military_tech_rounded,
                color: Color(0xFFFFE082), size: 26),
            onTap: () async {
              await Get.to(() => CategoryGiftHistoryScreen(
                    category: _getOrCreateProfitItem('Gold', 2),
                  ));
              _fetchGiftProfit();
              _fetchFreshData();
            },
          ),
          const SizedBox(height: 10),

          // Farms Category Card (Emerald / Forest green theme)
          _buildCategoryProfitCard(
            categoryName: 'Farms',
            subtitle: 'Gifts Profit from Farms category',
            coins: farmsCoins,
            gradientColors: const [Color(0xFF133221), Color(0xFF0C1F15)],
            borderColor: const Color(0xFF2ECC71).withOpacity(0.35),
            iconContainerColor: const Color(0xFF1E5B33),
            coinTextColor: const Color(0xFF2ECC71),
            arrowCircleColor: const Color(0xFF1B452B),
            iconWidget: const Icon(Icons.park_rounded,
                color: Color(0xFFA5D6A7), size: 24),
            onTap: () async {
              await Get.to(() => CategoryGiftHistoryScreen(
                    category: _getOrCreateProfitItem('Farms', 3),
                  ));
              _fetchGiftProfit();
              _fetchFreshData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProfitCard({
    required String categoryName,
    required String subtitle,
    required int coins,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color iconContainerColor,
    required Color coinTextColor,
    required Color arrowCircleColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            // Category Icon Container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 14),

            // Category Name & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Coin Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$coins',
                  style: TextStyle(
                    color: coinTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'coins',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Right Chevron Button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: arrowCircleColor,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: coinTextColor,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. "Convert Stars to Money" Info Card
  Widget _buildConvertStarsToMoneyCard() {
    return InkWell(
      onTap: _openConversionBottomSheet,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF282012),
              Color(0xFF17130A),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD54F).withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Info badge icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD54F).withOpacity(0.18),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withOpacity(0.4),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.currency_rupee_rounded,
                  color: Color(0xFFFFD54F),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Convert Stars to Money',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      text: 'Turn your earned stars into cash with ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Bank Transfer or UPI',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Shimmering coin graphics
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFFFFD54F), size: 28),
                  ],
                ),
                const SizedBox(width: 6),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFFD54F),
                    size: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. "Request Conversion" Golden Button
  Widget _buildRequestConversionButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFDF7A),
            Color(0xFFF39C12),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF39C12).withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _openConversionBottomSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.currency_exchange_rounded,
                    color: Color(0xFF2C1E0A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Request Conversion',
                  style: TextStyle(
                    color: Color(0xFF2C1E0A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF2C1E0A),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // History Selection Menu
  void _showHistorySelectionMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF161926),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorRes.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: ColorRes.gold, size: 22),
              ),
              title: const Text(
                'Gift Earning History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'View history of gifts received from viewers',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () {
                Get.back();
                Get.to(() => CategoryGiftHistoryScreen(
                      category: GiftProfitItem(
                        categoryId: 0,
                        categoryName: 'Star Wallet',
                        totalCoins: (user?.coinCollectedLifetime ?? user?.coinWallet ?? 0).toInt(),
                      ),
                    ));
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: Colors.greenAccent, size: 22),
              ),
              title: const Text(
                'Conversion & Payout History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'View requested payouts & payment completion records',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () {
                Get.back();
                Get.to(() => const StarConversionHistoryScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  // Help Dialog
  void _showHelpDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF161926),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorRes.gold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: ColorRes.gold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'About Star Wallet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '1. You earn stars when viewers send gifts in live streams.\n\n'
                '2. Stars are categorized by gift types (Food, Gold, Farms).\n\n'
                '3. You can convert your stars to real money at any time using "Request Conversion".\n\n'
                '4. Choose Bank Transfer or GPay/UPI as your payout method.\n\n'
                '5. Once submitted, the Admin reviews and confirms payment with transaction ID.\n\n'
                '6. You can track all payments under Conversion/Payout History.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorRes.gold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Got It',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CONVERSION POPUP / BOTTOM SHEET
  // ==========================================
  void _openConversionBottomSheet() {
    final availableWalletStars = (user?.coinWallet ?? 0).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ConversionModalWidget(
          availableWalletStars: availableWalletStars,
          coinValue: coinValue,
          currency: currency,
          giftProfits: giftProfits,
          onSuccess: () {
            _fetchFreshData();
            _fetchGiftProfit();
          },
        );
      },
    );
  }
}

// ==========================================
// CONVERSION MODAL STATEFUL WIDGET
// ==========================================
class _ConversionModalWidget extends StatefulWidget {
  final int availableWalletStars;
  final double coinValue;
  final String currency;
  final List<GiftProfitItem> giftProfits;
  final VoidCallback onSuccess;

  const _ConversionModalWidget({
    required this.availableWalletStars,
    required this.coinValue,
    required this.currency,
    required this.giftProfits,
    required this.onSuccess,
  });

  @override
  State<_ConversionModalWidget> createState() => _ConversionModalWidgetState();
}

class _ConversionModalWidgetState extends State<_ConversionModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _starsController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _upiNumberController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  String selectedCategory = 'All'; // 'All', 'Food', 'Gold', 'Farms'
  int selectedCategoryId = 0;
  String selectedPayoutMethod = 'Bank Transfer'; // 'Bank Transfer' or 'GPay/UPI'
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _starsController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _starsController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _phoneController.dispose();
    _upiNumberController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  int get availableStarsForCategory {
    if (selectedCategory == 'All') {
      return widget.availableWalletStars;
    }
    for (final p in widget.giftProfits) {
      if ((p.categoryName ?? '').toLowerCase() == selectedCategory.toLowerCase()) {
        final catStars = p.totalCoins ?? 0;
        return math.min(catStars, widget.availableWalletStars);
      }
    }
    return 0;
  }

  double get calculatedConversionAmount {
    final stars = int.tryParse(_starsController.text.trim()) ?? 0;
    return stars * widget.coinValue;
  }

  Future<void> _submitConversion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final stars = int.tryParse(_starsController.text.trim()) ?? 0;
    if (stars <= 0) {
      Get.snackbar('Invalid Stars', 'Please enter a valid number of stars to convert.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final maxStars = availableStarsForCategory;
    if (stars > maxStars) {
      Get.snackbar('Insufficient Stars',
          'You only have $maxStars stars available for $selectedCategory.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (selectedPayoutMethod == 'GPay/UPI') {
      if (_upiNumberController.text.trim().isEmpty &&
          _upiIdController.text.trim().isEmpty) {
        Get.snackbar('Missing Details', 'Please provide either GPay/UPI Number or UPI ID.',
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    setState(() => isSubmitting = true);

    try {
      final response = await GiftWalletService.instance.submitStarConversionRequest(
        coins: stars,
        payoutMethod: selectedPayoutMethod,
        categoryId: selectedCategoryId,
        categoryName: selectedCategory,
        accountHolderName: selectedPayoutMethod == 'Bank Transfer' ? _holderNameController.text.trim() : null,
        accountNumber: selectedPayoutMethod == 'Bank Transfer' ? _accountNumberController.text.trim() : null,
        ifscCode: selectedPayoutMethod == 'Bank Transfer' ? _ifscController.text.trim() : null,
        phoneNumber: _phoneController.text.trim(),
        upiNumber: selectedPayoutMethod == 'GPay/UPI' ? _upiNumberController.text.trim() : null,
        upiId: selectedPayoutMethod == 'GPay/UPI' ? _upiIdController.text.trim() : null,
      );

      setState(() => isSubmitting = false);

      if (response.status == true) {
        Get.back(); // close sheet
        widget.onSuccess();
        _showConfirmationSuccessDialog(stars, calculatedConversionAmount);
      } else {
        Get.snackbar('Request Failed', response.message ?? 'Failed to submit conversion request.',
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      Get.snackbar('Error', 'An error occurred. Please try again.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showConfirmationSuccessDialog(int stars, double amount) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF161926),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.18),
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 38),
              ),
              const SizedBox(height: 18),
              const Text(
                'Request Submitted!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your request to convert $stars Stars (${widget.currency} ${amount.toStringAsFixed(2)}) has been sent to the admin for approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: ColorRes.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive payment details once approved by admin.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ColorRes.gold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Get.back();
                        Get.to(() => const StarConversionHistoryScreen());
                      },
                      child: const Text('View History',
                          style: TextStyle(color: ColorRes.gold, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorRes.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text('Done',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final maxStars = availableStarsForCategory;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141622),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Convert Stars to Money',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              // Total Collected Balance Card
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF261D12), Color(0xFF17130B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: ColorRes.gold, size: 28),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available in Wallet',
                              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                            ),
                            Text(
                              '${widget.availableWalletStars} Stars',
                              style: const TextStyle(
                                color: ColorRes.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Estimated Value',
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                        ),
                        Text(
                          '${widget.currency} ${(widget.availableWalletStars * widget.coinValue).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Category Selector
              Text(
                'Select Conversion Category',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(),

              const SizedBox(height: 14),

              // Star Input Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stars to Convert',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Max: $maxStars',
                    style: TextStyle(
                      color: ColorRes.gold.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _starsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1C1F2E),
                  prefixIcon: const Icon(Icons.star_rounded, color: ColorRes.gold),
                  suffixText: 'Stars',
                  suffixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  hintText: 'Enter amount of stars',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: ColorRes.gold, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter stars to convert';
                  final num = int.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Must be greater than 0';
                  if (num > maxStars) return 'Exceeds available stars ($maxStars)';
                  return null;
                },
              ),

              // Quick shortcuts
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQuickPill('100', () => _starsController.text = '100'),
                  const SizedBox(width: 8),
                  _buildQuickPill('500', () => _starsController.text = '500'),
                  const SizedBox(width: 8),
                  _buildQuickPill('1000', () => _starsController.text = '1000'),
                  const SizedBox(width: 8),
                  _buildQuickPill('MAX', () => _starsController.text = '$maxStars'),
                ],
              ),

              const SizedBox(height: 14),

              // Applicable Conversion Amount Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B261D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'You Will Receive:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '${widget.currency} ${calculatedConversionAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Payout Method Selector: Bank Transfer vs GPay/UPI
              Text(
                'Choose Payout Method',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMethodTab(
                      title: 'Bank Transfer',
                      icon: Icons.account_balance_rounded,
                      isSelected: selectedPayoutMethod == 'Bank Transfer',
                      onTap: () => setState(() => selectedPayoutMethod = 'Bank Transfer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMethodTab(
                      title: 'GPay / UPI',
                      icon: Icons.qr_code_rounded,
                      isSelected: selectedPayoutMethod == 'GPay/UPI',
                      onTap: () => setState(() => selectedPayoutMethod = 'GPay/UPI'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Dynamic Input Fields
              if (selectedPayoutMethod == 'Bank Transfer') ...[
                _buildFormField(
                  controller: _holderNameController,
                  label: 'Account Holder Name',
                  hint: 'Full name as in bank passbook',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                _buildFormField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Bank account number',
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                _buildFormField(
                  controller: _ifscController,
                  label: 'IFSC Code',
                  hint: 'e.g. HDFC0001234',
                  icon: Icons.apartment_rounded,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                _buildFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Registered phone number',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ] else ...[
                _buildFormField(
                  controller: _upiNumberController,
                  label: 'GPay / UPI Number',
                  hint: 'e.g. 9876543210',
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                _buildFormField(
                  controller: _upiIdController,
                  label: 'UPI ID',
                  hint: 'e.g. username@okaxis / username@upi',
                  icon: Icons.alternate_email_rounded,
                ),
                _buildFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Contact phone number',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],

              const SizedBox(height: 20),

              // Submit Conversion Request Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorRes.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: isSubmitting ? null : _submitConversion,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Submit Conversion Request',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'name': 'All', 'id': 0},
      {'name': 'Food', 'id': 1},
      {'name': 'Gold', 'id': 2},
      {'name': 'Farms', 'id': 3},
    ];

    return Row(
      children: categories.map((c) {
        final name = c['name'] as String;
        final id = c['id'] as int;
        final isSelected = selectedCategory == name;

        int stars = 0;
        if (name == 'All') {
          stars = widget.availableWalletStars;
        } else {
          for (final p in widget.giftProfits) {
            if ((p.categoryName ?? '').toLowerCase() == name.toLowerCase()) {
              stars = p.totalCoins ?? 0;
            }
          }
        }

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = name;
                selectedCategoryId = id;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? ColorRes.gold : const Color(0xFF1C1F2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ColorRes.gold : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$stars',
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickPill(String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2234),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorRes.gold : const Color(0xFF1C1F2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? ColorRes.gold : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1F2E),
              prefixIcon: Icon(icon, color: Colors.white38, size: 18),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColorRes.gold, width: 1.2),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS FOR EXACT SCREENSHOT MATCH
// ==========================================

class _CosmicBackgroundPainter extends CustomPainter {
  final double animationProgress;

  _CosmicBackgroundPainter(this.animationProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFD54F).withOpacity(0.25);

    final randomPoints = [
      Offset(size.width * 0.12, size.height * 0.15),
      Offset(size.width * 0.88, size.height * 0.14),
      Offset(size.width * 0.18, size.height * 0.28),
      Offset(size.width * 0.82, size.height * 0.26),
      Offset(size.width * 0.08, size.height * 0.38),
      Offset(size.width * 0.92, size.height * 0.36),
      Offset(size.width * 0.25, size.height * 0.09),
      Offset(size.width * 0.72, size.height * 0.18),
    ];

    for (int i = 0; i < randomPoints.length; i++) {
      final pt = randomPoints[i];
      final phase = (animationProgress * 2 * math.pi + i) % (2 * math.pi);
      final alpha = 0.15 + 0.35 * (math.sin(phase) + 1) / 2;
      paint.color = const Color(0xFFFFE082).withOpacity(alpha);

      // Draw 4-point sparkle
      final path = Path();
      const r = 5.0;
      path.moveTo(pt.dx, pt.dy - r);
      path.lineTo(pt.dx + 1.5, pt.dy - 1.5);
      path.lineTo(pt.dx + r, pt.dy);
      path.lineTo(pt.dx + 1.5, pt.dy + 1.5);
      path.lineTo(pt.dx, pt.dy + r);
      path.lineTo(pt.dx - 1.5, pt.dy + 1.5);
      path.lineTo(pt.dx - r, pt.dy);
      path.lineTo(pt.dx - 1.5, pt.dy - 1.5);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter oldDelegate) => true;
}

class _OrbitalRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);

    final ringPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // First ellipse orbit
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 200, height: 75),
      ringPaint,
    );
    canvas.restore();

    // Second smaller ellipse
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 14);
    ringPaint.color = const Color(0xFFFFE082).withOpacity(0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 170, height: 60),
      ringPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitalRingsPainter oldDelegate) => false;
}
