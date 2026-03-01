import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';

class InventoryManagementScreen extends ConsumerStatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  ConsumerState<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends ConsumerState<InventoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    final lowStock = products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final outOfStock = products.where((p) => p.isOutOfStock).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${products.length})'),
            Tab(text: 'Low Stock (${lowStock.length})'),
            Tab(text: 'Out of Stock (${outOfStock.length})'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStockTable(products),
                _buildStockTable(lowStock),
                _buildStockTable(outOfStock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTable(List<dynamic> items) {
    final filtered = items.where((p) => p.name.toLowerCase().contains(_search.toLowerCase()) || p.sku.toLowerCase().contains(_search.toLowerCase())).toList();

    if (filtered.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No items found', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          dataTextStyle: const TextStyle(fontSize: 13),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Current Stock'), numeric: true),
            DataColumn(label: Text('Min Alert'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: filtered.map<DataRow>((p) {
            Color statusColor = AppTheme.success;
            String statusText = 'In Stock';
            if (p.isOutOfStock) {
              statusColor = AppTheme.error;
              statusText = 'Out of Stock';
            } else if (p.isLowStock) {
              statusColor = AppTheme.warning;
              statusText = 'Low Stock';
            }
            return DataRow(cells: [
              DataCell(SizedBox(
                width: 160,
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.shopping_bag, size: 18, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              )),
              DataCell(Text(p.sku)),
              DataCell(Text(p.categoryName)),
              DataCell(Text('${p.stockQty}', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor))),
              DataCell(Text('${p.minStockAlert}')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.success),
                    tooltip: 'Add Stock',
                    onPressed: () => _showStockAdjustment(p, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.error),
                    tooltip: 'Remove Stock',
                    onPressed: () => _showStockAdjustment(p, false),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showStockAdjustment(dynamic product, bool isAdd) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isAdd ? 'Add Stock' : 'Remove Stock'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product: ${product.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Current Stock: ${product.stockQty}'),
                const SizedBox(height: 16),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason / Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                ref.read(productsProvider.notifier).adjustStock(product.id, isAdd ? qty : -qty);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock ${isAdd ? 'added' : 'removed'}: $qty units')),
                );
              },
              child: Text(isAdd ? 'Add' : 'Remove'),
            ),
          ],
        );
      },
    );
  }
}
