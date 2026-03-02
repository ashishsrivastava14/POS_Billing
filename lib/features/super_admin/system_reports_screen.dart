import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';

class SystemReportsScreen extends ConsumerStatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  ConsumerState<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends ConsumerState<SystemReportsScreen> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('System Reports')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.date_range, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateRange != null
                                ? '${formatDate(_dateRange!.start)} – ${formatDate(_dateRange!.end)}'
                                : 'Select Date Range',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _dateRange != null ? null : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (_dateRange != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Clear',
                            onPressed: () => setState(() => _dateRange = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                                initialDateRange: _dateRange,
                              );
                              if (range != null) setState(() => _dateRange = range);
                            },
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: const Text('Pick Dates'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _dateRange != null
                                        ? 'Exporting report for ${formatDate(_dateRange!.start)} – ${formatDate(_dateRange!.end)}'
                                        : 'Exporting full report as PDF…',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('Export PDF'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Revenue by Vendor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Breakdown by Vendor',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: vendors.asMap().entries.map((entry) {
                            final colors = [AppTheme.primaryColor, AppTheme.accentColor, AppTheme.success, AppTheme.info, AppTheme.warning];
                            return PieChartSectionData(
                              value: entry.value.totalRevenue,
                              title: '${(entry.value.totalRevenue / vendors.fold<double>(0, (s, v) => s + v.totalRevenue) * 100).toStringAsFixed(0)}%',
                              color: colors[entry.key % colors.length],
                              radius: 40,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...vendors.asMap().entries.map((entry) {
                      final colors = [AppTheme.primaryColor, AppTheme.accentColor, AppTheme.success, AppTheme.info, AppTheme.warning];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[entry.key % colors.length], shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(entry.value.shopName, style: const TextStyle(fontSize: 13))),
                            Text(formatCurrency(entry.value.totalRevenue), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendor Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Shop Name')),
                          DataColumn(label: Text('Owner')),
                          DataColumn(label: Text('Plan')),
                          DataColumn(label: Text('Staff')),
                          DataColumn(label: Text('Revenue'), numeric: true),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: vendors.map((v) => DataRow(cells: [
                          DataCell(Text(v.shopName)),
                          DataCell(Text(v.ownerName)),
                          DataCell(Text(v.plan)),
                          DataCell(Text(v.staffCount.toString())),
                          DataCell(Text(formatCurrency(v.totalRevenue))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: v.isActive ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              v.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(fontSize: 11, color: v.isActive ? AppTheme.success : AppTheme.error),
                            ),
                          )),
                        ])).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
