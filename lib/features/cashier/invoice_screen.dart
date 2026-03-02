import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final String orderId;
  const InvoiceScreen({super.key, required this.orderId});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  bool _isGenerating = false;

  Future<Uint8List> _generateInvoicePdf(Order order) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      AppConstants.shopName,
                      style: pw.TextStyle(font: fontBold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      AppConstants.shopAddress,
                      style: pw.TextStyle(font: font, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'GST: ${AppConstants.gstNumber}',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Divider(height: 16),

              // Order info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Invoice #${order.invoiceNumber}',
                    style: pw.TextStyle(font: fontBold, fontSize: 11),
                  ),
                  pw.Text(
                    formatDateTime(order.createdAt),
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Customer: ${order.customerName ?? 'Walk-in'}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Cashier: ${order.cashierName}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.Divider(height: 16),

              // Items table header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Qty',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Price',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.Divider(height: 6),

              // Items
              ...order.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          item.productName,
                          style: pw.TextStyle(font: font, fontSize: 10),
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity}',
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          formatCurrency(item.unitPrice),
                          style: pw.TextStyle(font: font, fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          formatCurrency(item.lineTotal),
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(height: 16),

              // Totals
              _pdfRow(
                'Subtotal',
                formatCurrency(order.subtotal),
                font,
                fontBold,
              ),
              if (order.discountAmount > 0)
                _pdfRow(
                  'Discount',
                  '-${formatCurrency(order.discountAmount)}',
                  font,
                  fontBold,
                  valueColor: PdfColors.green700,
                ),
              _pdfRow(
                'CGST',
                formatCurrency(order.taxAmount / 2),
                font,
                fontBold,
              ),
              _pdfRow(
                'SGST',
                formatCurrency(order.taxAmount / 2),
                font,
                fontBold,
              ),
              pw.Divider(height: 8),
              _pdfRow(
                'Grand Total',
                formatCurrency(order.totalAmount),
                fontBold,
                fontBold,
                fontSize: 13,
                valueColor: PdfColors.indigo700,
              ),
              pw.SizedBox(height: 4),
              _pdfRow(
                'Payment',
                order.paymentMode.name.toUpperCase(),
                font,
                fontBold,
              ),
              if (order.cashTendered != null)
                _pdfRow(
                  'Cash Tendered',
                  formatCurrency(order.cashTendered!),
                  font,
                  fontBold,
                ),
              if (order.changeAmount != null && order.changeAmount! > 0)
                _pdfRow(
                  'Change',
                  formatCurrency(order.changeAmount!),
                  font,
                  fontBold,
                  valueColor: PdfColors.green700,
                ),
              pw.Divider(height: 16),

              // Footer
              pw.Center(
                child: pw.Text(
                  AppConstants.receiptFooter,
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfRow(
    String label,
    String value,
    pw.Font labelFont,
    pw.Font valueFont, {
    double fontSize = 10,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: labelFont, fontSize: fontSize),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: valueFont,
              fontSize: fontSize,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(Order order) async {
    setState(() => _isGenerating = true);
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _generateInvoicePdf(order),
        name: 'Invoice_${order.invoiceNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _savePdf(Order order) async {
    setState(() => _isGenerating = true);
    try {
      final bytes = await _generateInvoicePdf(order);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Invoice_${order.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save PDF failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print Invoice',
              onPressed: () => _printInvoice(order),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share / Save PDF',
              onPressed: () => _savePdf(order),
            ),
          ],
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Icon(
                    Icons.store,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppConstants.shopName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    AppConstants.shopAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'GST: ${AppConstants.gstNumber}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Divider(height: 24),

                  // Order info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice ${order.invoiceNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatDateTime(order.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer: ${order.customerName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Cashier: ${order.cashierName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Items table header
                  const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Item',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Qty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Price',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Items
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrency(item.unitPrice),
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrency(item.lineTotal),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),

                  // Totals
                  _invoiceRow('Subtotal', formatCurrency(order.subtotal)),
                  if (order.discountAmount > 0)
                    _invoiceRow(
                      'Discount',
                      '-${formatCurrency(order.discountAmount)}',
                      color: AppTheme.success,
                    ),
                  _invoiceRow('CGST', formatCurrency(order.taxAmount / 2)),
                  _invoiceRow('SGST', formatCurrency(order.taxAmount / 2)),
                  const Divider(),
                  _invoiceRow(
                    'Grand Total',
                    formatCurrency(order.totalAmount),
                    isBold: true,
                    size: 16,
                  ),
                  const SizedBox(height: 8),
                  _invoiceRow('Payment', order.paymentMode.name.toUpperCase()),
                  if (order.cashTendered != null)
                    _invoiceRow(
                      'Cash Tendered',
                      formatCurrency(order.cashTendered!),
                    ),
                  if (order.changeAmount != null && order.changeAmount! > 0)
                    _invoiceRow(
                      'Change',
                      formatCurrency(order.changeAmount!),
                      color: AppTheme.success,
                    ),

                  const Divider(height: 24),
                  Text(
                    AppConstants.receiptFooter,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Barcode mock
                  Container(
                    height: 40,
                    width: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '||||||||||||||||||||',
                        style: TextStyle(letterSpacing: -1.5, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/cashier/billing'),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('New Sale'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating
                              ? null
                              : () => _savePdf(order),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Save PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _invoiceRow(
    String label,
    String value, {
    bool isBold = false,
    double size = 12,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: size, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? AppTheme.primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }
}
