import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/model/diamond_purchase/diamond_purchase_model.dart';
import 'package:geoedu/screen/diamond_purchase/service/invoice_generator.dart';
import 'package:geoedu/utilities/color_res.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final DiamondTransactionModel transaction;

  const InvoicePreviewScreen({super.key, required this.transaction});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late final TransformationController _transformationController;
  Offset? _doubleTapPosition;
  bool _isPrinting = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(() {
      if (mounted) setState(() {});
    });
    CommonService.instance.fetchGlobalSettings().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double get _currentScale =>
      _transformationController.value.getMaxScaleOnAxis();

  String get _zoomPercentage => '${(_currentScale * 100).round()}%';

  void _zoomIn() {
    final target = (_currentScale + 0.5).clamp(1.0, 4.0);
    _transformationController.value = Matrix4.identity()..scale(target);
  }

  void _zoomOut() {
    final target = (_currentScale - 0.5).clamp(1.0, 4.0);
    _transformationController.value = Matrix4.identity()..scale(target);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  String get _cleanTxnId =>
      widget.transaction.paymentId ??
      widget.transaction.transactionId ??
      '${widget.transaction.id ?? 1001}';

  String get _pdfFileName => 'Tax_Invoice_$_cleanTxnId.pdf';

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back();
    }
  }

  Future<void> _handlePrint() async {
    if (_isPrinting || _isSharing) return;
    setState(() => _isPrinting = true);
    try {
      final pdfBytes =
          await InvoiceGenerator.generateInvoicePdf(widget.transaction);
      await Printing.layoutPdf(
        name: 'Tax_Invoice_$_cleanTxnId',
        onLayout: (PdfPageFormat format) async => pdfBytes,
        dynamicLayout: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Printing failed: $e. You can use the Share button to save/print the PDF.',
            ),
            backgroundColor: Colors.orange.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isPrinting || _isSharing) return;
    setState(() => _isSharing = true);
    try {
      final pdfBytes =
          await InvoiceGenerator.generateInvoicePdf(widget.transaction);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$_pdfFileName');
      await file.writeAsBytes(pdfBytes, flush: true);

      Rect? sharePositionOrigin;
      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
        }
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: 'application/pdf', name: _pdfFileName)
          ],
          subject: 'Tax Invoice - $_cleanTxnId',
          text: 'Tax Invoice for GeoEdu Purchase ($_cleanTxnId)',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      // Fallback to Printing.sharePdf
      try {
        final pdfBytes =
            await InvoiceGenerator.generateInvoicePdf(widget.transaction);
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: _pdfFileName,
        );
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share invoice: $e2'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          _handleBack();
        }
      },
      child: Scaffold(
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
                CustomAppBar(
                  title: 'Tax Invoice',
                  iconColor: ColorRes.whitePure,
                  onTapBack: _handleBack,
                  rowWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Print',
                        icon: _isPrinting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.print_rounded,
                                color: Colors.white, size: 22),
                        onPressed: _isPrinting ? null : _handlePrint,
                      ),
                      IconButton(
                        tooltip: 'Share',
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.share_rounded,
                                color: Colors.white, size: 22),
                        onPressed: _isSharing ? null : _handleShare,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onDoubleTapDown: (details) {
                          _doubleTapPosition = details.localPosition;
                        },
                        onDoubleTap: () {
                          if (_currentScale > 1.1) {
                            _resetZoom();
                          } else {
                            final pos = _doubleTapPosition ?? Offset.zero;
                            final x = -pos.dx * 1.2;
                            final y = -pos.dy * 1.2;
                            _transformationController.value =
                                Matrix4.identity()
                                  ..translate(x, y)
                                  ..scale(2.2);
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 5.0,
                          panEnabled: true,
                          scaleEnabled: true,
                          boundaryMargin: const EdgeInsets.all(80),
                          child: PdfPreview(
                            build: (format) =>
                                InvoiceGenerator.generateInvoicePdf(
                                    widget.transaction),
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            dynamicLayout: false,
                            useActions: false,
                            pdfFileName: _pdfFileName,
                            loadingWidget: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF7A00)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Floating Zoom Controller Widget
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2029)
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    color: Colors.white, size: 18),
                                tooltip: 'Zoom Out',
                                constraints: const BoxConstraints(
                                  minWidth: 34,
                                  minHeight: 34,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed:
                                    _currentScale > 1.05 ? _zoomOut : null,
                              ),
                              GestureDetector(
                                onTap: _resetZoom,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _zoomPercentage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.white, size: 18),
                                tooltip: 'Zoom In',
                                constraints: const BoxConstraints(
                                  minWidth: 34,
                                  minHeight: 34,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed:
                                    _currentScale < 4.95 ? _zoomIn : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom Action Bar matching app bar gradient with SafeArea
                Container(
                  decoration: const BoxDecoration(
                    gradient: kAppBarGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isPrinting ? null : _handlePrint,
                              icon: _isPrinting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.print_rounded,
                                      color: Colors.white, size: 22),
                              label: const Text(
                                'Print',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.18),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSharing ? null : _handleShare,
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.share_rounded,
                                      color: Colors.white, size: 22),
                              label: const Text(
                                'Share',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.18),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
