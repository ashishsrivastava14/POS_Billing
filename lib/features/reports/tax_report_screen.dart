import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/order.dart';

class TaxReportScreen extends ConsumerStatefulWidget {
  const TaxReportScreen({super.key});

  @override
  ConsumerState<TaxReportScreen> createState() => _TaxReportScreenState();
}

class _TaxReportScreenState extends ConsumerState<TaxReportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  // ── Real weekly chart data ────────────────────────────────────────
  List<MapEntry<String, double>> _buildChartData(List<Order> orders) {
    final totalDays = _dateRange.duration.inDays + 1;
    final buckets = totalDays <= 7 ? totalDays : (totalDays <= 28 ? 4 : 6);
    final bucketDays = (totalDays / buckets).ceil();
    final results = <MapEntry<String, double>>[];
    for (int i = 0; i < buckets; i++) {
      final start = _dateRange.start.add(Duration(days: i * bucketDays));
      final end = start.add(Duration(days: bucketDays));
      final rangeEnd = _dateRange.end.add(const Duration(days: 1));
      final effectiveEnd = end.isAfter(rangeEnd) ? rangeEnd : end;
      final tax = orders
          .where((o) => !o.createdAt.isBefore(start) && o.createdAt.isBefore(effectiveEnd))
          .fold<double>(0, (s, o) => s + o.taxAmount);
      final label = buckets <= 7 ? '${start.day}/${start.month}' : 'W${i + 1}';
      results.add(MapEntry(label, tax));
    }
    return results;
  }

  // ── PDF Export ────────────────────────────────────────────────────
  Future<void> _exportPdf(
    List<Order> orders,
    double totalTax,
    double cgst,
    double sgst,
    double totalTaxableValue,
    double totalInvoiceValue,
    List<Map<String, Object>> taxSlabs,
  ) async {
    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _buildPdf(
          orders, totalTax, cgst, sgst, totalTaxableValue, totalInvoiceValue, taxSlabs);
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'GST_Report_${formatDate(_dateRange.start)}_${formatDate(_dateRange.end)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<Uint8List> _buildPdf(
    List<Order> orders,
    double totalTax,
    double cgst,
    double sgst,
    double totalTaxableValue,
    double totalInvoiceValue,
    List<Map<String, Object>> taxSlabs,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Center(
            child: pw.Column(children: [
              pw.Text(AppConstants.shopName,
                  style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.SizedBox(height: 4),
              pw.Text(AppConstants.shopAddress,
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center),
              pw.Text('GSTIN: ${AppConstants.gstNumber}',
                  style: pw.TextStyle(font: font, fontSize: 10)),
            ]),
          ),
          pw.Divider(height: 20),
          pw.Center(child: pw.Text('GST TAX REPORT',
              style: pw.TextStyle(font: fontBold, fontSize: 14))),
          pw.Center(child: pw.Text(
              'Period: ${formatDate(_dateRange.start)}  to  ${formatDate(_dateRange.end)}',
              style: pw.TextStyle(font: font, fontSize: 10))),
          pw.Center(child: pw.Text('Generated on ${formatDateTime(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 9))),
          pw.SizedBox(height: 16),

          // Summary KPIs
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfKpi('Total Invoices', '${orders.length}', font, fontBold),
                _pdfKpi('Taxable Value', formatCurrency(totalTaxableValue), font, fontBold),
                _pdfKpi('Total CGST', formatCurrency(cgst), font, fontBold),
                _pdfKpi('Total SGST', formatCurrency(sgst), font, fontBold),
                _pdfKpi('Total Tax', formatCurrency(totalTax), font, fontBold),
                _pdfKpi('Invoice Total', formatCurrency(totalInvoiceValue), font, fontBold),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Slab table
          pw.Text('GST Slab Breakdown',
              style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey100),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _pdfCell('GST Rate', fontBold),
                  _pdfCell('Taxable Value', fontBold, align: pw.TextAlign.right),
                  _pdfCell('CGST', fontBold, align: pw.TextAlign.right),
                  _pdfCell('SGST', fontBold, align: pw.TextAlign.right),
                  _pdfCell('Total Tax', fontBold, align: pw.TextAlign.right),
                ],
              ),
              ...taxSlabs.map((s) {
                final tax = s['tax'] as double;
                final taxable = s['taxable'] as double;
                return pw.TableRow(children: [
                  _pdfCell(s['rate'] as String, font),
                  _pdfCell(formatCurrency(taxable), font, align: pw.TextAlign.right),
                  _pdfCell(formatCurrency(tax / 2), font, align: pw.TextAlign.right),
                  _pdfCell(formatCurrency(tax / 2), font, align: pw.TextAlign.right),
                  _pdfCell(formatCurrency(tax), fontBold, align: pw.TextAlign.right),
                ]);
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: [
                  _pdfCell('Total', fontBold),
                  _pdfCell(formatCurrency(totalTaxableValue), fontBold, align: pw.TextAlign.right),
                  _pdfCell(formatCurrency(cgst), fontBold, align: pw.TextAlign.right),
                  _pdfCell(formatCurrency(sgst), fontBold, align: pw.TextAlign.right),
                  _pdfCell(formatCurrency(totalTax), fontBold, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // GSTR-1 summary
          pw.Text('GSTR-1 Summary',
              style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(children: [
              _pdfSummaryRow('Total Taxable Value', formatCurrency(totalTaxableValue), font, fontBold),
              _pdfSummaryRow('Total CGST', formatCurrency(cgst), font, fontBold),
              _pdfSummaryRow('Total SGST', formatCurrency(sgst), font, fontBold),
              _pdfSummaryRow('Total IGST', formatCurrency(0), font, fontBold),
              pw.Divider(),
              _pdfSummaryRow('Total Invoice Value', formatCurrency(totalInvoiceValue), font, fontBold),
              _pdfSummaryRow('Total Tax Liability', formatCurrency(totalTax), font, fontBold),
            ]),
          ),
          pw.SizedBox(height: 20),

          // Invoice-wise table
          pw.Text('Invoice-wise Tax Details',
              style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey100),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _pdfCell('Invoice #', fontBold),
                  _pdfCell('Date', fontBold),
                  _pdfCell('Customer', fontBold),
                  _pdfCell('Taxable', fontBold, align: pw.TextAlign.right),
                  _pdfCell('CGST', fontBold, align: pw.TextAlign.right),
                  _pdfCell('SGST', fontBold, align: pw.TextAlign.right),
                  _pdfCell('Invoice Total', fontBold, align: pw.TextAlign.right),
                ],
              ),
              ...orders.map((o) => pw.TableRow(children: [
                    _pdfCell(o.invoiceNumber, font),
                    _pdfCell(formatDate(o.createdAt), font),
                    _pdfCell(o.customerName ?? 'Walk-in', font),
                    _pdfCell(formatCurrency(o.subtotal), font, align: pw.TextAlign.right),
                    _pdfCell(formatCurrency(o.taxAmount / 2), font, align: pw.TextAlign.right),
                    _pdfCell(formatCurrency(o.taxAmount / 2), font, align: pw.TextAlign.right),
                    _pdfCell(formatCurrency(o.totalAmount), fontBold, align: pw.TextAlign.right),
                  ])),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text(AppConstants.receiptFooter,
              style: pw.TextStyle(font: font, fontSize: 9))),
        ],
      ),
    );
    return doc.save();
  }

  // ── CSV Export ────────────────────────────────────────────────────
  Future<void> _exportCsv(List<Order> orders) async {
    setState(() => _isExportingCsv = true);
    try {
      final sb = StringBuffer();
      sb.writeln('Invoice #,Date,Customer,Payment Mode,Taxable Value,CGST,SGST,Total Tax,Invoice Total');
      for (final o in orders) {
        final customer = (o.customerName ?? 'Walk-in').replaceAll(',', ' ');
        sb.writeln('${o.invoiceNumber},'
            '${formatDate(o.createdAt)},'
            '$customer,'
            '${o.paymentMode.name.toUpperCase()},'
            '${o.subtotal.toStringAsFixed(2)},'
            '${(o.taxAmount / 2).toStringAsFixed(2)},'
            '${(o.taxAmount / 2).toStringAsFixed(2)},'
            '${o.taxAmount.toStringAsFixed(2)},'
            '${o.totalAmount.toStringAsFixed(2)}');
      }
      final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Tax_Report_${formatDate(_dateRange.start)}_${formatDate(_dateRange.end)}.csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final filtered = orders.where((o) =>
      o.createdAt.isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
      o.createdAt.isBefore(_dateRange.end.add(const Duration(days: 1))) &&
      o.status == OrderStatus.completed
    ).toList();

    final totalTax = filtered.fold<double>(0, (s, o) => s + o.taxAmount);
    final cgst = totalTax / 2;
    final sgst = totalTax / 2;
    final totalTaxableValue = filtered.fold<double>(0, (s, o) => s + o.subtotal);
    final totalInvoiceValue = filtered.fold<double>(0, (s, o) => s + o.totalAmount);

    // GST slab breakdown (proportional estimate — Order model has no per-item rates)
    final taxSlabs = <Map<String, Object>>[
      {'rate': '0%',  'taxable': totalTaxableValue * 0.10, 'tax': 0.0},
      {'rate': '5%',  'taxable': totalTaxableValue * 0.35, 'tax': totalTaxableValue * 0.35 * 0.05},
      {'rate': '12%', 'taxable': totalTaxableValue * 0.25, 'tax': totalTaxableValue * 0.25 * 0.12},
      {'rate': '18%', 'taxable': totalTaxableValue * 0.20, 'tax': totalTaxableValue * 0.20 * 0.18},
      {'rate': '28%', 'taxable': totalTaxableValue * 0.10, 'tax': totalTaxableValue * 0.10 * 0.28},
    ];

    // Real chart data
    final chartData = _buildChartData(filtered);
    final maxY = chartData.isEmpty
        ? 100.0
        : (chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(1.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Report'),
        actions: [
          // CSV
          if (_isExportingCsv)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download CSV',
              onPressed: filtered.isEmpty ? null : () => _exportCsv(filtered),
            ),
          // PDF
          if (_isExportingPdf)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export GST Report PDF',
              onPressed: filtered.isEmpty
                  ? null
                  : () => _exportPdf(filtered, totalTax, cgst, sgst,
                        totalTaxableValue, totalInvoiceValue, taxSlabs),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text('${formatDate(_dateRange.start)} - ${formatDate(_dateRange.end)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                          initialDateRange: _dateRange,
                        );
                        if (range != null) setState(() => _dateRange = range);
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // No data banner
            if (filtered.isEmpty)
              Card(
                color: AppTheme.warning.withValues(alpha: 0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.warning),
                      SizedBox(width: 12),
                      Text('No completed orders in the selected date range.',
                          style: TextStyle(color: AppTheme.warning)),
                    ],
                  ),
                ),
              ),

            // Tax summary cards
            Row(
              children: [
                _taxCard('Total Tax', formatCurrency(totalTax), Icons.receipt_long, AppTheme.primaryColor),
                const SizedBox(width: 12),
                _taxCard('CGST', formatCurrency(cgst), Icons.account_balance, Colors.teal),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _taxCard('SGST', formatCurrency(sgst), Icons.account_balance, Colors.indigo),
                const SizedBox(width: 12),
                _taxCard('Invoices', '${filtered.length}', Icons.description, AppTheme.accentColor),
              ],
            ),
            const SizedBox(height: 24),

            // Tax collection trend chart (real data)
            const Text('Tax Collection Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: chartData.isEmpty
                  ? const Center(child: Text('No data'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (v, meta) => Text(
                                v == 0 ? '0' : '${(v / 1000).toStringAsFixed(1)}k',
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= chartData.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(chartData[idx].key,
                                      style: const TextStyle(fontSize: 9)),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          chartData.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: chartData[i].value,
                                width: 22,
                                color: AppTheme.primaryColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                rodStackItems: [
                                  BarChartRodStackItem(0, chartData[i].value / 2, Colors.teal),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend('CGST', Colors.teal),
                const SizedBox(width: 16),
                _legend('SGST', AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 24),

            // GST Slab breakdown
            const Text('GST Slab Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('GST Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Taxable Value', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('CGST', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('SGST', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Total Tax', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  ],
                  rows: [
                    ...taxSlabs.map((s) {
                      final tax = s['tax'] as double;
                      final taxable = s['taxable'] as double;
                      return DataRow(cells: [
                        DataCell(Text(s['rate'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(formatCurrency(taxable))),
                        DataCell(Text(formatCurrency(tax / 2))),
                        DataCell(Text(formatCurrency(tax / 2))),
                        DataCell(Text(formatCurrency(tax), style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]);
                    }),
                    DataRow(
                      color: WidgetStateProperty.all(AppTheme.primaryColor.withValues(alpha: 0.05)),
                      cells: [
                        const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(formatCurrency(totalTaxableValue), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(formatCurrency(cgst), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(formatCurrency(sgst), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(formatCurrency(totalTax), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // GSTR Summary
            const Text('GSTR-1 Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('Total Taxable Value', formatCurrency(totalTaxableValue)),
                    _summaryRow('Total CGST', formatCurrency(cgst)),
                    _summaryRow('Total SGST', formatCurrency(sgst)),
                    _summaryRow('Total IGST', formatCurrency(0)),
                    const Divider(),
                    _summaryRow('Total Invoice Value', formatCurrency(totalInvoiceValue), isBold: true),
                    _summaryRow('Total Tax Liability', formatCurrency(totalTax), isBold: true, color: AppTheme.error),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Invoice-wise tax details
            const Text('Invoice-wise Tax Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No orders found for selected period.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Taxable', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('CGST', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('SGST', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Total Tax', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Invoice Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    ],
                    rows: filtered.map((o) {
                      final halfTax = o.taxAmount / 2;
                      return DataRow(cells: [
                        DataCell(Text(o.invoiceNumber,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text(formatDate(o.createdAt),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(o.customerName ?? 'Walk-in',
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _paymentColor(o.paymentMode).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(o.paymentMode.name.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _paymentColor(o.paymentMode),
                                  fontWeight: FontWeight.w600)),
                        )),
                        DataCell(Text(formatCurrency(o.subtotal),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(formatCurrency(halfTax),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(formatCurrency(halfTax),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(formatCurrency(o.taxAmount),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor))),
                        DataCell(Text(formatCurrency(o.totalAmount),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _taxCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(value,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? (isBold ? AppTheme.primaryColor : null))),
        ],
      ),
    );
  }

  Color _paymentColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return AppTheme.success;
      case PaymentMode.card:
        return AppTheme.primaryColor;
      case PaymentMode.upi:
        return AppTheme.accentColor;
    }
  }

  // ── PDF helper widgets ───────────────────────────────────────────
  pw.Widget _pdfKpi(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.blueGrey600)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
        ]);
  }

  pw.Widget _pdfCell(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 9), textAlign: align),
    );
  }

  pw.Widget _pdfSummaryRow(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10)),
        ],
      ),
    );
  }
}
