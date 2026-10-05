import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/gift_wallet/category_gift_history_model.dart';
import 'package:geoedu/model/gift_wallet/gift_profit_model.dart';
import 'package:geoedu/utilities/color_res.dart';

class CategoryGiftHistoryScreen extends StatefulWidget {
  final GiftProfitItem category;

  const CategoryGiftHistoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryGiftHistoryScreen> createState() =>
      _CategoryGiftHistoryScreenState();
}

class _CategoryGiftHistoryScreenState extends State<CategoryGiftHistoryScreen> {
  bool isLoading = true;
  String selectedFilter = 'all'; // 'all', 'today', 'yesterday', 'week', 'month'
  CategoryGiftHistoryData? historyData;

  final List<Map<String, String>> filterOptions = [
    {'key': 'all', 'label': 'All Time'},
    {'key': 'today', 'label': 'Today'},
    {'key': 'yesterday', 'label': 'Yesterday'},
    {'key': 'week', 'label': 'This Week'},
    {'key': 'month', 'label': 'This Month'},
  ];

  Color get categoryColor {
    switch (widget.category.categoryName) {
      case 'Food':
        return const Color(0xFFFF6B6B);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Farms':
        return const Color(0xFF51CF66);
      default:
        return ColorRes.primaryColor;
    }
  }

  IconData get categoryIcon {
    switch (widget.category.categoryName) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Gold':
        return Icons.workspace_premium_rounded;
      case 'Farms':
        return Icons.park_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory(selectedFilter);
  }

  Future<void> _fetchHistory(String filter) async {
    setState(() => isLoading = true);
    try {
      final response = await GiftWalletService.instance.fetchCategoryGiftHistory(
        categoryId: widget.category.categoryId ?? 0,
        categoryName: widget.category.categoryName,
        filter: filter,
      );

      if (mounted) {
        setState(() {
          historyData = response.data;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  int get displayedTotalStars {
    if (historyData != null && historyData!.totalStars != null) {
      return historyData!.totalStars!;
    }
    if (selectedFilter == 'all') {
      return widget.category.totalCoins ?? 0;
    }
    return 0;
  }

  int get displayedTotalDiamonds {
    return historyData?.totalDiamonds ?? 0;
  }

  int get displayedTotalTransactions {
    if (historyData != null && historyData!.totalTransactions != null) {
      return historyData!.totalTransactions!;
    }
    return historyData?.transactions?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final catName = widget.category.categoryName ?? 'Category';

    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      body: Column(
        children: [
          _buildHeader(catName),
          Expanded(
            child: RefreshIndicator(
              color: categoryColor,
              backgroundColor: ColorRes.cardBackground,
              onRefresh: () => _fetchHistory(selectedFilter),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSummaryCard(catName),
                    const SizedBox(height: 20),
                    _buildFilterSection(),
                    const SizedBox(height: 20),
                    _buildTransactionsSection(catName),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String catName) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(categoryIcon, color: categoryColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$catName History',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String catName) {
    return Container(
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
          color: categoryColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$catName Earnings',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getFilterLabel(selectedFilter),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      catName,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  value: '$displayedTotalStars',
                  label: 'Stars Earned',
                  color: categoryColor,
                  icon: '⭐',
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: Colors.white.withOpacity(0.08),
                ),
                _buildStatColumn(
                  value: '$displayedTotalDiamonds',
                  label: 'Diamonds Spent',
                  color: const Color(0xFF4DABF7),
                  icon: '💎',
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: Colors.white.withOpacity(0.08),
                ),
                _buildStatColumn(
                  value: '$displayedTotalTransactions',
                  label: 'Total Gifts',
                  color: Colors.white,
                  icon: '🎁',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String value,
    required String label,
    required Color color,
    required String icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.filter_alt_outlined,
                  size: 16, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'DATE FILTER',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filterOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = filterOptions[index];
              final isSelected = selectedFilter == option['key'];

              return GestureDetector(
                onTap: () {
                  if (selectedFilter != option['key']) {
                    setState(() {
                      selectedFilter = option['key']!;
                    });
                    _fetchHistory(selectedFilter);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor
                        : ColorRes.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      option['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? (categoryColor == const Color(0xFFFFD700)
                                ? Colors.black
                                : Colors.white)
                            : Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(String catName) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              CircularProgressIndicator(
                color: categoryColor,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 14),
              Text(
                'Loading transactions...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final transactions = historyData?.transactions ?? [];

    if (transactions.isEmpty) {
      return _buildEmptyState(catName);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GIFT TRANSACTIONS (${transactions.length})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                _getFilterLabel(selectedFilter),
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index], catName);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      CategoryGiftTransactionItem item, String catName) {
    final giftImage = item.giftImage;
    final hasImage = giftImage != null && giftImage.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Category tag & Date/time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$catName Gift 🎁',
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.time ?? item.date ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                  if (item.date != null && item.time != null) ...[
                    Text(
                      ' • ${item.date}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main body: Gift icon + Info + Stars & Diamonds
          Row(
            children: [
              // Gift Image Thumbnail
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: giftImage.addBaseURL(),
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            categoryIcon,
                            color: categoryColor,
                            size: 26,
                          ),
                        )
                      : Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.giftName ?? 'Gift',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Sender: ${item.senderName ?? 'User'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Earnings Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${item.starsEarned ?? 0}',
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stars Earned',
                    style: TextStyle(
                      color: categoryColor.withOpacity(0.8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.diamonds ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFF4DABF7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text('💎', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 2),
                      Text(
                        'spent',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String catName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: ColorRes.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No $catName Gifts Found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selectedFilter == 'all'
                ? 'No transactions have been recorded in this category yet.'
                : 'No transactions found for ${_getFilterLabel(selectedFilter)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String key) {
    switch (key) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'all':
      default:
        return 'All Time';
    }
  }
}
