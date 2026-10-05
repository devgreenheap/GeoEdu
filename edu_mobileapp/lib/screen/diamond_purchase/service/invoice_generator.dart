import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/utilities/asset_res.dart';

class InvoiceGenerator {
  static const String companyName = 'Greenheap DigiEdu Private Limited';
  static const String companyAddress =
      'No 1090n, Sector 3, 18th Cross Road,\nBengaluru Urban, Karnataka, 560102';
  static const String gstin = '29AAGCG1234F1Z5';
  static const String hsnCode = '998439';

  /// Converts a number to words in Indian English currency format
  static String numberToWords(num amount) {
    final int val = amount.round();
    if (val == 0) return 'Zero';

    final List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    final List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convertChunk(int n) {
      String str = '';
      if (n >= 100) {
        str += '${units[n ~/ 100]} Hundred ';
        n %= 100;
      }
      if (n >= 20) {
        str += '${tens[n ~/ 10]} ';
        n %= 10;
      }
      if (n > 0) {
        str += '${units[n]} ';
      }
      return str.trim();
    }

    String result = '';
    int crore = val ~/ 10000000;
    int rem = val % 10000000;
    int lakh = rem ~/ 100000;
    rem %= 100000;
    int thousand = rem ~/ 1000;
    rem %= 1000;

    if (crore > 0) {
      result += '${convertChunk(crore)} Crore ';
    }
    if (lakh > 0) {
      result += '${convertChunk(lakh)} Lakh ';
    }
    if (thousand > 0) {
      result += '${convertChunk(thousand)} Thousand ';
    }
    if (rem > 0) {
      result += '${convertChunk(rem)} ';
    }

    return result.trim();
  }

  /// Builds the Tax Invoice PDF document exactly matching the reference template
  static Future<Uint8List> generateInvoicePdf(
      DiamondTransactionModel transaction) async {
    final pdf = pw.Document();

    // Load App Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load(AssetRes.appLogo);
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Calculation values
    final netAmount = transaction.amount ?? 0.0;
    final originalPrice = (transaction.originalPrice != null &&
            transaction.originalPrice! >= netAmount)
        ? transaction.originalPrice!
        : netAmount;
    final discount = (transaction.discount != null && transaction.discount! > 0)
        ? transaction.discount!
        : (originalPrice > netAmount ? (originalPrice - netAmount) : 0.0);

    final taxableValue =
        netAmount > 0 ? (netAmount / 1.18) : 0.0;
    final igst = netAmount - taxableValue;

    // Real-time metadata
    final user = SessionManager.instance.getUser();
    final customerName = transaction.userName?.trim().isNotEmpty == true
        ? transaction.userName!
        : (user?.fullname?.trim().isNotEmpty == true
            ? user!.fullname!
            : (user?.username?.trim().isNotEmpty == true
                ? user!.username!
                : 'GeoEdu User'));

    final txnId = transaction.paymentId?.trim().isNotEmpty == true
        ? transaction.paymentId!
        : (transaction.transactionId?.trim().isNotEmpty == true
            ? transaction.transactionId!
            : 'TXN${transaction.id ?? 1001}');

    final dateTimeStr = transaction.createdAt?.trim().isNotEmpty == true
        ? transaction.createdAt!.replaceAll(' ', '; ')
        : (transaction.dateTime != null
            ? '${transaction.dateTime!.year}-${transaction.dateTime!.month.toString().padLeft(2, '0')}-${transaction.dateTime!.day.toString().padLeft(2, '0')}; ${transaction.time ?? ''}'
            : '${transaction.date ?? ''}; ${transaction.time ?? ''}');

    final paymentMode = transaction.paymentMode ?? 'UPI';
    final placeOfSupply = transaction.placeOfSupply ?? 'Tamil Nadu, India';

    // Invoice Number
    final now = DateTime.now();
    final finYear = '${now.year}-${now.year + 1}';
    final invoiceNumber =
        'GEO/$finYear/${now.month}/${transaction.id ?? 18620978}';

    final amountInWords =
        'Rupees ${numberToWords(netAmount)} Only';

    final headerGrey = PdfColor.fromHex('D6D6D6');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Centered Title: "Tax Invoice"
              pw.Center(
                child: pw.Text(
                  'Tax Invoice',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // 2. Top Right Company Details & Logo
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Logo & App Name
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 36,
                              height: 36,
                              margin: const pw.EdgeInsets.only(right: 8),
                              child: pw.Image(logoImage),
                            ),
                          pw.Text(
                            'GeoEdu',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        companyAddress,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'GSTIN: $gstin',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'HSN Code: $hsnCode',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Invoice #: $invoiceNumber',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 3. Customer & Transaction Details
              pw.SizedBox(
                width: 340,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow('Name', customerName),
                    pw.SizedBox(height: 8),
                    _buildMetaRow('Transaction Date &\nTime', dateTimeStr),
                    pw.SizedBox(height: 8),
                    _buildMetaRow('Transaction ID #', txnId),
                    pw.SizedBox(height: 8),
                    _buildMetaRow('Mode of Payment', paymentMode),
                    pw.SizedBox(height: 8),
                    _buildMetaRow('Place of Supply', placeOfSupply),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // 4. Line Items Table (Matches template layout)
              // Header row
              pw.Container(
                color: headerGrey,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Rows
              _buildTableRow(
                  'Diamonds Purchase', 'Rs.${originalPrice.toStringAsFixed(1)}'),
              _buildTableRow(
                  'Discount', 'Rs.${discount.toStringAsFixed(1)}'),
              _buildTableRow(
                'Net Amount towards purchase (Inclusive of GST)',
                'Rs.${netAmount.toStringAsFixed(1)}',
                isBold: true,
              ),
              _buildTableRow(
                  'Total Taxable Value - Diamonds Purchase*',
                  'Rs.${taxableValue.toStringAsFixed(2)}'),
              _buildTableRow('SGST (0.0%)', 'Rs.0.0'),
              _buildTableRow('CGST (0.0%)', 'Rs.0.0'),
              _buildTableRow(
                  'IGST (18.0%)', 'Rs.${igst.toStringAsFixed(2)}'),
              _buildTableRow(
                'Grand Total\nRounded Off*',
                'Rs.${netAmount.toStringAsFixed(1)}',
                isBold: true,
              ),

              // Total in words row
              pw.Container(
                color: headerGrey,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Text(
                        'Total Amount (In words)',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        amountInWords,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 36),

              // 5. Authorised Signatory Section
              pw.Row(
                children: [
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'For $companyName',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 14),
                      // Stylized signature
                      pw.Container(
                        width: 90,
                        height: 24,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'GeoEdu Auth',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 120,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorised Signatory',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // 6. Footer Notes
              pw.Text(
                'Refer to geoedu.com/terms for Policy, Terms & Conditions.',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Tax payable on reverse charge - No.',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '*In case of inter-state supply IGST will be applicable. Within state supplies are liable for CGST & SGST.',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9.5,
              color: PdfColors.black,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableRow(String title, String amount,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Downloads or shares the PDF file using the system share/save sheet
  static Future<void> downloadInvoice(
      BuildContext context, DiamondTransactionModel transaction) async {
    try {
      final pdfBytes = await generateInvoicePdf(transaction);
      final filename =
          'Tax_Invoice_${transaction.paymentId ?? transaction.transactionId ?? transaction.id}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
