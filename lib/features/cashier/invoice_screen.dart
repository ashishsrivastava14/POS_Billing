import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';

class InvoiceScreen extends ConsumerWidget {
  final String orderId;
  const InvoiceScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final order = orders.where((o) => o.id == orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing invoice (mock)...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing PDF (mock)...')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Icon(Icons.store, size: 40, color: AppTheme.primaryColor),
                  const SizedBox(height: 8),
                  const Text(AppConstants.shopName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(AppConstants.shopAddress, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
                  Text('GST: ${AppConstants.gstNumber}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const Divider(height: 24),

                  // Order info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invoice #${order.id.substring(0, 12)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(formatDateTime(order.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer: ${order.customerName}', style: const TextStyle(fontSize: 12)),
                      Text('Cashier: ${order.cashierName}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  const Divider(height: 24),

                  // Items table header
                  const Row(
                    children: [
                      Expanded(flex: 4, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                    ],
                  ),
                  const Divider(),

                  // Items
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(item.productName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                              Expanded(flex: 1, child: Text('${item.quantity}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text(formatCurrency(item.unitPrice), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text(formatCurrency(item.lineTotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),

                  // Totals
                  _invoiceRow('Subtotal', formatCurrency(order.subtotal)),
                  if (order.discountAmount > 0)
                    _invoiceRow('Discount', '-${formatCurrency(order.discountAmount)}', color: AppTheme.success),
                  _invoiceRow('CGST', formatCurrency(order.taxAmount / 2)),
                  _invoiceRow('SGST', formatCurrency(order.taxAmount / 2)),
                  const Divider(),
                  _invoiceRow('Grand Total', formatCurrency(order.totalAmount), isBold: true, size: 16),
                  const SizedBox(height: 8),
                  _invoiceRow('Payment', order.paymentMode.name.toUpperCase()),
                  if (order.cashTendered != null)
                    _invoiceRow('Cash Tendered', formatCurrency(order.cashTendered!)),
                  if (order.changeAmount != null && order.changeAmount! > 0)
                    _invoiceRow('Change', formatCurrency(order.changeAmount!), color: AppTheme.success),

                  const Divider(height: 24),
                  Text(AppConstants.receiptFooter, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  // Barcode mock
                  Container(
                    height: 40,
                    width: 160,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
                    child: const Center(child: Text('||||||||||||||||||||', style: TextStyle(letterSpacing: -1.5, fontSize: 18))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/cashier/billing'),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('New Sale'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF generated (mock)')),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Save PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool isBold = false, double size = 12, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: size, color: color)),
          Text(value, style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? (isBold ? AppTheme.primaryColor : null))),
        ],
      ),
    );
  }
}
