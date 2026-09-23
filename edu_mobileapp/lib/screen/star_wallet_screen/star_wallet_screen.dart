import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/gift_wallet/gift_profit_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

class StarWalletScreen extends StatefulWidget {
  const StarWalletScreen({super.key});

  @override
  State<StarWalletScreen> createState() => _StarWalletScreenState();
}

class _StarWalletScreenState extends State<StarWalletScreen> {
  User? user;
  List<GiftProfitItem> giftProfits = [];
  bool isLoadingProfit = true;

  @override
  void initState() {
    super.initState();
    user = SessionManager.instance.getUser();
    _fetchFreshData();
    _fetchGiftProfit();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                color: ColorRes.blackPure,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child:
                            Image.asset(AssetRes.editStar, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Star Shop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lifetime',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Gift Profit Section
                    _buildGiftProfitSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Star Wallet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftProfitSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorRes.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard,
                    color: ColorRes.gold, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gift Profit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoadingProfit)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: ColorRes.gold,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (giftProfits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No gift profit yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...giftProfits.map((item) => _buildProfitRow(item)),
        ],
      ),
    );
  }

  Widget _buildProfitRow(GiftProfitItem item) {
    final categoryColors = {
      'Food': const Color(0xFFFF6B6B),
      'Gold': const Color(0xFFFFD700),
      'Farms': const Color(0xFF51CF66),
    };

    final categoryIcons = {
      'Food': Icons.fastfood_rounded,
      'Gold': Icons.workspace_premium_rounded,
      'Farms': Icons.park_rounded,
    };

    final color =
        categoryColors[item.categoryName] ?? ColorRes.primaryColor;
    final icon =
        categoryIcons[item.categoryName] ?? Icons.category_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.categoryName ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalCoins ?? 0}',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
