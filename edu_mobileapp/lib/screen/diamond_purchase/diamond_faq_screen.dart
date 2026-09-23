import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/model/diamond_purchase/diamond_faq_model.dart';
import 'package:geoedu/utilities/color_res.dart';


class DiamondFaqScreen extends StatefulWidget {
  const DiamondFaqScreen({super.key});

  @override
  State<DiamondFaqScreen> createState() => _DiamondFaqScreenState();
}

class _DiamondFaqScreenState extends State<DiamondFaqScreen> {
  List<DiamondFaq> faqs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      final response = await GiftWalletService.instance.fetchDiamondFaqs(category: 'diamond');
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
                iconColor: ColorRes.whitePure,
                title: "FAQs",
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFB6FF52)))
                    : faqs.isEmpty
                        ? const Center(
                            child: Text('No FAQs available',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: faqs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final faq = faqs[index];
                              return _FaqTile(faq: faq);
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
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1040).withOpacity(0.9),
            const Color(0xFF0D0D2B).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
