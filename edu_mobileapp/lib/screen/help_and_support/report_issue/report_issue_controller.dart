import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/model/general/support_ticket_model.dart';

class ReportIssueController extends BaseController {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

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

    showLoader();
    try {
      StatusModel result = await CommonService.instance.createSupport(
        subject: subject,
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
