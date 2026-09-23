import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/agent_commission_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AgentCommissionScreen extends StatefulWidget {
  const AgentCommissionScreen({super.key});

  @override
  State<AgentCommissionScreen> createState() => _AgentCommissionScreenState();
}

class _AgentCommissionScreenState extends State<AgentCommissionScreen> {
  final List<CommissionTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  num _totalCommission = 0;
  num _paidCommission = 0;
  num _balanceCommission = 0;
  num _commissionRate = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCommission();
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
        !_isLoadingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchCommission() async {
    try {
      final result = await CommonService.instance.fetchAgentCommission();
      if (result.status == true && result.data != null) {
        setState(() {
          _totalCommission = result.data!.totalCommission ?? 0;
          _paidCommission = result.data!.paidCommission ?? 0;
          _balanceCommission = result.data!.balanceCommission ?? 0;
          _commissionRate = result.data!.commissionRate ?? 0;
          _transactions.addAll(result.data!.transactions ?? []);
          _hasMore = (result.data!.transactions ?? []).length >= 20;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMore() async {
    if (_transactions.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await CommonService.instance
          .fetchAgentCommission(lastItemId: _transactions.last.id);
      if (result.status == true &&
          result.data != null &&
          (result.data!.transactions ?? []).isNotEmpty) {
        setState(() {
          _transactions.addAll(result.data!.transactions!);
          _hasMore = result.data!.transactions!.length >= 20;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C1A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: const Text(
          "Commission",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white38, strokeWidth: 2))
          : Column(
              children: [
                /// Summary card
                _CommissionSummaryCard(
                  totalCommission: _totalCommission,
                  paidCommission: _paidCommission,
                  balanceCommission: _balanceCommission,
                  commissionRate: _commissionRate,
                ),
                const SizedBox(height: 8),

                /// Transactions header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_transactions.length} records',
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                /// Transaction list
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  color: Colors.white24, size: 60),
                              SizedBox(height: 12),
                              Text(
                                'No commission transactions yet',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          itemCount: _transactions.length +
                              (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            if (index == _transactions.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white38, strokeWidth: 2),
                                ),
                              );
                            }
                            return _CommissionTransactionTile(
                              transaction: _transactions[index],
                              formatDate: _formatDate,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _CommissionSummaryCard extends StatelessWidget {
  final num totalCommission;
  final num paidCommission;
  final num balanceCommission;
  final num commissionRate;

  const _CommissionSummaryCard({
    required this.totalCommission,
    required this.paidCommission,
    required this.balanceCommission,
    required this.commissionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          /// Total + Rate row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Commission',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.diamond_outlined,
                            color: Color(0xFF00D2FF), size: 24),
                        const SizedBox(width: 6),
                        Text(
                          _formatAmount(totalCommission),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$commissionRate%',
                      style: const TextStyle(
                        color: Color(0xFF00D2FF),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Rate',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),

          /// Paid + Balance row
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Paid',
                  amount: paidCommission,
                  color: Colors.greenAccent,
                  icon: Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Balance',
                  amount: balanceCommission,
                  color: Colors.orangeAccent,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(num amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final num amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatAmount(num amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
}

class _CommissionTransactionTile extends StatelessWidget {
  final CommissionTransaction transaction;
  final String Function(String?) formatDate;

  const _CommissionTransactionTile({
    required this.transaction,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          /// Profile photo
          CustomImage(
            size: const Size(44, 44),
            image: (transaction.profilePhoto ?? '').addBaseURL(),
            fullName: transaction.fullname,
          ),
          const SizedBox(width: 12),

          /// Transaction info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.fullname ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${transaction.username ?? ''}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(transaction.createdAt),
                  style:
                      const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),

          /// Diamond + commission
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_outlined,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '${transaction.diamondAmount ?? 0}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${transaction.commissionEarned ?? 0}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
