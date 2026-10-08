import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/model/general/support_ticket_model.dart';
import 'package:geoedu/screen/help_and_support/report_issue/report_issue_controller.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class ReportIssueScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSubject;
  final String? initialMessage;
  final String? txnId;
  final String? amountStr;
  final String? diamondsStr;

  const ReportIssueScreen({
    super.key,
    this.initialCategory,
    this.initialSubject,
    this.initialMessage,
    this.txnId,
    this.amountStr,
    this.diamondsStr,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  late final ReportIssueController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReportIssueController());

    if (widget.initialCategory != null &&
        widget.initialCategory!.trim().isNotEmpty) {
      controller.setCategory(widget.initialCategory!.trim());
    }

    if (widget.initialSubject != null &&
        widget.initialSubject!.trim().isNotEmpty) {
      controller.subjectController.text = widget.initialSubject!.trim();
    }

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      controller.messageController.text = widget.initialMessage!.trim();
    }
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('diamond')) return Icons.diamond_rounded;
    if (lower.contains('refund')) return Icons.currency_exchange_rounded;
    if (lower.contains('invoice') || lower.contains('billing')) {
      return Icons.receipt_long_rounded;
    }
    if (lower.contains('live') || lower.contains('audio')) {
      return Icons.live_tv_rounded;
    }
    if (lower.contains('gift') || lower.contains('effect')) {
      return Icons.card_giftcard_rounded;
    }
    if (lower.contains('star') || lower.contains('payout')) {
      return Icons.star_rounded;
    }
    if (lower.contains('account') || lower.contains('login')) {
      return Icons.person_rounded;
    }
    if (lower.contains('bug') || lower.contains('technical')) {
      return Icons.bug_report_rounded;
    }
    if (lower.contains('inquiry') || lower.contains('feedback')) {
      return Icons.help_outline_rounded;
    }
    return Icons.payment_rounded;
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('diamond')) return const Color(0xFFFFB300);
    if (lower.contains('refund')) return const Color(0xFFE91E63);
    if (lower.contains('invoice') || lower.contains('billing')) {
      return const Color(0xFF00BCD4);
    }
    if (lower.contains('live') || lower.contains('audio')) {
      return const Color(0xFFAB47BC);
    }
    if (lower.contains('gift') || lower.contains('effect')) {
      return const Color(0xFFFF7043);
    }
    if (lower.contains('star') || lower.contains('payout')) {
      return const Color(0xFFFFCA28);
    }
    if (lower.contains('account') || lower.contains('login')) {
      return const Color(0xFF4CAF50);
    }
    if (lower.contains('bug') || lower.contains('technical')) {
      return const Color(0xFFEF5350);
    }
    if (lower.contains('inquiry') || lower.contains('feedback')) {
      return const Color(0xFF90A4AE);
    }
    return const Color(0xFF29B6F6);
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                'Select Issue Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the category that best describes your problem',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ReportIssueController.availableCategories.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final cat =
                        ReportIssueController.availableCategories[index];
                    return Obx(() {
                      final isSelected =
                          controller.selectedCategory.value == cat;
                      final color = _getCategoryColor(cat);
                      final icon = _getCategoryIcon(cat);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        title: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14.5,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF4CAF50), size: 22)
                            : const Icon(Icons.circle_outlined,
                                color: Colors.white24, size: 20),
                        onTap: () {
                          controller.setCategory(cat);
                          Navigator.pop(ctx);
                        },
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportEmail = ReportIssueController.getEffectiveSupportEmail();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: kSecondaryHeaderGradient),
            ),
          ),
          Column(
            children: [
              const CustomAppBar(
                title: "Report Issue",
                iconColor: Colors.white,
                centertitle: false,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Official Support Email Info Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300)
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mail_outline_rounded,
                                  color: Color(0xFFFFB300), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Support Email',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 11),
                                  ),
                                  Text(
                                    supportEmail,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => controller.launchDirectEmail(
                                  txnId: widget.txnId,
                                  amount: widget.amountStr,
                                  diamonds: widget.diamondsStr,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF2196F3)
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.send_rounded,
                                          color: Color(0xFF90CAF9), size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'Email Us',
                                        style: TextStyle(
                                          color: Color(0xFF90CAF9),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Issue Category Label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Issue Category',
                            style: TextStyleCustom.outFitMedium500(
                              color: whitePure(context),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCategoryBottomSheet(context),
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: Color(0xFF64B5F6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Issue Category Selected Card
                      Obx(() {
                        final currentCat = controller.selectedCategory.value;
                        final color = _getCategoryColor(currentCat);
                        final icon = _getCategoryIcon(currentCat);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showCategoryBottomSheet(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentCat,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Tap to choose another category',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down_circle_outlined,
                                    color: Colors.white60,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // Horizontal Quick Chips for fast category switching
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildQuickChip('Transaction / Payment Issue'),
                            _buildQuickChip('Diamonds Not Credited'),
                            _buildQuickChip('Refund & Duplicate Charge'),
                            _buildQuickChip('Live Stream & Audio Call Issue'),
                            _buildQuickChip('Gifts & Entry Effects Issue'),
                            _buildQuickChip('Account & Login Issue'),
                            _buildQuickChip('App Bug / Technical Glitch'),
                            _buildQuickChip('General Inquiry & Feedback'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Subject Field
                      Text(
                        'Subject',
                        style: TextStyleCustom.outFitMedium500(
                          color: whitePure(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: controller.subjectController,
                          style: TextStyleCustom.outFitRegular400(
                            color: whitePure(context),
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            hintText: 'Enter subject',
                            hintStyle: TextStyleCustom.outFitLight300(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Describe Issue Field
                      Text(
                        'Describe your issue',
                        style: TextStyleCustom.outFitMedium500(
                          color: whitePure(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: controller.messageController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyleCustom.outFitRegular400(
                            color: whitePure(context),
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            hintText: 'Type your issue here...',
                            hintStyle: TextStyleCustom.outFitLight300(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Ticket Button
                      GestureDetector(
                        onTap: controller.submitIssue,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF477d8d), Color(0xFF214f86)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Submit Ticket',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Or Direct Email Button
                      GestureDetector(
                        onTap: () => controller.launchDirectEmail(
                          txnId: widget.txnId,
                          amount: widget.amountStr,
                          diamonds: widget.diamondsStr,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email_outlined,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Email Directly ($supportEmail)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // My Tickets Title
                      Text(
                        'My Tickets',
                        style: TextStyleCustom.outFitMedium500(
                          color: whitePure(context),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tickets list
                      Obx(() {
                        if (controller.isLoading.value &&
                            controller.myTickets.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 30),
                            child: LoaderWidget(),
                          );
                        }
                        if (controller.myTickets.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Center(
                              child: Text(
                                'No tickets yet',
                                style: TextStyleCustom.outFitLight300(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.myTickets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _TicketCard(
                              ticket: controller.myTickets[index],
                              getCategoryColor: _getCategoryColor,
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String category) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == category;
      final color = _getCategoryColor(category);

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => controller.setCategory(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.25) : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.white.withOpacity(0.12),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final Color Function(String) getCategoryColor;

  const _TicketCard({
    required this.ticket,
    required this.getCategoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final rawSubject = ticket.subject ?? '';
    String categoryName = '';
    String displaySubject = rawSubject;

    if (rawSubject.startsWith('[') && rawSubject.contains(']')) {
      final endIdx = rawSubject.indexOf(']');
      categoryName = rawSubject.substring(1, endIdx);
      displaySubject = rawSubject.substring(endIdx + 1).trim();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: getCategoryColor(categoryName)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: getCategoryColor(categoryName)
                                .withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: getCategoryColor(categoryName),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      displaySubject.isNotEmpty ? displaySubject : rawSubject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: ticket.status ?? 'pending'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (ticket.adminReply != null &&
              ticket.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF477d8d).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Reply',
                    style: TextStyle(
                      color: Color(0xFF7dd3a8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.adminReply!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ticket.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              ticket.createdAt!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'answered':
        bgColor = const Color(0xFF2ecc71).withOpacity(0.2);
        textColor = const Color(0xFF2ecc71);
        break;
      case 'in_progress':
        bgColor = const Color(0xFFf39c12).withOpacity(0.2);
        textColor = const Color(0xFFf39c12);
        break;
      default:
        bgColor = Colors.white.withOpacity(0.15);
        textColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').capitalize ?? status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
