import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
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

    // Tax slab breakdown (mock different GST rates)
    final taxSlabs = [
      {'rate': '0%', 'taxable': totalTaxableValue * 0.1, 'tax': 0.0},
      {'rate': '5%', 'taxable': totalTaxableValue * 0.35, 'tax': totalTaxableValue * 0.35 * 0.05},
      {'rate': '12%', 'taxable': totalTaxableValue * 0.25, 'tax': totalTaxableValue * 0.25 * 0.12},
      {'rate': '18%', 'taxable': totalTaxableValue * 0.2, 'tax': totalTaxableValue * 0.2 * 0.18},
      {'rate': '28%', 'taxable': totalTaxableValue * 0.1, 'tax': totalTaxableValue * 0.1 * 0.28},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting GST report PDF (mock)...'))),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading CSV (mock)...'))),
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

            // Tax collection chart
            const Text('Tax Collection Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                          if (v.toInt() >= labels.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[v.toInt()], style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(4, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: totalTax / 4 * (0.8 + (i % 3) * 0.15),
                        width: 22,
                        color: AppTheme.primaryColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        rodStackItems: [
                          BarChartRodStackItem(0, totalTax / 8 * (0.8 + (i % 3) * 0.15), Colors.teal),
                        ],
                      ),
                    ],
                  )),
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

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? (isBold ? AppTheme.primaryColor : null))),
        ],
      ),
    );
  }
}
