import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/gift_wallet/star_conversion_model.dart';
import 'package:geoedu/utilities/color_res.dart';

class StarConversionHistoryScreen extends StatefulWidget {
  const StarConversionHistoryScreen({super.key});

  @override
  State<StarConversionHistoryScreen> createState() => _StarConversionHistoryScreenState();
}

class _StarConversionHistoryScreenState extends State<StarConversionHistoryScreen> {
  bool isLoading = true;
  List<StarConversionItem> allRequests = [];
  String selectedFilter = 'all'; // all, paid, pending, rejected

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final data = await GiftWalletService.instance.fetchStarConversionHistory();
      if (mounted) {
        setState(() {
          allRequests = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<StarConversionItem> get filteredRequests {
    if (selectedFilter == 'paid') {
      return allRequests.where((r) => r.isPaid).toList();
    } else if (selectedFilter == 'pending') {
      return allRequests.where((r) => r.isPending).toList();
    } else if (selectedFilter == 'rejected') {
      return allRequests.where((r) => r.isRejected).toList();
    }
    return allRequests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildFilterTabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchHistory,
                color: ColorRes.gold,
                backgroundColor: const Color(0xFF1E2130),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131520),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
          const Expanded(
            child: Text(
              'Conversion & Payout History',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ColorRes.gold, size: 22),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All (${allRequests.length})'},
      {'key': 'pending', 'label': 'Pending (${allRequests.where((r) => r.isPending).length})'},
      {'key': 'paid', 'label': 'Paid (${allRequests.where((r) => r.isPaid).length})'},
      {'key': 'rejected', 'label': 'Rejected (${allRequests.where((r) => r.isRejected).length})'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = f['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? ColorRes.gold : const Color(0xFF1B1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? ColorRes.gold : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorRes.gold),
      );
    }

    final list = filteredRequests;

    if (list.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.white.withOpacity(0.2), size: 64),
                const SizedBox(height: 16),
                Text(
                  'No conversion requests found',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your Star-to-Money conversion history will appear here.',
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildPayoutCard(list[index]);
      },
    );
  }

  Widget _buildPayoutCard(StarConversionItem item) {
    if (item.isPaid) {
      return _buildPaidCelebrationCard(item);
    } else if (item.isRejected) {
      return _buildRejectedCard(item);
    } else {
      return _buildPendingCard(item);
    }
  }

  /// Celebratory Paid Card requested by the user
  Widget _buildPaidCelebrationCard(StarConversionItem item) {
    final currency = item.currency ?? '₹';
    final paidAmount = item.paidAmount != null && item.paidAmount! > 0 ? item.paidAmount! : (item.amount ?? 0);
    final paidDate = item.paymentDate ?? '';
    final paidTime = item.paymentTime ?? '';
    final txnId = item.transactionId ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF142E1F),
            Color(0xFF0F1E16),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27AE60).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Celebratory Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E824C), Color(0xFF166038)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Completed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Your Star-to-Money conversion has been successfully paid.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('PAID', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Payment Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlight Amount & Transaction ID Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Paid:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            '$currency ${paidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF2ECC71),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Transaction ID:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            txnId,
                            style: const TextStyle(
                              color: ColorRes.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid on:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            '$paidDate ${paidTime.isNotEmpty ? "at $paidTime" : ""}'.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Breakdown list
                _buildDetailRow('Conversion Category', item.categoryName ?? 'All', badgeColor: const Color(0xFFE67E22)),
                _buildDetailRow('Stars Converted', '${item.coins ?? 0} Stars', badgeColor: ColorRes.gold),
                _buildDetailRow('Payout Method', item.payoutMethod ?? 'Bank Transfer', badgeColor: Colors.blueAccent),
                if (item.payoutMethod == 'GPay/UPI') ...[
                  if (item.upiId != null && item.upiId!.isNotEmpty) _buildDetailRow('UPI ID', item.upiId!),
                  if (item.upiNumber != null && item.upiNumber!.isNotEmpty) _buildDetailRow('GPay Number', item.upiNumber!),
                  if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty) _buildDetailRow('Phone Number', item.phoneNumber!),
                ] else ...[
                  if (item.accountHolderName != null && item.accountHolderName!.isNotEmpty) _buildDetailRow('Account Holder', item.accountHolderName!),
                  if (item.accountNumber != null && item.accountNumber!.isNotEmpty) _buildDetailRow('Account Number', item.accountNumber!),
                  if (item.ifscCode != null && item.ifscCode!.isNotEmpty) _buildDetailRow('IFSC Code', item.ifscCode!),
                  if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty) _buildDetailRow('Phone Number', item.phoneNumber!),
                ],
                _buildDetailRow('Request Date', item.createdAt ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pending Card
  Widget _buildPendingCard(StarConversionItem item) {
    final currency = item.currency ?? '₹';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161926),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversion Requested',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.requestNumber ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.coins ?? 0} Stars',
                  style: const TextStyle(color: ColorRes.gold, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '$currency ${(item.amount ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Category', item.categoryName ?? 'All'),
            _buildDetailRow('Payout Method', item.payoutMethod ?? 'Bank Transfer'),
            _buildDetailRow('Submitted On', item.createdAt ?? '-'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Request has been sent to admin for approval. You will receive payment confirmation once approved.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rejected Card
  Widget _buildRejectedCard(StarConversionItem item) {
    final currency = item.currency ?? '₹';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Rejected',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.requestNumber ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'REJECTED',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.coins ?? 0} Stars (Refunded)',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$currency ${(item.amount ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Category', item.categoryName ?? 'All'),
            _buildDetailRow('Date', item.createdAt ?? '-'),
            if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Reason: ${item.adminNote}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}
