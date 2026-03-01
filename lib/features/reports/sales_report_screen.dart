import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting PDF (mock)...')));
            },
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
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(7, (i) => FlSpot(i.toDouble(), (totalRevenue / 7 * (0.7 + (i % 3) * 0.2)))),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
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
                    DataCell(Text('#${o.id.substring(0, 8)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
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
