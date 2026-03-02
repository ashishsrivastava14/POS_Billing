import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/product_image.dart';
import '../../models/product.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  String _searchQuery = '';
  String? _categoryFilter;
  bool _isGridView = true;

  void _openForm({Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ProductFormPage(product: product),
      ),
    );
  }

  // ── CSV Import ────────────────────────────────────────────
  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file contents')),
          );
        }
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final lines = content
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV has no data rows (need header + at least 1 row)')),
          );
        }
        return;
      }

      final headers = _parseCsvRow(lines.first)
          .map((h) => h.trim().toLowerCase().replaceAll(' ', '_'))
          .toList();

      final categories = ref.read(categoriesProvider);
      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      for (int i = 1; i < lines.length; i++) {
        try {
          final row = _parseCsvRow(lines[i]);
          final product = _productFromRow(i + 1, headers, row, categories);
          ref.read(productsProvider.notifier).add(product);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Row ${i + 1}: $e');
        }
      }

      if (mounted) _showImportResultDialog(imported, failed, errors);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  /// Parses a single CSV row, respecting double-quoted fields with commas.
  List<String> _parseCsvRow(String row) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < row.length; i++) {
      final ch = row[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  /// Builds a [Product] from a CSV row using the parsed headers.
  /// Expected columns (order-independent, matched by header name):
  /// name*, sku, barcode, category_name, brand, unit,
  /// purchase_price*, selling_price*, tax_percent, stock_qty, min_stock_alert
  Product _productFromRow(
    int rowNum,
    List<String> headers,
    List<String> row,
    List<dynamic> categories,
  ) {
    String col(String key) {
      final idx = headers.indexOf(key);
      if (idx == -1 || idx >= row.length) return '';
      return row[idx].trim();
    }

    final name = col('name');
    if (name.isEmpty) throw 'Missing required column "name"';

    final purchaseStr = col('purchase_price');
    final sellingStr = col('selling_price');
    final purchase = double.tryParse(purchaseStr);
    final selling = double.tryParse(sellingStr);
    if (purchase == null) throw 'Invalid purchase_price "$purchaseStr"';
    if (selling == null) throw 'Invalid selling_price "$sellingStr"';

    final catName = col('category_name');
    final matchedCat = categories.cast<dynamic>().firstWhere(
          (c) => c.name.toLowerCase() == catName.toLowerCase(),
          orElse: () => categories.isNotEmpty ? categories.first : null,
        );
    if (matchedCat == null) throw 'No categories found';

    return Product(
      id: 'p\${DateTime.now().microsecondsSinceEpoch}_$rowNum',
      name: name,
      sku: col('sku'),
      barcode: col('barcode'),
      categoryId: matchedCat.id as String,
      categoryName: matchedCat.name as String,
      brand: col('brand'),
      unit: col('unit').isEmpty ? 'pcs' : col('unit'),
      purchasePrice: purchase,
      sellingPrice: selling,
      taxPercent: double.tryParse(col('tax_percent')) ?? 0,
      stockQty: int.tryParse(col('stock_qty')) ?? 0,
      minStockAlert: int.tryParse(col('min_stock_alert')) ?? 5,
      vendorId: 'v1',
    );
  }

  void _showImportResultDialog(int imported, int failed, List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              imported > 0 ? Icons.check_circle : Icons.error_outline,
              color: imported > 0 ? AppTheme.success : AppTheme.error,
            ),
            const SizedBox(width: 10),
            const Text('Import Result'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultChip('Imported', imported, AppTheme.success),
            if (failed > 0) ...[const SizedBox(height: 8), _resultChip('Failed', failed, AppTheme.error)],
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $e',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.error)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'CSV format: name, sku, barcode, category_name, brand, unit, purchase_price, selling_price, tax_percent, stock_qty, min_stock_alert',
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _resultChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count products',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

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
            onPressed: _importCsv,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name, SKU or brand...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
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
                onTap: () => _openForm(product: p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ProductImage(
                              productId: p.id,
                              imageUrl: p.imageUrl,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholderColor: AppTheme.primaryColor,
                            ),
                          ),
                          if (p.isLowStock || p.isOutOfStock)
                            Positioned(
                              top: 6, right: 6,
                              child: _StockBadge(product: p),
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
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                productId: p.id,
                imageUrl: p.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholderColor: AppTheme.primaryColor,
              ),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${p.sku} • ${p.brand} • ${p.categoryName}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatCurrency(p.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 4),
                _StockBadge(product: p, compact: true),
              ],
            ),
            onTap: () => _openForm(product: p),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STOCK BADGE HELPER
// ─────────────────────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final Product product;
  final bool compact;
  const _StockBadge({required this.product, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = product.isOutOfStock
        ? AppTheme.error
        : product.isLowStock
            ? AppTheme.warning
            : AppTheme.success;
    final label = compact
        ? 'Stock: \${product.stockQty}'
        : product.isOutOfStock
            ? 'Out of Stock'
            : 'Low Stock';
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 6, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: compact ? 0.1 : 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 9,
          color: compact ? color : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRODUCT FORM PAGE  (full-screen, beautiful)
// ─────────────────────────────────────────────────────────────
class _ProductFormPage extends ConsumerStatefulWidget {
  final Product? product;
  const _ProductFormPage({this.product});

  @override
  ConsumerState<_ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<_ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _purchaseCtrl;
  late final TextEditingController _sellingCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;

  late String _selectedCategoryId;
  Uint8List? _pickedImageBytes;   // works on both web and native
  String? _pickedImagePath;       // native file path (null on web)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _unitCtrl = TextEditingController(text: p?.unit ?? 'pcs');
    _purchaseCtrl = TextEditingController(text: p != null ? p.purchasePrice.toString() : '');
    _sellingCtrl = TextEditingController(text: p != null ? p.sellingPrice.toString() : '');
    _taxCtrl = TextEditingController(text: p != null ? p.taxPercent.toString() : '0');
    _stockCtrl = TextEditingController(text: p != null ? p.stockQty.toString() : '0');
    _minStockCtrl = TextEditingController(text: p != null ? p.minStockAlert.toString() : '5');
    _selectedCategoryId = p?.categoryId ?? 'c1';
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _skuCtrl, _barcodeCtrl, _brandCtrl, _unitCtrl,
      _purchaseCtrl, _sellingCtrl, _taxCtrl, _stockCtrl, _minStockCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImagePath = kIsWeb ? null : xFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: \$e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Select Image Source',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.accentColor),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from your photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImageBytes != null ||
                  (widget.product?.imageUrl?.isNotEmpty ?? false))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppTheme.error),
                  ),
                  title: const Text('Remove Image',
                      style: TextStyle(color: AppTheme.error)),
                  onTap: () {
                    setState(() { _pickedImageBytes = null; _pickedImagePath = null; });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barcode scanner ───────────────────────────────────────
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _BarcodeScannerPage(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _barcodeCtrl.text = result);
    }
  }

  // ── Save ──────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final cats = ref.read(categoriesProvider);
    final cat = cats.firstWhere((c) => c.id == _selectedCategoryId);
    final imageUrl = _pickedImagePath ?? widget.product?.imageUrl;
    if (widget.product == null) {
      ref.read(productsProvider.notifier).add(Product(
            id: 'p\${DateTime.now().millisecondsSinceEpoch}',
            name: _nameCtrl.text.trim(),
            sku: _skuCtrl.text.trim(),
            barcode: _barcodeCtrl.text.trim(),
            categoryId: _selectedCategoryId,
            categoryName: cat.name,
            brand: _brandCtrl.text.trim(),
            unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
            purchasePrice: double.tryParse(_purchaseCtrl.text) ?? 0,
            sellingPrice: double.tryParse(_sellingCtrl.text) ?? 0,
            taxPercent: double.tryParse(_taxCtrl.text) ?? 0,
            stockQty: int.tryParse(_stockCtrl.text) ?? 0,
            minStockAlert: int.tryParse(_minStockCtrl.text) ?? 5,
            vendorId: 'v1',
            imageUrl: imageUrl,
          ));
    } else {
      ref.read(productsProvider.notifier).update(widget.product!.copyWith(
            name: _nameCtrl.text.trim(),
            sku: _skuCtrl.text.trim(),
            barcode: _barcodeCtrl.text.trim(),
            categoryId: _selectedCategoryId,
            categoryName: cat.name,
            brand: _brandCtrl.text.trim(),
            unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
            purchasePrice: double.tryParse(_purchaseCtrl.text),
            sellingPrice: double.tryParse(_sellingCtrl.text),
            taxPercent: double.tryParse(_taxCtrl.text),
            stockQty: int.tryParse(_stockCtrl.text),
            minStockAlert: int.tryParse(_minStockCtrl.text),
            imageUrl: imageUrl,
          ));
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.product == null
            ? 'Product added successfully'
            : 'Product updated successfully'),
        backgroundColor: AppTheme.success,
      ));
    }
  }

  // ── Delete ────────────────────────────────────────────────
  void _confirmDelete() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever,
                    color: AppTheme.error, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Delete Product?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'This will permanently remove "\${widget.product!.name}" and cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error),
                      onPressed: () {
                        ref.read(productsProvider.notifier).delete(widget.product!.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product deleted'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field helper ──────────────────────────────────────────
  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    String? hint,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final isEdit = widget.product != null;
    final p = widget.product;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'New Product'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.white,
              tooltip: 'Delete product',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Update Product' : 'Add Product',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGE SECTION ──────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Stack(
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickedImageBytes != null
                            ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: 160, height: 160)
                            : p != null
                                ? ProductImage(
                                    productId: p.id,
                                    imageUrl: p.imageUrl,
                                    width: 160,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    placeholderColor: AppTheme.primaryColor,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 52,
                                          color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                                      const SizedBox(height: 8),
                                      Text('Add Photo',
                                          style: TextStyle(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.6),
                                              fontSize: 13)),
                                    ],
                                  ),
                      ),
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to change product image',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),

              // ── BASIC INFO ──────────────────────────────
              _sectionHeader('Basic Information', Icons.info_outline),
              _field(_nameCtrl, 'Product Name *',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_skuCtrl, 'SKU', hint: 'e.g. GRC001')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _barcodeCtrl,
                      'Barcode',
                      suffix: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                        tooltip: 'Scan barcode',
                        onPressed: _scanBarcode,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v!),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_brandCtrl, 'Brand', hint: 'e.g. Tata')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_unitCtrl, 'Unit', hint: 'pcs / kg / L')),
                ],
              ),

              // ── PRICING ─────────────────────────────────
              _sectionHeader('Pricing', Icons.currency_rupee),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _purchaseCtrl, 'Purchase Price *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _sellingCtrl, 'Selling Price *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: _field(
                  _taxCtrl, 'Tax %',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hint: '0 / 5 / 12 / 18',
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                ),
              ),
              // Live profit preview
              ValueListenableBuilder(
                valueListenable: _purchaseCtrl,
                builder: (ctx, val, child) => ValueListenableBuilder(
                  valueListenable: _sellingCtrl,
                  builder: (ctx2, val2, child2) {
                    final purchase = double.tryParse(_purchaseCtrl.text) ?? 0;
                    final selling = double.tryParse(_sellingCtrl.text) ?? 0;
                    if (purchase <= 0 || selling <= 0) return const SizedBox.shrink();
                    final margin = ((selling - purchase) / purchase) * 100;
                    final profit = selling - purchase;
                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: profit >= 0
                            ? AppTheme.success.withValues(alpha: 0.07)
                            : AppTheme.error.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: profit >= 0
                              ? AppTheme.success.withValues(alpha: 0.3)
                              : AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _profitItem('Profit / Unit', formatCurrency(profit), profit >= 0),
                          Container(width: 1, height: 32, color: Colors.grey[300]),
                          _profitItem('Margin', '${margin.toStringAsFixed(1)}%', profit >= 0),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── INVENTORY ────────────────────────────────
              _sectionHeader('Inventory', Icons.inventory_2_outlined),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _stockCtrl, 'Current Stock',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _minStockCtrl, 'Min Stock Alert',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profitItem(String label, String value, bool positive) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: positive ? AppTheme.success : AppTheme.error)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BARCODE SCANNER PAGE
// ─────────────────────────────────────────────────────────────
class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  late final MobileScannerController _ctrl;
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _scanned = true;
      Navigator.pop(context, barcode!.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
              color: _torchOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              _ctrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 72),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Point camera at barcode or QR code',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 20, right: 20,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.keyboard, color: Colors.white),
              label: const Text('Enter Manually', style: TextStyle(color: Colors.white)),
              onPressed: () => _showManualEntry(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Barcode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'e.g. 8901030682575',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    Navigator.pop(context, ctrl.text.trim());
                  }
                },
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan overlay painter ──────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    const rectSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: rectSize, height: rectSize * 0.65);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );
    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const corner = 20.0;
    final r = rect;
    canvas.drawPath(
        Path()
          ..moveTo(r.left, r.top + corner)
          ..lineTo(r.left, r.top)
          ..lineTo(r.left + corner, r.top),
        cornerPaint);
    canvas.drawPath(
        Path()
          ..moveTo(r.right - corner, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right, r.top + corner),
        cornerPaint);
    canvas.drawPath(
        Path()
          ..moveTo(r.left, r.bottom - corner)
          ..lineTo(r.left, r.bottom)
          ..lineTo(r.left + corner, r.bottom),
        cornerPaint);
    canvas.drawPath(
        Path()
          ..moveTo(r.right - corner, r.bottom)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.right, r.bottom - corner),
        cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
