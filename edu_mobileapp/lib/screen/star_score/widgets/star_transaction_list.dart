import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/star_score/star_score_model.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:intl/intl.dart';

class StarTransactionList extends StatefulWidget {
  final String type; // "all", "video", "audio", "chat"

  const StarTransactionList({super.key, required this.type});

  @override
  State<StarTransactionList> createState() => _StarTransactionListState();
}

class _StarTransactionListState extends State<StarTransactionList>
    with AutomaticKeepAliveClientMixin {
  List<StarTransactionItem> transactions = [];
  bool isLoading = true;
  bool hasMore = false;
  bool isLoadingMore = false;
  int? nextLastItemId;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  /// Maps tab type to the grouped_transactions key
  String? get _groupKey {
    switch (widget.type) {
      case 'chat':
        return 'chat_gift';
      case 'audio':
        return 'audio_gift';
      case 'video':
        return 'video_gift';
      default:
        return null; // "all" uses transactions list
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
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
      _loadMore();
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await GiftWalletService.instance
          .fetchStarTransactions(type: widget.type);
      if (mounted) {
        setState(() {
          transactions = _extractTransactions(response);
          hasMore = response.hasMore ?? false;
          nextLastItemId = response.nextLastItemId;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<StarTransactionItem> _extractTransactions(StarScoreResponseModel response) {
    final key = _groupKey;
    if (key != null && response.groupedTransactions != null) {
      return response.groupedTransactions![key] ?? [];
    }
    // For "all" tab: use transactions list, but also include items from all
    // grouped_transactions keys (e.g. admin_bonus) that may not be in the flat list.
    final flatList = response.transactions ?? [];
    if (response.groupedTransactions != null) {
      final flatIds = flatList.map((e) => e.id).toSet();
      final missing = <StarTransactionItem>[];
      for (final group in response.groupedTransactions!.values) {
        for (final item in group) {
          if (!flatIds.contains(item.id)) {
            missing.add(item);
          }
        }
      }
      if (missing.isNotEmpty) {
        final merged = [...flatList, ...missing];
        merged.sort((a, b) {
          final aDate = a.createdAt ?? '';
          final bDate = b.createdAt ?? '';
          return bDate.compareTo(aDate);
        });
        return merged;
      }
    }
    return flatList;
  }

  Future<void> _loadMore() async {
    if (nextLastItemId == null) return;
    setState(() => isLoadingMore = true);
    try {
      final response = await GiftWalletService.instance
          .fetchStarTransactions(type: widget.type, lastItemId: nextLastItemId);
      if (mounted) {
        setState(() {
          transactions.addAll(_extractTransactions(response));
          hasMore = response.hasMore ?? false;
          nextLastItemId = response.nextLastItemId;
          isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    final response = await GiftWalletService.instance
        .fetchStarTransactions(type: widget.type);
    if (mounted) {
      setState(() {
        transactions = _extractTransactions(response);
        hasMore = response.hasMore ?? false;
        nextLastItemId = response.nextLastItemId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB6FF52)),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetRes.starScoreStar, height: 48, width: 48),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: () {
                setState(() => isLoading = true);
                _fetchTransactions();
              },
              icon: const Icon(Icons.refresh, color: Colors.white38, size: 32),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFB6FF52),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: transactions.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFFB6FF52)),
              ),
            );
          }
          return _buildTransactionCard(transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(StarTransactionItem item) {
    final isCredit = item.type == 'credit';
    final dateTime = _parseDate(item.createdAt);
    final timeStr = dateTime != null ? DateFormat('hh:mm a').format(dateTime) : '';
    final dateStr = dateTime != null ? DateFormat('dd/MM/yy').format(dateTime) : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(colors: [
          Color(0xFF5C24B7),
          Color(0xFF36404E),
        ]),
      ),
      child: Column(
        spacing: 5,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${isCredit ? '+' : '-'} ${item.stars ?? 0} ",
                      style: TextStyle(
                        color: isCredit
                            ? const Color(0xFFB6FF52)
                            : const Color(0xFFFF5252),
                        fontSize: 14,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Image.asset(
                        AssetRes.starScoreStar,
                        height: 12,
                        width: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.description ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            spacing: 5,
            children: [
              Text(
                timeStr,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              _circle(),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Widget _circle() {
    return Container(
      height: 5,
      width: 5,
      decoration: const BoxDecoration(
        color: Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
}
