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

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _groupBy = 'daily';
  bool _isExporting = false;

  // ── Chart data helpers ──────────────────────────────────────
  /// Returns a list of (label, totalRevenue) pairs for the chart.
  List<MapEntry<String, double>> _buildChartData(List<Order> orders) {
    if (_groupBy == 'daily') {
      // Show individual days in the range (max 14 days)
      final days = _dateRange.duration.inDays + 1;
      final showDays = days.clamp(1, 14);
      final results = <MapEntry<String, double>>[];
      for (int i = showDays - 1; i >= 0; i--) {
        final day = _dateRange.end.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final total = orders
            .where((o) => o.createdAt.isAfter(dayStart.subtract(const Duration(microseconds: 1))) &&
                o.createdAt.isBefore(dayEnd))
            .fold<double>(0, (s, o) => s + o.totalAmount);
        results.add(MapEntry('${day.day}/${day.month}', total));
      }
      return results;
    } else {
      // Weekly: show last 8 weeks
      final results = <MapEntry<String, double>>[];
      for (int w = 7; w >= 0; w--) {
        final weekEnd = _dateRange.end.subtract(Duration(days: w * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));
        final total = orders
            .where((o) => o.createdAt.isAfter(weekStart.subtract(const Duration(microseconds: 1))) &&
                o.createdAt.isBefore(weekEnd.add(const Duration(days: 1))))
            .fold<double>(0, (s, o) => s + o.totalAmount);
        results.add(MapEntry('W${8 - w}', total));
      }
      return results;
    }
  }

  // ── PDF Export ─────────────────────────────────────────────
  Future<void> _exportPdf(
    List<Order> filteredOrders,
    double totalRevenue,
    int totalOrders,
    double avgOrder,
    double totalTax,
  ) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _buildPdf(filteredOrders, totalRevenue, totalOrders, avgOrder, totalTax);
      await Printing.layoutPdf(onLayout: (_) => bytes, name: 'Sales_Report_${formatDate(_dateRange.start)}_${formatDate(_dateRange.end)}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<Uint8List> _buildPdf(
    List<Order> orders,
    double totalRevenue,
    int totalOrders,
    double avgOrder,
    double totalTax,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final cashCount = orders.where((o) => o.paymentMode == PaymentMode.cash).length;
    final cardCount = orders.where((o) => o.paymentMode == PaymentMode.card).length;
    final upiCount = orders.where((o) => o.paymentMode == PaymentMode.upi).length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(AppConstants.shopName, style: pw.TextStyle(font: fontBold, fontSize: 18)),
                pw.SizedBox(height: 4),
                pw.Text(AppConstants.shopAddress, style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center),
                pw.Text('GST: ${AppConstants.gstNumber}', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
          ),
          pw.Divider(height: 20),
          pw.Center(
            child: pw.Text('SALES REPORT', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          ),
          pw.Center(
            child: pw.Text(
              '${formatDate(_dateRange.start)}  to  ${formatDate(_dateRange.end)}',
              style: pw.TextStyle(font: font, fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfKpi('Total Revenue', formatCurrency(totalRevenue), font, fontBold),
                    _pdfKpi('Total Orders', '$totalOrders', font, fontBold),
                    _pdfKpi('Avg. Order Value', formatCurrency(avgOrder), font, fontBold),
                    _pdfKpi('Tax Collected', formatCurrency(totalTax), font, fontBold),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfKpi('Cash Orders', '$cashCount', font, fontBold),
                    _pdfKpi('Card Orders', '$cardCount', font, fontBold),
                    _pdfKpi('UPI Orders', '$upiCount', font, fontBold),
                    _pdfKpi('Discounts', formatCurrency(orders.fold(0.0, (s, o) => s + o.discountAmount)), font, fontBold),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Orders table
          pw.Text('Order Details', style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey100),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _pdfCell('Invoice #', fontBold),
                  _pdfCell('Date', fontBold),
                  _pdfCell('Customer', fontBold),
                  _pdfCell('Items', fontBold),
                  _pdfCell('Payment', fontBold),
                  _pdfCell('Total', fontBold, align: pw.TextAlign.right),
                ],
              ),
              ...orders.map((o) => pw.TableRow(
                children: [
                  _pdfCell(o.invoiceNumber, font),
                  _pdfCell(formatDate(o.createdAt), font),
                  _pdfCell(o.customerName ?? 'Walk-in', font),
                  _pdfCell('${o.items.length}', font),
                  _pdfCell(o.paymentMode.name.toUpperCase(), font),
                  _pdfCell(formatCurrency(o.totalAmount), fontBold, align: pw.TextAlign.right),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Generated on ${formatDateTime(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfKpi(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
      ],
    );
  }

  pw.Widget _pdfCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9), textAlign: align),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final filteredOrders = orders.where((o) =>
      o.createdAt.isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
      o.createdAt.isBefore(_dateRange.end.add(const Duration(days: 1))) &&
      o.status == OrderStatus.completed
    ).toList();

    final totalRevenue = filteredOrders.fold<double>(0, (s, o) => s + o.totalAmount);
    final totalOrders = filteredOrders.length;
    final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final totalTax = filteredOrders.fold<double>(0, (s, o) => s + o.taxAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting
                ? null
                : () => _exportPdf(filteredOrders, totalRevenue, totalOrders, avgOrder, totalTax),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range picker
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

            // KPI cards
            Row(
              children: [
                _kpi('Total Revenue', formatCurrency(totalRevenue), Icons.currency_rupee, AppTheme.primaryColor),
                const SizedBox(width: 12),
                _kpi('Orders', '$totalOrders', Icons.receipt, AppTheme.success),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpi('Avg. Order', formatCurrency(avgOrder), Icons.analytics, AppTheme.accentColor),
                const SizedBox(width: 12),
                _kpi('Tax Collected', formatCurrency(totalTax), Icons.account_balance, Colors.teal),
              ],
            ),
            const SizedBox(height: 24),

            // Sales trend chart
            Row(
              children: [
                const Text('Sales Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('Daily')),
                    ButtonSegment(value: 'weekly', label: Text('Weekly')),
                  ],
                  selected: {_groupBy},
                  onSelectionChanged: (v) => setState(() => _groupBy = v.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final chartData = _buildChartData(filteredOrders);
              final maxY = chartData.isEmpty
                  ? 100.0
                  : chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;
              return SizedBox(
                height: 250,
                child: chartData.every((e) => e.value == 0)
                    ? const Center(
                        child: Text('No sales data for selected period',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY == 0 ? 100 : maxY,
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 56,
                                getTitlesWidget: (v, meta) => Text(
                                  formatCompactCurrency(v),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: (chartData.length / 6).ceilToDouble().clamp(1, chartData.length.toDouble()),
                                getTitlesWidget: (v, meta) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(chartData[idx].key, style: const TextStyle(fontSize: 9)),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartData.asMap().entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                                  .toList(),
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                  show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                                  radius: 3,
                                  color: AppTheme.primaryColor,
                                  strokeWidth: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            }),
            const SizedBox(height: 24),

            // Payment mode breakdown
            const Text('Payment Mode Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: filteredOrders.where((o) => o.paymentMode == PaymentMode.cash).length.toDouble(),
                            title: 'Cash',
                            color: AppTheme.success,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: filteredOrders.where((o) => o.paymentMode == PaymentMode.card).length.toDouble(),
                            title: 'Card',
                            color: AppTheme.primaryColor,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: filteredOrders.where((o) => o.paymentMode == PaymentMode.upi).length.toDouble(),
                            title: 'UPI',
                            color: AppTheme.accentColor,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legend('Cash', AppTheme.success, '${filteredOrders.where((o) => o.paymentMode == PaymentMode.cash).length}'),
                      const SizedBox(height: 8),
                      _legend('Card', AppTheme.primaryColor, '${filteredOrders.where((o) => o.paymentMode == PaymentMode.card).length}'),
                      const SizedBox(height: 8),
                      _legend('UPI', AppTheme.accentColor, '${filteredOrders.where((o) => o.paymentMode == PaymentMode.upi).length}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent orders table
            const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Items')),
                    DataColumn(label: Text('Payment')),
                    DataColumn(label: Text('Total'), numeric: true),
                  ],
                  rows: filteredOrders.take(15).map((o) => DataRow(cells: [
                    DataCell(Text(o.invoiceNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataCell(Text(formatDate(o.createdAt), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(o.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${o.items.length}', style: const TextStyle(fontSize: 12))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _paymentColor(o.paymentMode).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(o.paymentMode.name.toUpperCase(), style: TextStyle(fontSize: 10, color: _paymentColor(o.paymentMode), fontWeight: FontWeight.w600)),
                    )),
                    DataCell(Text(formatCurrency(o.totalAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ])).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color, String count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text('$label ($count)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _paymentColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash: return AppTheme.success;
      case PaymentMode.card: return AppTheme.primaryColor;
      case PaymentMode.upi: return AppTheme.accentColor;
    }
  }
}
