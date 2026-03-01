import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  String _searchQuery = '';
  String? _categoryFilter;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null || p.categoryId == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV import feature (mock)')),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search by name, SKU or brand...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _categoryFilter == null,
                    onSelected: (_) => setState(() => _categoryFilter = null),
                  ),
                ),
                ...categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryFilter == c.id,
                    onSelected: (_) => setState(() => _categoryFilter = _categoryFilter == c.id ? null : c.id),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${filtered.length} products', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isGridView ? _buildGridView(filtered) : _buildListView(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showProductForm(context, product: p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.shopping_bag, size: 40, color: AppTheme.primaryColor)),
                          if (p.isLowStock || p.isOutOfStock)
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.isOutOfStock ? AppTheme.error : AppTheme.warning,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.isOutOfStock ? 'Out of Stock' : 'Low Stock',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(p.brand, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatCurrency(p.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                                Text('Qty: ${p.stockQty}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: AppTheme.primaryColor),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${p.sku} • ${p.brand} • ${p.categoryName}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatCurrency(p.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.isOutOfStock ? AppTheme.error.withValues(alpha: 0.1) : p.isLowStock ? AppTheme.warning.withValues(alpha: 0.1) : AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stock: ${p.stockQty}',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.isOutOfStock ? AppTheme.error : p.isLowStock ? AppTheme.warning : AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => _showProductForm(context, product: p),
          ),
        );
      },
    );
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final brandCtrl = TextEditingController(text: product?.brand ?? '');
    final purchaseCtrl = TextEditingController(text: product?.purchasePrice.toString() ?? '');
    final sellingCtrl = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    final taxCtrl = TextEditingController(text: product?.taxPercent.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stockQty.toString() ?? '');
    final minStockCtrl = TextEditingController(text: product?.minStockAlert.toString() ?? '');
    String selectedCategoryId = product?.categoryId ?? 'c1';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode'))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: ref.read(categoriesProvider).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setDialogState(() => selectedCategoryId = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: purchaseCtrl, decoration: const InputDecoration(labelText: 'Purchase Price'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: sellingCtrl, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: taxCtrl, decoration: const InputDecoration(labelText: 'Tax %'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock Qty'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Min Stock Alert'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image picker (mock)')),
                          );
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Image'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (product != null)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Delete Product?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                              onPressed: () {
                                ref.read(productsProvider.notifier).delete(product.id);
                                Navigator.pop(dCtx);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                  ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final cat = ref.read(categoriesProvider).firstWhere((c) => c.id == selectedCategoryId);
                    if (product == null) {
                      ref.read(productsProvider.notifier).add(Product(
                        id: 'p${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text,
                        sku: skuCtrl.text,
                        barcode: barcodeCtrl.text,
                        categoryId: selectedCategoryId,
                        categoryName: cat.name,
                        brand: brandCtrl.text,
                        unit: 'pcs',
                        purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0,
                        sellingPrice: double.tryParse(sellingCtrl.text) ?? 0,
                        taxPercent: double.tryParse(taxCtrl.text) ?? 0,
                        stockQty: int.tryParse(stockCtrl.text) ?? 0,
                        minStockAlert: int.tryParse(minStockCtrl.text) ?? 5,
                        vendorId: 'v1',
                      ));
                    } else {
                      ref.read(productsProvider.notifier).update(product.copyWith(
                        name: nameCtrl.text,
                        sku: skuCtrl.text,
                        barcode: barcodeCtrl.text,
                        categoryId: selectedCategoryId,
                        categoryName: cat.name,
                        brand: brandCtrl.text,
                        purchasePrice: double.tryParse(purchaseCtrl.text),
                        sellingPrice: double.tryParse(sellingCtrl.text),
                        taxPercent: double.tryParse(taxCtrl.text),
                        stockQty: int.tryParse(stockCtrl.text),
                        minStockAlert: int.tryParse(minStockCtrl.text),
                      ));
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(product == null ? 'Product added' : 'Product updated')),
                    );
                  },
                  child: Text(product == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
