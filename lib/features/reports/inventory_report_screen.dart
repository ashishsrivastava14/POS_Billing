import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_drawer.dart';

class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    ref.watch(categoriesProvider); // Categories provider used for side effects

    final totalProducts = products.length;
    final lowStockProducts = products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final outOfStockProducts = products.where((p) => p.isOutOfStock).toList();
    final totalStockValue = products.fold<double>(0, (s, p) => s + (p.purchasePrice * p.stockQty));
    final totalRetailValue = products.fold<double>(0, (s, p) => s + (p.sellingPrice * p.stockQty));

    // Category stock distribution
    final categoryStockMap = <String, int>{};
    for (final p in products) {
      categoryStockMap[p.categoryName] = (categoryStockMap[p.categoryName] ?? 0) + p.stockQty;
    }

    final colors = [AppTheme.primaryColor, AppTheme.accentColor, AppTheme.success, Colors.purple, Colors.teal, Colors.pink, Colors.indigo, Colors.brown, Colors.cyan, Colors.lime];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting PDF (mock)...'))),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs
            Row(
              children: [
                _kpi('Total Products', '$totalProducts', Icons.inventory_2, AppTheme.primaryColor),
                const SizedBox(width: 12),
                _kpi('Low Stock', '${lowStockProducts.length}', Icons.warning, AppTheme.warning),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpi('Out of Stock', '${outOfStockProducts.length}', Icons.error, AppTheme.error),
                const SizedBox(width: 12),
                _kpi('Stock Value', formatCurrency(totalStockValue), Icons.account_balance_wallet, AppTheme.success),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.trending_up, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Potential Revenue', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(formatCurrency(totalRetailValue), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Margin', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(formatCurrency(totalRetailValue - totalStockValue), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.success)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category-wise stock distribution
            const Text('Category Stock Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (categoryStockMap.values.isEmpty ? 100 : categoryStockMap.values.reduce((a, b) => a > b ? a : b) * 1.2),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final keys = categoryStockMap.keys.toList();
                          if (v.toInt() >= keys.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(keys[v.toInt()].length > 6 ? '${keys[v.toInt()].substring(0, 6)}..' : keys[v.toInt()], style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: categoryStockMap.entries.toList().asMap().entries.map((e) {
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        color: colors[e.key % colors.length],
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Low stock alerts
            if (lowStockProducts.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.warning, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  const Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              ...lowStockProducts.take(10).map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${p.stockQty}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning))),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('${p.categoryName} • Min: ${p.minStockAlert}', style: const TextStyle(fontSize: 11)),
                  trailing: Text('Need ${p.minStockAlert - p.stockQty} more', style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              )),
            ],

            // Out of stock
            if (outOfStockProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.error, color: AppTheme.error, size: 20),
                  const SizedBox(width: 8),
                  const Text('Out of Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              ...outOfStockProducts.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppTheme.error.withValues(alpha: 0.03),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove_shopping_cart, size: 18, color: AppTheme.error),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('${p.categoryName} • ${p.brand}', style: const TextStyle(fontSize: 11)),
                  trailing: const Text('REORDER', style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              )),
            ],
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
}
