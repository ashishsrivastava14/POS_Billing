import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/kpi_card.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers.dart';
import 'dart:math';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorsProvider);
    final orders = ref.watch(ordersProvider);
    final users = ref.watch(usersProvider);
    final totalRevenue = vendors.fold<double>(0, (s, v) => s + v.totalRevenue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context, ref),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 800 ? 4 : 2;
                final aspectRatio = constraints.maxWidth > 800 ? 1.5 : 1.0;
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    KpiCard(
                      title: 'Total Vendors',
                      value: vendors.length.toString(),
                      icon: Icons.store,
                      color: AppTheme.primaryColor,
                      subtitle: '${vendors.where((v) => v.isActive).length} active',
                      onTap: () => context.push('/super-admin/vendors'),
                    ),
                    KpiCard(
                      title: 'Total Revenue',
                      value: formatCompactCurrency(totalRevenue),
                      icon: Icons.currency_rupee,
                      color: AppTheme.success,
                      subtitle: 'All time',
                      onTap: () => context.push('/super-admin/reports'),
                    ),
                    KpiCard(
                      title: 'Active Sessions',
                      value: '${users.where((u) => u.isActive).length}',
                      icon: Icons.people,
                      color: AppTheme.info,
                      subtitle: 'Currently online',
                      onTap: () => context.push('/super-admin/users'),
                    ),
                    KpiCard(
                      title: 'Total Orders',
                      value: orders.length.toString(),
                      icon: Icons.receipt_long,
                      color: AppTheme.accentColor,
                      subtitle: 'This month',
                      onTap: () => context.push('/super-admin/reports'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Revenue Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Last 30 Days',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20000,
                            getDrawingHorizontalLine: (value) =>
                                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) => Text(
                                  '₹${(value / 1000).toStringAsFixed(0)}k',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'D${value.toInt()}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(30, (i) {
                                return FlSpot(i.toDouble(), 30000 + Random(i).nextDouble() * 70000);
                              }),
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              ),
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Shops Bar Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Performing Shops',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${vendors[groupIndex].shopName}\n',
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: formatCurrency(rod.toY),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < vendors.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        vendors[idx].shopName.split(' ')[0],
                                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: List.generate(vendors.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: vendors[i].totalRevenue,
                                  color: i == 0 ? AppTheme.accentColor : AppTheme.primaryColor,
                                  width: 24,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent Activity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () => context.push('/super-admin/audit-logs'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...ref.watch(auditLogsProvider).take(5).map((log) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _getActionColor(log.action).withValues(alpha: 0.1),
                        child: Icon(
                          _getActionIcon(log.action),
                          color: _getActionColor(log.action),
                          size: 20,
                        ),
                      ),
                      title: Text(log.details, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        '${log.userName} • ${formatDateTime(log.timestamp)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final logs = ref.read(auditLogsProvider).take(10).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/super-admin/audit-logs');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('No recent notifications'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getActionColor(log.action).withValues(alpha: 0.1),
                            child: Icon(
                              _getActionIcon(log.action),
                              color: _getActionColor(log.action),
                              size: 20,
                            ),
                          ),
                          title: Text(log.details, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            '${log.userName} • ${formatDateTime(log.timestamp)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getActionColor(log.action).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.action,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getActionColor(log.action),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'Created': return AppTheme.success;
      case 'Updated': return AppTheme.info;
      case 'Deleted': return AppTheme.error;
      case 'Deactivated': return AppTheme.warning;
      default: return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'Created': return Icons.add_circle;
      case 'Updated': return Icons.edit;
      case 'Deleted': return Icons.delete;
      case 'Deactivated': return Icons.block;
      default: return Icons.info;
    }
  }
}
