import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/model/general/support_ticket_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportIssueController extends BaseController {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  static const String officialSupportEmail = 'geoeducation2026@gmail.com';

  static const List<String> availableCategories = [
    'Transaction / Payment Issue',
    'Diamonds Not Credited',
    'Refund & Duplicate Charge',
    'Tax Invoice & Billing',
    'Live Stream & Audio Call Issue',
    'Gifts & Entry Effects Issue',
    'Star Wallet & Host Payout',
    'Account & Login Issue',
    'App Bug / Technical Glitch',
    'General Inquiry & Feedback',
  ];

  final RxString selectedCategory = 'Transaction / Payment Issue'.obs;
  RxBool isLoading = false.obs;
  RxList<SupportTicket> myTickets = <SupportTicket>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyTickets();
  }

  @override
  void onClose() {
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  void setCategory(String category) {
    if (availableCategories.contains(category)) {
      selectedCategory.value = category;
    } else {
      selectedCategory.value = category;
    }
  }

  static String getEffectiveSupportEmail() {
    final rawMail = SessionManager.instance.getSettings()?.helpMail ?? '';
    if (rawMail.isEmpty ||
        rawMail.toLowerCase().contains('1236@') ||
        rawMail.toLowerCase().contains('goeducation') ||
        rawMail.toLowerCase().contains('geoedu.com')) {
      return officialSupportEmail;
    }
    return rawMail.trim();
  }

  Future<void> launchDirectEmail({
    String? txnId,
    String? amount,
    String? diamonds,
  }) async {
    final helpMail = getEffectiveSupportEmail();
    final category = selectedCategory.value;
    final sub = subjectController.text.trim();
    final subject = '[$category] ${sub.isNotEmpty ? sub : (txnId != null ? 'Txn #$txnId' : 'Support Request')}';

    final buffer = StringBuffer();
    buffer.writeln('Hello GeoEdu Support,');
    buffer.writeln();
    buffer.writeln('Issue Category: $category');
    if (txnId != null && txnId.isNotEmpty) {
      buffer.writeln('Transaction ID: $txnId');
    }
    if (diamonds != null && diamonds.isNotEmpty) {
      buffer.writeln('Diamonds: $diamonds');
    }
    if (amount != null && amount.isNotEmpty) {
      buffer.writeln('Amount: $amount');
    }
    buffer.writeln();
    final userMsg = messageController.text.trim();
    if (userMsg.isNotEmpty) {
      buffer.writeln('Details:\n$userMsg');
    } else {
      buffer.writeln('Details:\n');
    }

    final uri = Uri.parse(
        'mailto:$helpMail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(buffer.toString())}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> submitIssue() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty) {
      showSnackBar('Please enter a subject');
      return;
    }
    if (message.isEmpty) {
      showSnackBar('Please describe your issue');
      return;
    }

    // Attach category tag to subject so admin and ticket records clearly display it
    final category = selectedCategory.value;
    String finalSubject = subject;
    if (!finalSubject.toLowerCase().contains(category.toLowerCase())) {
      finalSubject = '[$category] $subject';
    }

    showLoader();
    try {
      StatusModel result = await CommonService.instance.createSupport(
        subject: finalSubject,
        message: message,
      );
      stopLoader();
      if (result.status == true) {
        showSnackBar(result.message ?? 'Issue submitted successfully');
        subjectController.clear();
        messageController.clear();
        fetchMyTickets();
      } else {
        showSnackBar(result.message ?? 'Failed to submit issue');
      }
    } catch (e) {
      stopLoader();
      showSnackBar('Something went wrong. Please try again.');
    }
  }

  Future<void> fetchMyTickets() async {
    isLoading.value = true;
    try {
      SupportTicketModel result =
          await CommonService.instance.fetchMySupports();
      myTickets.value = result.data ?? [];
    } catch (_) {}
    isLoading.value = false;
  }
}
