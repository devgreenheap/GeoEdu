import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/diamond_purchase/diamond_faq_model.dart';
import 'package:geoedu/utilities/asset_res.dart';

class DiamondFaqScreen extends StatefulWidget {
  final int initialTab;

  const DiamondFaqScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<DiamondFaqScreen> createState() => _DiamondFaqScreenState();
}

class _DiamondFaqScreenState extends State<DiamondFaqScreen> {
  late int selectedTab; // 0: Diamond FAQs, 1: Payment FAQs
  List<DiamondFaq> diamondFaqs = [];
  List<DiamondFaq> paymentFaqs = [];
  bool isLoading = true;

  // Fallbacks matching real-time content from reference UI
  static final List<DiamondFaq> _fallbackDiamondFaqs = [
    DiamondFaq(
      id: 1,
      category: 'diamond',
      question: 'What are Diamonds?',
      answer:
          'Diamonds are the in-app currency used to purchase gifts, effects, and other premium features in the app.',
    ),
    DiamondFaq(
      id: 2,
      category: 'diamond',
      question: 'Can diamonds be converted into my country’s currency?',
      answer:
          'Diamonds purchased for in-app use cannot usually be converted into real money. However, host earnings (received as per platform rules) may be eligible for withdrawal. Please check the payout section for more details.',
    ),
    DiamondFaq(
      id: 3,
      category: 'diamond',
      question: 'How do I purchase diamonds?',
      answer:
          'You can buy diamonds anytime from the Diamond Store in the Premium section. Simply choose your preferred diamond pack and complete the secure checkout.',
    ),
    DiamondFaq(
      id: 4,
      category: 'diamond',
      question: 'Do diamonds have an expiration date?',
      answer:
          'No, purchased diamonds remain permanently in your account wallet until you choose to spend them on gifts, entry effects, or other premium perks.',
    ),
  ];

  static final List<DiamondFaq> _fallbackPaymentFaqs = [
    DiamondFaq(
      id: 5,
      category: 'payment',
      question: 'What payment methods are supported?',
      answer:
          'We support Google Play In-App Billing, Apple App Store purchases, UPI, major Credit/Debit Cards (Visa, MasterCard, RuPay), and secure Net Banking.',
    ),
    DiamondFaq(
      id: 6,
      category: 'payment',
      question: 'Is my payment transaction secure?',
      answer:
          'Yes, 100%. All transactions are processed through PCI-DSS Level 1 compliant payment gateways featuring end-to-end 256-bit SSL encryption.',
    ),
    DiamondFaq(
      id: 7,
      category: 'payment',
      question: 'How long does it take for diamonds to reflect after payment?',
      answer:
          'Diamonds are credited immediately upon transaction approval. In rare cases of banking delays, please allow up to 10 minutes and check your invoice history.',
    ),
    DiamondFaq(
      id: 8,
      category: 'payment',
      question: 'What should I do if my payment was deducted but diamonds not added?',
      answer:
          'Please visit the Diamond Purchase screen, tap Download Invoice, and share your Transaction ID with our 24/7 Help & Support team for immediate resolution.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() => isLoading = true);
    try {
      final category = selectedTab == 0 ? 'diamond' : 'payment';
      final response =
          await GiftWalletService.instance.fetchDiamondFaqs(category: category);
      if (mounted) {
        setState(() {
          final serverList = response.data ?? [];
          if (selectedTab == 0) {
            diamondFaqs = serverList.isNotEmpty ? serverList : _fallbackDiamondFaqs;
          } else {
            paymentFaqs = serverList.isNotEmpty ? serverList : _fallbackPaymentFaqs;
          }
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (selectedTab == 0 && diamondFaqs.isEmpty) {
            diamondFaqs = _fallbackDiamondFaqs;
          } else if (selectedTab == 1 && paymentFaqs.isEmpty) {
            paymentFaqs = _fallbackPaymentFaqs;
          }
          isLoading = false;
        });
      }
    }
  }

  void _onTabChanged(int index) {
    if (selectedTab == index) return;
    setState(() {
      selectedTab = index;
    });
    final currentList = index == 0 ? diamondFaqs : paymentFaqs;
    if (currentList.isEmpty) {
      _fetchFaqs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFaqs = selectedTab == 0
        ? (diamondFaqs.isNotEmpty ? diamondFaqs : _fallbackDiamondFaqs)
        : (paymentFaqs.isNotEmpty ? paymentFaqs : _fallbackPaymentFaqs);

    return Scaffold(
      backgroundColor: const Color(0xFF090A12),
      body: Stack(
        children: [
          // 1. Radiant Orange Header Ambient Background Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF5211),
                    Color(0xFFE64A19),
                    Color(0xFF8D2506),
                    Color(0x00090A12),
                  ],
                  stops: [0.0, 0.45, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Ambient radial glow behind the top-right question bubble
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB300).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Custom App Bar matching reference screenshot
                _buildTopAppBar(),

                const SizedBox(height: 10),

                // Pill-Shaped Segment Switcher (Diamond FAQs / Payment FAQs)
                _buildSegmentSwitcher(),

                const SizedBox(height: 16),

                // FAQs list + bottom illustration
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFFB300),
                    backgroundColor: const Color(0xFF161726),
                    onRefresh: _fetchFaqs,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFB300),
                              ),
                            ),
                          )
                        else ...[
                          // List of FAQ Cards
                          ...activeFaqs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final faq = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _FaqItemCard(
                                faq: faq,
                                isDiamondCategory: selectedTab == 0,
                                initiallyExpanded: index < 2, // Expand first two cards matching screenshot
                              ),
                            );
                          }),

                          const SizedBox(height: 20),

                          // 3D Bottom Illustration with glowing diamonds & question mark
                          _buildBottomIllustration(),
                        ],
                      ],
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

  /// App Bar matching reference screenshot: Back button, centered "FAQs", and top-right question icon with sparkles
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Centered Title
          const Text(
            'FAQs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),

          // Top Right Question Sparkle Graphic
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Speech bubble badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Color(0xFFE64A19),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                // Sparkle star 1
                const Positioned(
                  top: -2,
                  right: -4,
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Sparkle star 2
                const Positioned(
                  bottom: -2,
                  left: -4,
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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

  /// Segment selector matching reference screenshot: Diamond FAQs / Payment FAQs
  Widget _buildSegmentSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF121422),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Tab 0: Diamond FAQs
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(0),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selectedTab == 0
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFFFA000),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selectedTab == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: selectedTab == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.diamond_rounded,
                      size: 19,
                      color: selectedTab == 0
                          ? const Color(0xFF1A1202)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Diamond FAQs',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: selectedTab == 0
                          ? const Color(0xFF1A1202)
                          : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 1: Payment FAQs
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selectedTab == 1
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFFFA000),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selectedTab == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: selectedTab == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      size: 19,
                      color: selectedTab == 1
                          ? const Color(0xFF1A1202)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment FAQs',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: selectedTab == 1
                          ? const Color(0xFF1A1202)
                          : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Glowing Bottom Illustration of Diamonds & Floating Question Bubble
  Widget _buildBottomIllustration() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient purple & gold glow underneath
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.22),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.22),
                  blurRadius: 50,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),

          // Illustration Image from assets
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              AssetRes.faqIllustration,
              height: 220,
              width: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildFallbackIllustration(),
            ),
          ),
        ],
      ),
    );
  }

  /// Vector fallback if image asset is unavailable
  Widget _buildFallbackIllustration() {
    return Container(
      width: 200,
      height: 160,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base pedestal
          Positioned(
            bottom: 10,
            child: Container(
              width: 140,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B2A),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
              ),
            ),
          ),
          // Large Gold Diamond
          const Positioned(
            bottom: 25,
            child: Icon(
              Icons.diamond_rounded,
              color: Color(0xFFFFB300),
              size: 70,
            ),
          ),
          // Purple Speech Bubble with ?
          Positioned(
            top: 15,
            right: 25,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF9C27B0),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable FAQ Item Card matching reference screenshot style
class _FaqItemCard extends StatefulWidget {
  final DiamondFaq faq;
  final bool isDiamondCategory;
  final bool initiallyExpanded;

  const _FaqItemCard({
    required this.faq,
    required this.isDiamondCategory,
    this.initiallyExpanded = false,
  });

  @override
  State<_FaqItemCard> createState() => _FaqItemCardState();
}

class _FaqItemCardState extends State<_FaqItemCard> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDiamond = widget.isDiamondCategory;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF18182B).withValues(alpha: 0.94),
            const Color(0xFF10101E).withValues(alpha: 0.97),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? (isDiamond
                  ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                  : const Color(0xFFAB47BC).withValues(alpha: 0.5))
              : Colors.white.withValues(alpha: 0.08),
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: isDiamond
                      ? const Color(0xFFFF9800).withValues(alpha: 0.12)
                      : const Color(0xFFAB47BC).withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Icon Badge, Question Title, Chevron Arrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Left Icon Badge
                    _buildIconBadge(isDiamond),

                    const SizedBox(width: 14),

                    // Question Title
                    Expanded(
                      child: Text(
                        widget.faq.question ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Animated Chevron Icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded
                            ? (isDiamond
                                ? const Color(0xFFFFB300)
                                : const Color(0xFFCE93D8))
                            : Colors.white54,
                        size: 26,
                      ),
                    ),
                  ],
                ),

                // Expanded Answer Content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14, left: 2, right: 6),
                    child: Text(
                      widget.faq.answer ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Badge on Left of FAQ card:
  /// - Diamond card: Amber badge with glowing diamond
  /// - Payment card: Purple badge with wallet / card icon
  Widget _buildIconBadge(bool isDiamond) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDiamond
              ? [
                  const Color(0xFF382312),
                  const Color(0xFF241508),
                ]
              : [
                  const Color(0xFF281E48),
                  const Color(0xFF1A1232),
                ],
        ),
        border: Border.all(
          color: isDiamond
              ? const Color(0xFFFFB300).withValues(alpha: 0.5)
              : const Color(0xFFBA68C8).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDiamond
                ? const Color(0xFFFFB300).withValues(alpha: 0.2)
                : const Color(0xFFBA68C8).withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: isDiamond
            ? const Icon(
                Icons.diamond_rounded,
                color: Color(0xFFFFCA28),
                size: 22,
              )
            : const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFCE93D8),
                size: 20,
              ),
      ),
    );
  }
}
