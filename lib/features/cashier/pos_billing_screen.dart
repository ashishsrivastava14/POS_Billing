import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import 'package:go_router/go_router.dart';

class PosBillingScreen extends ConsumerStatefulWidget {
  const PosBillingScreen({super.key});

  @override
  ConsumerState<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends ConsumerState<PosBillingScreen> {
  String _search = '';
  String? _selectedCategoryId;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final cartDiscount = ref.watch(cartDiscountProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    final filteredProducts = products.where((p) {
      if (!p.isActive) return false;
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.barcode.contains(_search) ||
          p.sku.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchSearch && matchCat;
    }).toList();

    if (isWide) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        body: Row(
          children: [
            // Left: Product finder
            Expanded(
              flex: 3,
              child: _buildProductPanel(filteredProducts, categories),
            ),
            // Right: Cart
            SizedBox(
              width: 380,
              child: _buildCartPanel(cart, cartDiscount),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _buildAppBar(showTabs: true),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: [
            _buildProductPanel(filteredProducts, categories),
            _buildCartPanel(cart, cartDiscount),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({bool showTabs = false}) {
    final cart = ref.watch(cartProvider);
    return AppBar(
      title: const Text('POS Billing'),
      actions: [
        // Hold order button
        IconButton(
          icon: const Icon(Icons.pause_circle_outline),
          tooltip: 'Hold Order',
          onPressed: cart.isEmpty ? null : () {
            ref.read(heldOrdersProvider.notifier).state = [...ref.read(heldOrdersProvider), List.from(cart)];
            ref.read(cartProvider.notifier).clearCart();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order held')));
          },
        ),
        // View held orders
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Held Orders',
              onPressed: () => context.push('/cashier/held-orders'),
            ),
            if (ref.watch(heldOrdersProvider).isNotEmpty)
              Positioned(
                right: 4, top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.error),
                  child: Text('${ref.watch(heldOrdersProvider).length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
        // Cart badge for mobile
        if (MediaQuery.of(context).size.width <= 800)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 4, top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.error),
                    child: Text('${cart.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
      ],
      bottom: showTabs ? const TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(icon: Icon(Icons.grid_view), text: 'Products'),
          Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
        ],
      ) : null,
    );
  }

  Widget _buildProductPanel(List<Product> products, List<dynamic> categories) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      _addProductByBarcode(v.trim());
                      _searchController.clear();
                      setState(() => _search = '');
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search or scan barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _search = ''); })
                        : IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _openBarcodeScanner,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Category chips
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) => setState(() => _selectedCategoryId = null),
                ),
              ),
              ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name),
                  selected: _selectedCategoryId == c.id,
                  onSelected: (_) => setState(() => _selectedCategoryId = _selectedCategoryId == c.id ? null : c.id),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Product grid
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No products found', style: TextStyle(color: Colors.grey)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth > 600 ? 4 : constraints.maxWidth > 400 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return _productTile(p);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _productTile(Product product) {
    final isOut = product.isOutOfStock;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOut ? null : () {
          ref.read(cartProvider.notifier).addItem(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${product.name}'), duration: const Duration(milliseconds: 800)),
          );
        },
        child: Opacity(
          opacity: isOut ? 0.5 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrl ?? 'https://picsum.photos/seed/${product.sku}/200/200',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        child: const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        child: const Center(
                          child: Icon(Icons.shopping_bag_outlined, size: 32, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    if (isOut)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
                          child: const Text('OUT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(formatCurrency(product.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                      Text('Stock: ${product.stockQty}', style: TextStyle(fontSize: 10, color: product.isLowStock ? AppTheme.warning : Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(List<CartItem> cart, double? cartDiscount) {
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final totalTax = ref.read(cartProvider.notifier).totalTax;
    final grandTotal = ref.read(cartProvider.notifier).grandTotal;
    final discountAmount = cartDiscount ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Cart (${cart.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clearCart();
                      ref.read(cartDiscountProvider.notifier).state = null;
                    },
                    icon: const Icon(Icons.delete_sweep, size: 18, color: AppTheme.error),
                    label: const Text('Clear', style: TextStyle(color: AppTheme.error)),
                  ),
              ],
            ),
          ),
          // Customer selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: InkWell(
              onTap: _showCustomerPicker,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: ref.watch(selectedCustomerProvider) != null ? AppTheme.primaryColor : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      ref.watch(selectedCustomerProvider)?.name ?? 'Walk-in Customer',
                      style: TextStyle(fontSize: 13, color: ref.watch(selectedCustomerProvider) != null ? null : Colors.grey[600]),
                    ),
                    const Spacer(),
                    if (ref.watch(selectedCustomerProvider) != null)
                      GestureDetector(
                        onTap: () => ref.read(selectedCustomerProvider.notifier).state = null,
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      )
                    else
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          // Cart items
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Cart is empty', style: TextStyle(color: Colors.grey)),
                        Text('Tap products to add', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Dismissible(
                        key: Key(item.productId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: AppTheme.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => ref.read(cartProvider.notifier).removeItem(item.productId),
                        child: ListTile(
                          dense: true,
                          title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('${formatCurrency(item.unitPrice)} × ${item.quantity}', style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  if (item.quantity <= 1) {
                                    ref.read(cartProvider.notifier).removeItem(item.productId);
                                  } else {
                                    ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1);
                                  }
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 65,
                                child: Text(formatCurrency(item.lineTotalWithTax), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Discount apply
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                onTap: _showDiscountDialog,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.accentColor.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.discount, size: 18, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        discountAmount > 0 ? 'Discount: -${formatCurrency(discountAmount)}' : 'Apply Discount',
                        style: TextStyle(fontSize: 13, color: discountAmount > 0 ? AppTheme.accentColor : Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (discountAmount > 0)
                        GestureDetector(
                          onTap: () => ref.read(cartDiscountProvider.notifier).state = null,
                          child: const Icon(Icons.close, size: 18, color: Colors.grey),
                        )
                      else
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          // Totals
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Column(
                children: [
                  _totalRow('Subtotal', formatCurrency(subtotal)),
                  _totalRow('Tax (CGST+SGST)', formatCurrency(totalTax)),
                  if (discountAmount > 0)
                    _totalRow('Discount', '-${formatCurrency(discountAmount)}', color: AppTheme.success),
                  const Divider(),
                  _totalRow('Grand Total', formatCurrency(grandTotal - discountAmount), isBold: true, size: 18),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentModal(grandTotal - discountAmount),
                      icon: const Icon(Icons.payment),
                      label: Text('Pay ${formatCurrency(grandTotal - discountAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false, double size = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: size - 1, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(value, style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? (isBold ? AppTheme.primaryColor : null))),
        ],
      ),
    );
  }

  void _addProductByBarcode(String barcode) {
    final products = ref.read(productsProvider);
    final product = products.where((p) => p.barcode == barcode).firstOrNull;
    if (product != null) {
      if (product.isOutOfStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} is out of stock'), backgroundColor: AppTheme.error),
        );
      } else {
        ref.read(cartProvider.notifier).addItem(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${product.name}'), duration: const Duration(milliseconds: 800), backgroundColor: AppTheme.success),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product not found for barcode: $barcode'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _openBarcodeScanner() {
    final barcodeCtrl = TextEditingController();
    bool scanned = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                const Text('Barcode Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                // Camera scanner
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (scanned) return;
                        final bc = capture.barcodes.firstOrNull?.rawValue;
                        if (bc != null && bc.isNotEmpty) {
                          scanned = true;
                          Navigator.pop(ctx);
                          _addProductByBarcode(bc);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR enter manually', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter barcode...',
                          prefixIcon: Icon(Icons.keyboard),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (v) {
                          if (v.isNotEmpty) {
                            Navigator.pop(ctx);
                            _addProductByBarcode(v.trim());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (barcodeCtrl.text.isNotEmpty) {
                          Navigator.pop(ctx);
                          _addProductByBarcode(barcodeCtrl.text.trim());
                        }
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCustomerPicker() {
    final customers = ref.read(customersProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(builder: (ctx, setS) {
          final filtered = customers.where((c) => c.name.toLowerCase().contains(search.toLowerCase()) || c.phone.contains(search)).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (ctx, scrollCtrl) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setS(() => search = v),
                      decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search)),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final c = filtered[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(c.name[0])),
                            title: Text(c.name),
                            subtitle: Text(c.phone),
                            onTap: () {
                              ref.read(selectedCustomerProvider.notifier).state = c;
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  void _showDiscountDialog() {
    final ctrl = TextEditingController();
    String type = 'flat';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            title: const Text('Apply Discount'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'flat', label: Text('Flat ₹')),
                    ButtonSegment(value: 'percentage', label: Text('% Off')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setS(() => type = v.first),
                ),
                const SizedBox(height: 16),
                TextField(controller: ctrl, decoration: InputDecoration(labelText: type == 'flat' ? 'Amount (₹)' : 'Percentage (%)'), keyboardType: TextInputType.number),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(ctrl.text) ?? 0;
                  if (val <= 0) return;
                  final grandTotal = ref.read(cartProvider.notifier).grandTotal;
                  final discount = type == 'flat' ? val : grandTotal * val / 100;
                  ref.read(cartDiscountProvider.notifier).state = discount;
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showPaymentModal(double amount) {
    PaymentMode selectedMode = PaymentMode.cash;
    final cashCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          final change = (double.tryParse(cashCtrl.text) ?? 0) - amount;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                Text(formatCurrency(amount), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 20),
                SegmentedButton<PaymentMode>(
                  segments: const [
                    ButtonSegment(value: PaymentMode.cash, icon: Icon(Icons.money), label: Text('Cash')),
                    ButtonSegment(value: PaymentMode.card, icon: Icon(Icons.credit_card), label: Text('Card')),
                    ButtonSegment(value: PaymentMode.upi, icon: Icon(Icons.qr_code), label: Text('UPI')),
                  ],
                  selected: {selectedMode},
                  onSelectionChanged: (v) => setS(() => selectedMode = v.first),
                ),
                const SizedBox(height: 20),
                if (selectedMode == PaymentMode.cash) ...[
                  TextField(
                    controller: cashCtrl,
                    decoration: const InputDecoration(labelText: 'Cash Tendered (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (change >= 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Change: ', style: TextStyle(fontSize: 16)),
                          Text(formatCurrency(change), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.success)),
                        ],
                      ),
                    ),
                ],
                if (selectedMode == PaymentMode.card)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.credit_card, size: 48, color: AppTheme.primaryColor),
                        SizedBox(height: 8),
                        Text('Swipe / Insert / Tap card', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                if (selectedMode == PaymentMode.upi)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code, size: 48, color: AppTheme.primaryColor),
                        SizedBox(height: 8),
                        Text('Scan QR code to pay', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedMode == PaymentMode.cash && change < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insufficient cash tendered')),
                        );
                        return;
                      }
                      _completeOrder(selectedMode, double.tryParse(cashCtrl.text) ?? amount);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                    child: const Text('Complete Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  void _completeOrder(PaymentMode mode, double cashTendered) {
    final cart = ref.read(cartProvider);
    final discount = ref.read(cartDiscountProvider) ?? 0.0;
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final tax = ref.read(cartProvider.notifier).totalTax;
    final grand = ref.read(cartProvider.notifier).grandTotal - discount;
    final customer = ref.read(selectedCustomerProvider);

    final order = Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: 'INV${DateTime.now().millisecondsSinceEpoch}',
      vendorId: 'v1',
      createdAt: DateTime.now(),
      customerId: customer?.id,
      customerName: customer?.name ?? 'Walk-in',
      items: cart,
      subtotal: subtotal,
      taxAmount: tax,
      discountAmount: discount,
      totalAmount: grand,
      paymentMode: mode,
      cashTendered: mode == PaymentMode.cash ? cashTendered : null,
      changeAmount: mode == PaymentMode.cash ? cashTendered - grand : null,
      status: OrderStatus.completed,
      cashierId: ref.read(authProvider)?.id ?? '',
      cashierName: ref.read(authProvider)?.name ?? '',
    );

    ref.read(ordersProvider.notifier).add(order);
    ref.read(cartProvider.notifier).clearCart();
    ref.read(cartDiscountProvider.notifier).state = null;
    ref.read(selectedCustomerProvider.notifier).state = null;

    // Record sale in shift
    ref.read(shiftProvider.notifier).recordSale(grand);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order completed successfully! ✓'), backgroundColor: AppTheme.success),
    );

    // Navigate to invoice
    context.push('/cashier/invoice/${order.id}');
  }
}
