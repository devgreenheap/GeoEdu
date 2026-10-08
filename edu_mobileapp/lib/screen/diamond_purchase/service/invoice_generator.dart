import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/utilities/asset_res.dart';

class InvoiceGenerator {
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

  /// Helper to safely load remote image bytes
  static Future<pw.MemoryImage?> _fetchImageBytes(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (bytes.isNotEmpty) {
          return pw.MemoryImage(bytes);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Builds the Tax Invoice PDF document dynamically configured from Admin Panel
  static Future<Uint8List> generateInvoicePdf(
      DiamondTransactionModel transaction) async {
    final pdf = pw.Document();
    final setting = SessionManager.instance.getSettings();

    // 1. Dynamic Company & Invoice Configurations
    final companyName = setting?.invoiceCompanyName?.trim().isNotEmpty == true
        ? setting!.invoiceCompanyName!.trim()
        : 'Greenheap DigiEdu Private Limited';

    final companyAddress =
        setting?.invoiceCompanyAddress?.trim().isNotEmpty == true
            ? setting!.invoiceCompanyAddress!.trim()
            : 'No 1090n, Sector 3, 18th Cross Road,\nBengaluru Urban, Karnataka, 560102';

    final gstin = setting?.invoiceGstin?.trim().isNotEmpty == true
        ? setting!.invoiceGstin!.trim()
        : '29AAGCG1234F1Z5';

    final hsnCode = setting?.invoiceHsnCode?.trim().isNotEmpty == true
        ? setting!.invoiceHsnCode!.trim()
        : '998439';

    final invoiceTitle = setting?.invoiceTitle?.trim().isNotEmpty == true
        ? setting!.invoiceTitle!.trim()
        : 'Tax Invoice';

    final prefix = setting?.invoicePrefix?.trim().isNotEmpty == true
        ? setting!.invoicePrefix!.trim()
        : 'GEO';

    final currency = setting?.invoiceCurrency?.trim().isNotEmpty == true
        ? setting!.invoiceCurrency!.trim()
        : 'Rs.';

    final signatoryName =
        setting?.invoiceSignatoryName?.trim().isNotEmpty == true
            ? setting!.invoiceSignatoryName!.trim()
            : 'GeoEdu Auth';

    final termsText = setting?.invoiceTermsText?.trim().isNotEmpty == true
        ? setting!.invoiceTermsText!.trim()
        : 'Refer to geoedu.com/terms for Policy, Terms & Conditions.';

    final footerText = setting?.invoiceFooterText?.trim().isNotEmpty == true
        ? setting!.invoiceFooterText!.trim()
        : "Tax payable on reverse charge - No.\n*In case of inter-state supply IGST will be applicable. Within state supplies are liable for CGST & SGST.";

    final defaultPlaceOfSupply =
        setting?.invoicePlaceOfSupply?.trim().isNotEmpty == true
            ? setting!.invoicePlaceOfSupply!.trim()
            : 'Tamil Nadu, India';

    // 2. Load Company Logo (Admin uploaded network logo -> local asset fallback)
    pw.MemoryImage? logoImage;
    if (setting?.invoiceCompanyLogo?.trim().isNotEmpty == true) {
      logoImage = await _fetchImageBytes(setting!.invoiceCompanyLogo!.trim());
    }
    if (logoImage == null) {
      try {
        final logoBytes = await rootBundle.load(AssetRes.appLogo);
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}
    }

    // 3. Load Authorized Signature Image (if configured)
    pw.MemoryImage? signatureImage;
    if (setting?.invoiceSignatureImage?.trim().isNotEmpty == true) {
      signatureImage =
          await _fetchImageBytes(setting!.invoiceSignatureImage!.trim());
    }

    // 4. Tax Configuration & Mathematical Calculation
    final bool sgstEnabled = (setting?.invoiceSgstEnabled ?? 0) == 1;
    final double sgstPercent = setting?.invoiceSgstPercent ?? 0.0;

    final bool cgstEnabled = (setting?.invoiceCgstEnabled ?? 0) == 1;
    final double cgstPercent = setting?.invoiceCgstPercent ?? 0.0;

    final bool igstEnabled = (setting?.invoiceIgstEnabled ?? 1) == 1;
    final double igstPercent = setting?.invoiceIgstPercent ?? 18.0;

    final double effectiveSgstRate = sgstEnabled ? sgstPercent : 0.0;
    final double effectiveCgstRate = cgstEnabled ? cgstPercent : 0.0;
    final double effectiveIgstRate = igstEnabled ? igstPercent : 0.0;
    final double totalTaxRate =
        effectiveSgstRate + effectiveCgstRate + effectiveIgstRate;

    final double netAmount = transaction.amount ?? 0.0;
    final double originalPrice = (transaction.originalPrice != null &&
            transaction.originalPrice! >= netAmount)
        ? transaction.originalPrice!
        : netAmount;
    final double discount =
        (transaction.discount != null && transaction.discount! > 0)
            ? transaction.discount!
            : (originalPrice > netAmount ? (originalPrice - netAmount) : 0.0);

    // Taxable Value
    final double taxableValue = (netAmount > 0 && totalTaxRate > 0)
        ? (netAmount / (1.0 + (totalTaxRate / 100.0)))
        : netAmount;

    // Individual Tax Amounts
    final double sgstAmount =
        sgstEnabled ? (taxableValue * (sgstPercent / 100.0)) : 0.0;
    final double cgstAmount =
        cgstEnabled ? (taxableValue * (cgstPercent / 100.0)) : 0.0;
    final double igstAmount =
        igstEnabled ? (taxableValue * (igstPercent / 100.0)) : 0.0;

    // 5. Transaction Metadata
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

    final paymentMode = transaction.paymentMode ?? 'Online / Razorpay';
    final placeOfSupply = transaction.placeOfSupply?.trim().isNotEmpty == true
        ? transaction.placeOfSupply!
        : defaultPlaceOfSupply;

    // Dynamic Invoice Number
    final now = DateTime.now();
    final finYear = '${now.year}-${now.year + 1}';
    final invoiceNumber =
        '$prefix/$finYear/${now.month}/${transaction.id ?? 18620978}';

    final amountInWords = 'Rupees ${numberToWords(netAmount)} Only';
    final headerGrey = PdfColor.fromHex('D6D6D6');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Centered Title
              pw.Center(
                child: pw.Text(
                  invoiceTitle,
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
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Text(
                            setting?.appName ?? 'GeoEdu',
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
                      pw.SizedBox(
                        width: 220,
                        child: pw.Text(
                          companyAddress,
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.black,
                          ),
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
                  'Diamonds Purchase', '$currency${originalPrice.toStringAsFixed(1)}'),
              _buildTableRow(
                  'Discount', '$currency${discount.toStringAsFixed(1)}'),
              _buildTableRow(
                'Net Amount towards purchase (Inclusive of GST)',
                '$currency${netAmount.toStringAsFixed(1)}',
                isBold: true,
              ),
              _buildTableRow(
                  'Total Taxable Value - Diamonds Purchase*',
                  '$currency${taxableValue.toStringAsFixed(2)}'),

              // Dynamic Tax Rows: Only displayed if enabled by Admin
              if (sgstEnabled)
                _buildTableRow('SGST (${sgstPercent.toStringAsFixed(1)}%)',
                    '$currency${sgstAmount.toStringAsFixed(2)}'),
              if (cgstEnabled)
                _buildTableRow('CGST (${cgstPercent.toStringAsFixed(1)}%)',
                    '$currency${cgstAmount.toStringAsFixed(2)}'),
              if (igstEnabled)
                _buildTableRow('IGST (${igstPercent.toStringAsFixed(1)}%)',
                    '$currency${igstAmount.toStringAsFixed(2)}'),

              _buildTableRow(
                'Grand Total\nRounded Off*',
                '$currency${netAmount.toStringAsFixed(1)}',
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
                      pw.SizedBox(height: 10),
                      // Dynamic Signature Image or Stylized Text Fallback
                      if (signatureImage != null)
                        pw.Container(
                          width: 120,
                          height: 36,
                          alignment: pw.Alignment.center,
                          child: pw.Image(signatureImage,
                              fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 120,
                          height: 24,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            signatoryName,
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

              // 6. Dynamic Footer Notes
              if (termsText.isNotEmpty) ...[
                pw.Text(
                  termsText,
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
              ],
              if (footerText.isNotEmpty)
                pw.Text(
                  footerText,
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
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes, flush: true);

      Rect? sharePositionOrigin;
      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
        }
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: filename)],
          subject: 'Tax Invoice',
          text: 'Tax Invoice for GeoEdu Diamond Purchase',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      try {
        final pdfBytes = await generateInvoicePdf(transaction);
        final filename =
            'Tax_Invoice_${transaction.paymentId ?? transaction.transactionId ?? transaction.id}.pdf';
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share invoice: $e2'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
