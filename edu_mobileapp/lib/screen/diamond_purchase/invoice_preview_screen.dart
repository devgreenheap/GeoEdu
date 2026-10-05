import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/screen/diamond_purchase/service/invoice_generator.dart';
import 'package:geoedu/utilities/color_res.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final DiamondTransactionModel transaction;

  const InvoicePreviewScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1015),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: kSecondaryHeaderGradient),
            ),
          ),
          Column(
            children: [
              const CustomAppBar(
                title: 'Tax Invoice',
                iconColor: ColorRes.whitePure,
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) =>
                      InvoiceGenerator.generateInvoicePdf(transaction),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  dynamicLayout: false,
                  allowPrinting: true,
                  allowSharing: true,
                  pdfFileName:
                      'Tax_Invoice_${transaction.paymentId ?? transaction.transactionId ?? transaction.id}.pdf',
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                    ),
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
