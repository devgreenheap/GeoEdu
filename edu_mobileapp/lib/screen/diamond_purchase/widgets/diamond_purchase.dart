import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/screen/diamond_purchase/invoice_preview_screen.dart';
import 'package:geoedu/screen/diamond_purchase/service/invoice_generator.dart';
import 'package:geoedu/screen/help_and_support/payment_faq_screen.dart';
import 'package:geoedu/screen/help_and_support/report_issue/report_issue_controller.dart';
import 'package:geoedu/screen/help_and_support/report_issue/report_issue_screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/theme_res.dart';

class DiamondPurchase extends StatefulWidget {
  const DiamondPurchase({super.key});

  @override
  State<DiamondPurchase> createState() => _DiamondPurchaseState();
}

class _DiamondPurchaseState extends State<DiamondPurchase> {
  List<DiamondTransactionModel> diamondTransactions = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int? lastItemId;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

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
      _fetchTransactions(loadMore: true);
    }
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        diamondTransactions.clear();
        lastItemId = null;
        hasMore = true;
      });
    }

    try {
      final results = await GiftWalletService.instance
          .fetchDiamondTransactions(lastItemId: lastItemId);
      setState(() {
        diamondTransactions.addAll(results);
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

  void _onGetHelp(DiamondTransactionModel purchase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildHelpSheet(ctx, purchase),
    );
  }

  void _onDownloadInvoice(DiamondTransactionModel purchase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildInvoiceActionSheet(ctx, purchase),
    );
  }

  Widget _buildInvoiceActionSheet(
      BuildContext ctx, DiamondTransactionModel purchase) {
    final txnId = purchase.paymentId ?? purchase.transactionId ?? '${purchase.id}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1824),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tax Invoice',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transaction ID: $txnId',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.visibility_rounded,
                  color: Color(0xFFFF7A00)),
            ),
            title: const Text(
              'Preview & Print Invoice',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: const Text(
              'View full Tax Invoice with real-time app details',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white38),
            onTap: () {
              Navigator.pop(ctx);
              Get.to(() => InvoicePreviewScreen(transaction: purchase));
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.download_rounded,
                  color: Color(0xFF4CAF50)),
            ),
            title: const Text(
              'Download / Share PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: const Text(
              'Save PDF to files or share via WhatsApp/Email',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white38),
            onTap: () {
              Navigator.pop(ctx);
              InvoiceGenerator.downloadInvoice(context, purchase);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHelpSheet(BuildContext ctx, DiamondTransactionModel purchase) {
    final txnId = purchase.paymentId ?? purchase.transactionId ?? '${purchase.id}';
    final amountStr = '${purchase.currency ?? '₹'}${purchase.amount ?? 0}';
    final diamondsStr = '+${purchase.diamonds ?? 0} Diamonds';
    final helpMail = ReportIssueController.getEffectiveSupportEmail();

    final categories = [
      'Diamonds Not Credited',
      'Transaction / Payment Issue',
      'Refund & Duplicate Charge',
      'Tax Invoice & Billing',
      'Live Stream & Audio Call Issue',
      'Gifts & Entry Effects Issue',
      'App Bug / Technical Glitch',
      'General Inquiry & Feedback',
    ];

    IconData getCatIcon(String cat) {
      final lower = cat.toLowerCase();
      if (lower.contains('diamond')) return Icons.diamond_rounded;
      if (lower.contains('refund')) return Icons.currency_exchange_rounded;
      if (lower.contains('invoice')) return Icons.receipt_long_rounded;
      if (lower.contains('live')) return Icons.live_tv_rounded;
      if (lower.contains('gift')) return Icons.card_giftcard_rounded;
      if (lower.contains('bug')) return Icons.bug_report_rounded;
      if (lower.contains('inquiry')) return Icons.help_outline_rounded;
      return Icons.payment_rounded;
    }

    Color getCatColor(String cat) {
      final lower = cat.toLowerCase();
      if (lower.contains('diamond')) return const Color(0xFFFFB300);
      if (lower.contains('refund')) return const Color(0xFFE91E63);
      if (lower.contains('invoice')) return const Color(0xFF00BCD4);
      if (lower.contains('live')) return const Color(0xFFAB47BC);
      if (lower.contains('gift')) return const Color(0xFFFF7043);
      if (lower.contains('bug')) return const Color(0xFFEF5350);
      if (lower.contains('inquiry')) return const Color(0xFF90A4AE);
      return const Color(0xFF29B6F6);
    }

    String selectedCategory = 'Diamonds Not Credited';

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(
            color: Color(0xFF1B1824),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Need Help with this Purchase?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transaction: $txnId • $diamondsStr • $amountStr',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 16),

              // Category Selector Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Issue Category:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to switch',
                    style: TextStyle(
                      color: getCatColor(selectedCategory),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Selected Category Card with Dropdown Trigger
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (modalCtx) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF211D2D),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
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
                            const SizedBox(height: 14),
                            const Text(
                              'Choose Issue Category',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Colors.white10, height: 1),
                                itemBuilder: (context, idx) {
                                  final cat = categories[idx];
                                  final isSel = cat == selectedCategory;
                                  final col = getCatColor(cat);
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    leading: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: col.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(getCatIcon(cat),
                                          color: col, size: 20),
                                    ),
                                    title: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSel
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded,
                                            color: Color(0xFF4CAF50), size: 20)
                                        : null,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedCategory = cat;
                                      });
                                      Navigator.pop(modalCtx);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getCatColor(selectedCategory).withOpacity(0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              getCatColor(selectedCategory).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getCatIcon(selectedCategory),
                          color: getCatColor(selectedCategory),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedCategory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white60, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Horizontal Chips
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSel = cat == selectedCategory;
                    final col = getCatColor(cat);
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedCategory = cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? col.withOpacity(0.25)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? col
                                : Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white60,
                            fontSize: 11,
                            fontWeight:
                                isSel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),

              // Option 1: Report Issue Ticket
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.report_problem_rounded,
                      color: Color(0xFFFF5722)),
                ),
                title: const Text(
                  'Report an Issue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Create ticket for "$selectedCategory"',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.white38),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.to(() => ReportIssueScreen(
                        initialCategory: selectedCategory,
                        initialSubject: '[$selectedCategory] Txn #$txnId',
                        initialMessage:
                            'Hi Support,\n\nI need assistance regarding this purchase.\n\nIssue Category: $selectedCategory\nTransaction ID: $txnId\nDiamonds: $diamondsStr\nAmount: $amountStr\nDate: ${purchase.date ?? ''} ${purchase.time ?? ''}\n\nDescription of my issue: ',
                        txnId: txnId,
                        amountStr: amountStr,
                        diamondsStr: diamondsStr,
                      ));
                },
              ),
              const Divider(color: Colors.white10),

              // Option 2: Payment FAQs
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Color(0xFF2196F3)),
                ),
                title: const Text(
                  'Payment & Diamond FAQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: const Text(
                  'Read frequently asked questions about payments and diamonds',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.white38),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.to(() => const PaymentFaqScreen());
                },
              ),
              const Divider(color: Colors.white10),

              // Option 3: Email Support
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.email_outlined,
                      color: Color(0xFFFFB300)),
                ),
                title: const Text(
                  'Email Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Direct email to $helpMail',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.white38),
                onTap: () async {
                  Navigator.pop(ctx);
                  final subject = '[$selectedCategory] Txn #$txnId';
                  final body =
                      'Hello GeoEdu Support,\n\nIssue Category: $selectedCategory\nTransaction ID: $txnId\nAmount: $amountStr\nDiamonds: $diamondsStr\nDate: ${purchase.date ?? ''} ${purchase.time ?? ''}\n\nDetails: ';
                  final uri = Uri.parse(
                      'mailto:$helpMail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
                  try {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (diamondTransactions.isEmpty) {
      return const Center(
        child: Text(
          'No purchase history',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: diamondTransactions.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == diamondTransactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final purchase = diamondTransactions[index];
          return Container(
            padding: const EdgeInsets.all(4),
            color: Colors.transparent,
            child: Column(
              children: [
                // Transaction Details Card
                GestureDetector(
                  onTap: () => _onDownloadInvoice(purchase),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff5C24B7), Color(0xff36404E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${purchase.title}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "+ ${purchase.diamonds}",
                                  style: const TextStyle(
                                    color: Color(0xFFB6FF52),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(AssetRes.coinIcon,
                                    width: 20, height: 20),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: purchase.date,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: whitePure(context),
                                  ),
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    width: 3,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: whitePure(context),
                                      shape: BoxShape.circle,
                                    ),
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
                                    color: whitePure(context),
                                  ),
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    width: 3,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: whitePure(context),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            Expanded(
                              child: Text(
                                purchase.paymentId ?? purchase.transactionId ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: whitePure(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: purchase.currency ?? '₹',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const WidgetSpan(child: SizedBox(width: 2)),
                                TextSpan(
                                  text: '${purchase.amount ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive Action Bar (Get Help & Download Invoice)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0xff260063),
                      Color(0xff38547D),
                    ]),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionItem(
                        icon: AssetRes.help,
                        title: "Get Help",
                        onTap: () => _onGetHelp(purchase),
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.white24,
                      ),
                      _actionItem(
                        icon: AssetRes.download,
                        title: "Download Invoice",
                        onTap: () => _onDownloadInvoice(purchase),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }

  Widget _actionItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon, height: 18, width: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
