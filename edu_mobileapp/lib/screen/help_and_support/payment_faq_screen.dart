import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/model/diamond_purchase/diamond_faq_model.dart';

class PaymentFaqScreen extends StatefulWidget {
  const PaymentFaqScreen({super.key});

  @override
  State<PaymentFaqScreen> createState() => _PaymentFaqScreenState();
}

class _PaymentFaqScreenState extends State<PaymentFaqScreen> {
  List<DiamondFaq> faqs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      final response = await GiftWalletService.instance.fetchDiamondFaqs(category: 'payment');
      if (mounted) {
        setState(() {
          faqs = response.data ?? [];
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: kSecondaryHeaderGradient)),
          ),
          Column(
            children: [
              const CustomAppBar(
                iconColor: Colors.white,
                title: "Frequently Asked Questions",
                centertitle: false,
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFb6ff52)))
                    : faqs.isEmpty
                        ? const Center(
                            child: Text(
                              'No FAQs available',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: faqs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _FaqTile(faq: faqs[index]);
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final DiamondFaq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white38,
          title: Text(
            widget.faq.question ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.faq.answer ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
