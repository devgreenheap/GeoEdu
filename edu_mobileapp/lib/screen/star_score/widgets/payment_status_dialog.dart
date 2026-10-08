import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/screen/diamond_purchase/invoice_preview_screen.dart';
import 'package:geoedu/screen/diamond_purchase/service/invoice_generator.dart';
import 'package:geoedu/utilities/color_res.dart';

class PaymentAudioPlayer {
  static AudioPlayer? _player;

  static Future<void> playSuccess() async {
    try {
      _player ??= AudioPlayer();
      await _player?.stop();
      try {
        await _player?.setAsset('assets/payment audio/success.mp3');
      } catch (_) {
        await _player?.setAsset('assets/audios/payment_success.mp3');
      }
      await _player?.play();
    } catch (e) {
      Loggers.error('PaymentAudioPlayer playSuccess error: $e');
    }
  }

  static Future<void> playFail() async {
    try {
      _player ??= AudioPlayer();
      await _player?.stop();
      try {
        await _player?.setAsset('assets/payment audio/fail.mp3');
      } catch (_) {
        await _player?.setAsset('assets/audios/payment_fail.mp3');
      }
      await _player?.play();
    } catch (e) {
      Loggers.error('PaymentAudioPlayer playFail error: $e');
    }
  }
}

class PaymentStatusDialog extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String diamonds;
  final double amount;
  final String transactionId;
  final DateTime paymentTime;
  final VoidCallback? onDone;
  final DiamondTransactionModel? transaction;

  const PaymentStatusDialog({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    this.diamonds = '',
    this.amount = 0.0,
    required this.transactionId,
    required this.paymentTime,
    this.onDone,
    this.transaction,
  });

  static Future<void> showSuccess({
    required String diamonds,
    required double amount,
    required String transactionId,
    DateTime? paymentTime,
    VoidCallback? onDone,
    DiamondTransactionModel? transaction,
  }) async {
    PaymentAudioPlayer.playSuccess();
    await Get.dialog(
      PaymentStatusDialog(
        isSuccess: true,
        title: 'Payment Successful',
        message: '$diamonds Diamonds have been added to your account',
        diamonds: diamonds,
        amount: amount,
        transactionId: transactionId,
        paymentTime: paymentTime ?? DateTime.now(),
        onDone: onDone,
        transaction: transaction,
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> showFailure({
    required String message,
    String? transactionId,
    DateTime? paymentTime,
    VoidCallback? onDone,
  }) async {
    PaymentAudioPlayer.playFail();
    await Get.dialog(
      PaymentStatusDialog(
        isSuccess: false,
        title: 'Payment Failed',
        message: message,
        transactionId: transactionId ?? 'N/A',
        paymentTime: paymentTime ?? DateTime.now(),
        onDone: onDone,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm:ss a');
    final formattedDate = dateFormat.format(paymentTime);

    final primaryColor = isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final secondaryGlow = isSuccess
        ? const Color(0xFF00E676).withValues(alpha: 0.22)
        : const Color(0xFFFF5252).withValues(alpha: 0.22);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: secondaryGlow,
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge with Glow
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isSuccess
                          ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                          : [const Color(0xFFFF5252), const Color(0xFFFF7043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isSuccess ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSuccess ? Colors.white : const Color(0xFFFF8A80),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle / message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 20),

                // Diamonds & Amount Highlight Card (for success)
                if (isSuccess && diamonds.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD700).withValues(alpha: 0.15),
                          const Color(0xFF00E676).withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/yellow-dimond.png',
                          height: 28,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.diamond_rounded,
                            color: Color(0xFFFFD700),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+$diamonds Diamonds',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (amount > 0)
                              Text(
                                'Amount Paid: ₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Receipt Breakdown Table
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Transaction ID Row
                      _buildReceiptRow(
                        context,
                        label: 'Transaction ID',
                        value: _cleanTransactionId(transactionId),
                        showCopy: _isValidTransactionId(transactionId),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.white12, height: 1),
                      ),

                      // Exact Payment Time Row
                      _buildReceiptRow(
                        context,
                        label: 'Payment Time',
                        value: formattedDate,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.white12, height: 1),
                      ),

                      // Status Pill Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isSuccess ? 'Success' : 'Failed',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Download Invoice Button (Success only: below transaction details, above Done button)
                if (isSuccess) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF00E676).withValues(alpha: 0.6),
                          width: 1.3,
                        ),
                        backgroundColor:
                            const Color(0xFF00E676).withValues(alpha: 0.08),
                        foregroundColor: const Color(0xFF00E676),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF00E676),
                        size: 20,
                      ),
                      label: const Text(
                        'Download Invoice',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E676),
                          letterSpacing: 0.2,
                        ),
                      ),
                      onPressed: () => _showInvoiceOptions(context),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess
                          ? const Color(0xFF00E676)
                          : ColorRes.primaryColor,
                      foregroundColor: isSuccess ? Colors.black : Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      onDone?.call();
                    },
                    child: Text(
                      isSuccess ? 'Done' : 'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isSuccess ? const Color(0xFF0C1B10) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DiamondTransactionModel _resolveTransaction() {
    if (transaction != null) return transaction!;
    final user = SessionManager.instance.getUser();
    final cleanTxnId = _cleanTransactionId(transactionId);
    final count = int.tryParse(diamonds.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return DiamondTransactionModel(
      title: diamonds.isNotEmpty ? '$diamonds Diamonds' : 'Diamond Purchase',
      diamonds: count,
      amount: amount,
      originalPrice: amount,
      discount: 0.0,
      currency: 'INR',
      transactionId: cleanTxnId,
      paymentId: cleanTxnId,
      dateTime: paymentTime,
      date: DateFormat('dd/MM/yy').format(paymentTime),
      time: DateFormat('hh:mm a').format(paymentTime),
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(paymentTime),
      status: isSuccess ? 'SUCCESS' : 'FAILED',
      paymentMode: 'Online / Razorpay',
      placeOfSupply: 'Tamil Nadu, India',
      userName: user?.fullname ?? user?.username ?? 'GeoEdu User',
      userPhone: user?.userMobileNo,
      userEmail: user?.userEmail ?? user?.identity,
    );
  }

  void _showInvoiceOptions(BuildContext context) {
    final purchase = _resolveTransaction();
    final txnId = purchase.paymentId ?? purchase.transactionId ?? 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.download_rounded,
                    color: Color(0xFF00E676)),
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
      ),
    );
  }

  static String _cleanTransactionId(String? id) {
    if (id == null ||
        id.isEmpty ||
        id == 'N/A' ||
        id == 'Not Generated' ||
        id.startsWith('{') ||
        id.toLowerCase().contains('reason') ||
        id.toLowerCase().contains('payment_error') ||
        id.toLowerCase().contains('code_')) {
      return 'Not Generated';
    }
    return id;
  }

  static bool _isValidTransactionId(String? id) {
    final clean = _cleanTransactionId(id);
    return clean != 'Not Generated' && clean != 'N/A';
  }

  Widget _buildReceiptRow(
    BuildContext context, {
    required String label,
    required String value,
    bool showCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showCopy) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    HapticFeedback.lightImpact();
                    Get.showSnackbar(
                      const GetSnackBar(
                        message: 'Copied to clipboard',
                        duration: Duration(seconds: 1),
                        snackPosition: SnackPosition.BOTTOM,
                        margin: EdgeInsets.all(12),
                        borderRadius: 8,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.copy_rounded,
                      color: Colors.white54,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
