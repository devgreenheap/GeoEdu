import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_history_model.dart';
import 'package:geoedu/model/gift_wallet/gift_profit_model.dart';

import '../../../utilities/asset_res.dart';
import '../../../utilities/theme_res.dart';

class DiamondPurchaseHistory extends StatefulWidget {
  const DiamondPurchaseHistory({super.key});

  @override
  State<DiamondPurchaseHistory> createState() => _DiamondPurchaseHistoryState();
}

class _DiamondPurchaseHistoryState extends State<DiamondPurchaseHistory> {
  List<DiamondSpendHistoryModel> diamondPurchaseHistoryList = [];
  List<GiftProfitItem> giftProfits = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isLoadingProfit = true;
  int? lastItemId;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _fetchGiftProfit();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _fetchHistory(loadMore: true);
    }
  }

  Future<void> _fetchHistory({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        diamondPurchaseHistoryList.clear();
        lastItemId = null;
        hasMore = true;
      });
    }

    try {
      final results = await GiftWalletService.instance
          .fetchMyDiamondSpendHistory(lastItemId: lastItemId);
      setState(() {
        diamondPurchaseHistoryList.addAll(results);
        if (results.isNotEmpty) {
          lastItemId = results.last.id;
        }
        if (results.isEmpty) {
          hasMore = false;
        }
      });
    } catch (_) {}

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
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

  Widget _buildCategorySummary() {
    if (isLoadingProfit) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
            child: CircularProgressIndicator(
                color: Color(0xFFB6FF52), strokeWidth: 2)),
      );
    }

    if (giftProfits.isEmpty) return const SizedBox.shrink();

    final totalCoins =
        giftProfits.fold<int>(0, (sum, item) => sum + (item.totalCoins ?? 0));

    final categoryColors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD700),
      const Color(0xFF51CF66),
      const Color(0xFF748FFC),
      const Color(0xFFFF922B),
      const Color(0xFFCC5DE8),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D0D2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard,
                  color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Gift Profit by Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$totalCoins',
                style: const TextStyle(
                  color: Color(0xFFB6FF52),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...giftProfits.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = categoryColors[index % categoryColors.length];
            final percentage = totalCoins > 0
                ? (item.totalCoins ?? 0) / totalCoins
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryName ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${item.totalCoins ?? 0}',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (diamondPurchaseHistoryList.isEmpty) {
      return const Center(
          child: Text('No spend history',
              style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchHistory();
        await _fetchGiftProfit();
      },
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Category-wise Gift Profit Summary
          _buildCategorySummary(),
          if (giftProfits.isNotEmpty && diamondPurchaseHistoryList.isNotEmpty)
            const SizedBox(height: 16),
          // Spend history list
          ...List.generate(
            diamondPurchaseHistoryList.length + (isLoadingMore ? 1 : 0),
            (index) {
              if (index == diamondPurchaseHistoryList.length) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator()));
              }
              final purchase = diamondPurchaseHistoryList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff5C24B7), Color(0xff36404E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text("${purchase.title}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Text("${purchase.diamonds ?? 0}",
                                  style: TextStyle(
                                      color:
                                          (purchase.diamonds ?? 0).isNegative
                                              ? Colors.red
                                              : const Color(0xFFB6FF52))),
                              Image.asset(AssetRes.coinIcon,
                                  width: 20, height: 20)
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        spacing: 10,
                        children: [
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.date,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: whitePure(context))),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  width: 3,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: whitePure(context),
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ]),
                          ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.time,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: whitePure(context))),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  width: 3,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: whitePure(context),
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ]),
                          ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.transactionId,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: whitePure(context))),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
