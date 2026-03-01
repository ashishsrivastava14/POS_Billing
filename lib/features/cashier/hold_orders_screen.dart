import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';

class HoldOrdersScreen extends ConsumerWidget {
  const HoldOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldOrders = ref.watch(heldOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Held Orders (${heldOrders.length})')),
      body: heldOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No held orders', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Orders you park will appear here', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: heldOrders.length,
              itemBuilder: (context, index) {
                final items = heldOrders[index];
                final total = items.fold<double>(0, (s, i) => s + i.lineTotalWithTax);
                final itemCount = items.fold<int>(0, (s, i) => s + i.quantity);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.pause_circle, color: AppTheme.warning),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Held Order #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('$itemCount items • ${items.length} products', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Text(formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                          ],
                        ),
                        const Divider(height: 20),
                        // Item preview
                        ...items.take(3).map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 13))),
                              Text('×${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              Text(formatCurrency(item.lineTotalWithTax), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                        if (items.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('+ ${items.length - 3} more items...', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Delete held order
                                  final updated = [...heldOrders]..removeAt(index);
                                  ref.read(heldOrdersProvider.notifier).state = updated;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Held order deleted')));
                                },
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                                label: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(cartProvider.notifier).restoreCart(items);
                                  final updated = [...heldOrders]..removeAt(index);
                                  ref.read(heldOrdersProvider.notifier).state = updated;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order resumed'), backgroundColor: AppTheme.success),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Resume'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
