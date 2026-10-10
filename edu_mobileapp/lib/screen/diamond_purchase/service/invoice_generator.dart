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
import 'package:geoedu/common/extensions/string_extension.dart';
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
        : '7113';

    final invoiceTitle = setting?.invoiceTitle?.trim().isNotEmpty == true
        ? setting!.invoiceTitle!.trim()
        : 'PRODUCT INVOICE';

    final prefix = setting?.invoicePrefix?.trim().isNotEmpty == true
        ? setting!.invoicePrefix!.trim()
        : 'GH001';

    final signatoryName =
        setting?.invoiceSignatoryName?.trim().isNotEmpty == true
            ? setting!.invoiceSignatoryName!.trim()
            : 'Authorized Signatory';

    final termsText = setting?.invoiceTermsText?.trim().isNotEmpty == true
        ? setting!.invoiceTermsText!.trim()
        : '';

    // 2. Load Company Logo (Admin uploaded network logo -> local asset fallback)
    pw.MemoryImage? logoImage;
    if (setting?.invoiceCompanyLogo?.trim().isNotEmpty == true) {
      final logoUrl = setting!.invoiceCompanyLogo!.trim().addBaseURL();
      logoImage = await _fetchImageBytes(logoUrl);
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
      final sigUrl = setting!.invoiceSignatureImage!.trim().addBaseURL();
      signatureImage = await _fetchImageBytes(sigUrl);
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
    final String productName = (transaction.productName?.trim().isNotEmpty == true)
        ? transaction.productName!.trim()
        : 'Jewellery Product';

    final String productId = (transaction.productId?.trim().isNotEmpty == true)
        ? transaction.productId!.trim()
        : ('DIA${(transaction.id ?? 1).toString().padLeft(3, '0')}');

    final double originalPrice = (transaction.productOriginalPrice != null &&
            transaction.productOriginalPrice! > 0)
        ? transaction.productOriginalPrice!
        : ((transaction.originalPrice != null &&
                transaction.originalPrice! >= netAmount)
            ? transaction.originalPrice!
            : netAmount);

    final double discountedPrice = (transaction.productDiscountedPrice != null &&
            transaction.productDiscountedPrice! > 0)
        ? transaction.productDiscountedPrice!
        : netAmount;

    final double discount = (transaction.discount != null && transaction.discount! > 0)
        ? transaction.discount!
        : ((originalPrice > discountedPrice) ? (originalPrice - discountedPrice) : 0.0);

    // Dynamic Making Charge, Handling Fee & Silver Jewel GST from Invoice Settings (DB)
    final double handlingFee = setting?.handlingFee ?? 0.0;
    final double makingChargePercent = setting?.makingChargePercent ?? 0.0;
    final double silverJewelGstPercent = setting?.silverJewelGstPercent ?? 0.0;

    final double makingChargeAmount = (makingChargePercent > 0)
        ? (discountedPrice * (makingChargePercent / 100.0))
        : 0.0;

    final double effectiveGstPercent = (silverJewelGstPercent > 0)
        ? silverJewelGstPercent
        : totalTaxRate;

    final double gstBase = discountedPrice + makingChargeAmount + handlingFee;
    final double gstAmount = (effectiveGstPercent > 0)
        ? (gstBase * (effectiveGstPercent / 100.0))
        : 0.0;

    // Final Amount
    final double finalAmount = (makingChargePercent > 0 || silverJewelGstPercent > 0 || handlingFee > 0)
        ? (discountedPrice + makingChargeAmount + handlingFee + gstAmount)
        : netAmount;

    // 5. Transaction Metadata
    final user = SessionManager.instance.getUser();
    final customerName = transaction.userName?.trim().isNotEmpty == true
        ? transaction.userName!
        : (user?.fullname?.trim().isNotEmpty == true
            ? user!.fullname!
            : (user?.username?.trim().isNotEmpty == true
                ? user!.username!
                : 'Customer'));

    final now = DateTime.now();
    final String dateTimeStr = transaction.createdAt?.trim().isNotEmpty == true
        ? transaction.createdAt!.trim()
        : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final String customerPhone = transaction.userPhone?.trim().isNotEmpty == true
        ? transaction.userPhone!
        : (user?.userMobileNo?.trim().isNotEmpty == true
            ? user!.userMobileNo!
            : '7550178929');
    final String companyPhone = setting?.invoicePhoneNumber?.trim() ?? '';
    final String companyEmail = setting?.invoiceCompanyEmail?.trim() ?? '';
    final String baseUrl = (setting?.itemBaseUrl?.trim().isNotEmpty == true)
        ? setting!.itemBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://geoedu.com';
    final String verificationUrl =
        '$baseUrl/verify-invoice/${transaction.id ?? 1}';

    // Dynamic Invoice Number (e.g. GH001/10-26)
    final finYear = '${now.year % 100}-${(now.year + 1) % 100}';
    final invoiceNumber =
        '$prefix/${now.month.toString().padLeft(2, '0')}-$finYear';

    final amountInWords = 'Rupees ${numberToWords(finalAmount)} Only';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header (Logo + Company Name on Left, GSTIN on Right)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 38,
                      width: 38,
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'GSTIN:',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        gstin,
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                height: 0.8,
                color: PdfColors.grey400,
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
              ),

              // 2. Centered Title
              pw.Center(
                child: pw.Text(
                  invoiceTitle,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // 3. Customer & Bill Info Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Mr./Ms : ',
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(customerName,
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Mobile No : ',
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(customerPhone,
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Bill No : ',
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(invoiceNumber,
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Bill Date / Time : ',
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(dateTimeStr,
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // 4. Product Details Table (Matching Pale Golden Header & Border Styling)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: pw.Column(
                  children: [
                    // Header Row
                    pw.Container(
                      color: PdfColor.fromHex('FDF4C5'),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 6,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                    right: pw.BorderSide(
                                        color: PdfColors.black, width: 0.8)),
                              ),
                              child: pw.Text(
                                'Product Details',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 5),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                    right: pw.BorderSide(
                                        color: PdfColors.black, width: 0.8)),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'Quantity',
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  'Amount',
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Item Row
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Expanded(
                          flex: 6,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                  right: pw.BorderSide(
                                      color: PdfColors.black, width: 0.8)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  productName,
                                  style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Product ID: $productId   |   HSN / SAC: $hsnCode',
                                  style: const pw.TextStyle(
                                      fontSize: 7.5,
                                      color: PdfColors.grey700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                  right: pw.BorderSide(
                                      color: PdfColors.black, width: 0.8)),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '1',
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                discountedPrice.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // 5. Right-Aligned Financial Breakdown
              pw.Row(
                children: [
                  pw.Spacer(),
                  pw.SizedBox(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _buildSummaryLine('Sub Total:',
                            discountedPrice.toStringAsFixed(2)),
                        if (makingChargeAmount > 0)
                          _buildSummaryLine(
                              'Making Charge (${makingChargePercent.toStringAsFixed(1)}%):',
                              makingChargeAmount.toStringAsFixed(2)),
                        if (handlingFee > 0)
                          _buildSummaryLine('Shipping / Handling Cost:',
                              handlingFee.toStringAsFixed(2)),
                        if (effectiveGstPercent > 0)
                          _buildSummaryLine(
                              'GST (${effectiveGstPercent.toStringAsFixed(1)}%):',
                              gstAmount.toStringAsFixed(2))
                        else
                          _buildSummaryLine('GST:', '0.00'),
                        _buildSummaryLine(
                            'Discount:', discount.toStringAsFixed(2)),
                        pw.Container(
                          height: 0.5,
                          color: PdfColors.grey400,
                          margin: const pw.EdgeInsets.symmetric(vertical: 2),
                        ),
                        _buildSummaryLine(
                            'Total:', finalAmount.toStringAsFixed(2),
                            isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // 6. Total in Words (Bracketed Italic)
              pw.Center(
                child: pw.Text(
                  '[$amountInWords]',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // 7. Signatory & QR Verification Code
              pw.Row(
                children: [
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (signatureImage != null)
                        pw.Container(
                          width: 100,
                          height: 28,
                          alignment: pw.Alignment.center,
                          child:
                              pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Text(
                          signatoryName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Authorized Signatory',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: verificationUrl,
                        width: 65,
                        height: 65,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Scan to re-open invoice',
                        style: const pw.TextStyle(
                            fontSize: 6.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // 8. Declaration & Dark Accent Bar
              pw.Text(
                'Declaration',
                style: pw.TextStyle(
                    fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                height: 3.5,
                color: PdfColor.fromHex('222222'),
                margin: const pw.EdgeInsets.symmetric(vertical: 3),
              ),
              pw.Text(
                termsText.isNotEmpty
                    ? termsText
                    : 'I have read, understood, and accept the terms and conditions mentioned above, the guidelines regarding quality specified at the backside of this invoice, were explained to me. The above jewels mentioned in the invoice are according to my specification and I purchased/sold the jewels at my own wish/need, after due verification. Hereby, indicating the acceptance for above terms & conditions, received the product in good condition, and doing the payment. I further acknowledge the amount stated is correct and accurate.',
                style:
                    const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
                textAlign: pw.TextAlign.justify,
              ),

              pw.Spacer(),

              // 9. Footer
              pw.Container(
                height: 0.5,
                color: PdfColors.grey400,
                margin: const pw.EdgeInsets.only(bottom: 4),
              ),
              if (companyAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    companyAddress,
                    style: const pw.TextStyle(
                        fontSize: 7.5, color: PdfColors.black),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  [
                    if (companyPhone.isNotEmpty) 'Phone: $companyPhone',
                    if (companyEmail.isNotEmpty) 'Email: $companyEmail',
                  ].join('   |   '),
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.black),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryLine(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
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
