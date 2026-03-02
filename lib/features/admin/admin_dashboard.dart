import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../core/widgets/kpi_card.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/product_image.dart';
import '../../core/providers.dart';
import '../../models/order.dart';
import 'dart:math';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final products = ref.watch(productsProvider);
    final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
    final todaySales = completedOrders.fold<double>(0, (s, o) => s + o.totalAmount);
    final lowStockCount = products.where((p) => p.isLowStock).length;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 800 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: constraints.maxWidth > 800 ? 1.5 : 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    KpiCard(
                      title: "Today's Sales",
                      value: formatCompactCurrency(todaySales),
                      icon: Icons.currency_rupee,
                      color: AppTheme.success,
                    ),
                    KpiCard(
                      title: 'Orders Count',
                      value: completedOrders.length.toString(),
                      icon: Icons.receipt_long,
                      color: AppTheme.primaryColor,
                    ),
                    KpiCard(
                      title: 'Low Stock Alerts',
                      value: lowStockCount.toString(),
                      icon: Icons.warning_amber,
                      color: lowStockCount > 0 ? AppTheme.warning : AppTheme.success,
                    ),
                    KpiCard(
                      title: 'Total Products',
                      value: products.length.toString(),
                      icon: Icons.inventory,
                      color: AppTheme.info,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Sales Trend Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sales Trend (7 Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return BarTooltipItem(
                                  '${days[groupIndex]}\n${formatCurrency(rod.toY)}',
                                  const TextStyle(color: Colors.white, fontSize: 12),
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
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(days[value.toInt() % 7], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: List.generate(7, (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: 5000 + Random(i * 42).nextDouble() * 15000,
                                color: AppTheme.primaryColor,
                                width: 28,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Pie Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category-wise Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: categories.take(6).toList().asMap().entries.map((entry) {
                            final colors = [
                              AppTheme.primaryColor, AppTheme.accentColor, AppTheme.success,
                              AppTheme.info, AppTheme.warning, AppTheme.error,
                            ];
                            return PieChartSectionData(
                              value: entry.value.productCount.toDouble(),
                              title: '${entry.value.productCount}',
                              color: colors[entry.key % colors.length],
                              radius: 35,
                              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: categories.take(6).toList().asMap().entries.map((entry) {
                        final colors = [
                          AppTheme.primaryColor, AppTheme.accentColor, AppTheme.success,
                          AppTheme.info, AppTheme.warning, AppTheme.error,
                        ];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[entry.key % colors.length], shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(entry.value.name, style: const TextStyle(fontSize: 11)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Selling Products
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...products.take(5).map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ProductImage(
                          productId: p.id,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          placeholderColor: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(p.categoryName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      trailing: Text(formatCurrency(p.sellingPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
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
}
