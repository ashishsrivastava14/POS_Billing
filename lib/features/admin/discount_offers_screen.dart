import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../models/extras.dart';

class DiscountOffersScreen extends ConsumerStatefulWidget {
  const DiscountOffersScreen({super.key});

  @override
  ConsumerState<DiscountOffersScreen> createState() => _DiscountOffersScreenState();
}

class _DiscountOffersScreenState extends ConsumerState<DiscountOffersScreen> {
  @override
  Widget build(BuildContext context) {
    final discounts = ref.watch(discountsProvider);
    final now = DateTime.now();
    final activeDiscounts = discounts.where((d) => d.isActive && d.endDate.isAfter(now)).toList();
    final expired = discounts.where((d) => d.endDate.isBefore(now) || !d.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Discounts & Offers')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDiscountForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Offer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats row
          Row(
            children: [
              _statCard('Active', '${activeDiscounts.length}', AppTheme.success),
              const SizedBox(width: 12),
              _statCard('Expired', '${expired.length}', Colors.grey),
              const SizedBox(width: 12),
              _statCard('Total', '${discounts.length}', AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Active Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (activeDiscounts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No active offers', style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            ...activeDiscounts.map((d) => _discountCard(d, true)),
          const SizedBox(height: 24),
          const Text('Expired / Inactive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (expired.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No expired offers', style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            ...expired.map((d) => _discountCard(d, false)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _discountCard(Discount discount, bool isActive) {
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
                    color: (isActive ? AppTheme.accentColor : Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    discount.type == 'percentage' ? Icons.percent : Icons.currency_rupee,
                    color: isActive ? AppTheme.accentColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discount.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        discount.type == 'percentage' ? '${discount.value}% off' : '₹${discount.value} off',
                        style: TextStyle(color: isActive ? AppTheme.accentColor : Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showDiscountForm(context, discount: discount);
                    if (v == 'toggle') {
                      ref.read(discountsProvider.notifier).update(discount.copyWith(isActive: !discount.isActive));
                    }
                    if (v == 'delete') {
                      ref.read(discountsProvider.notifier).delete(discount.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discount deleted')));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                    PopupMenuItem(value: 'toggle', child: ListTile(
                      leading: Icon(discount.isActive ? Icons.pause_circle : Icons.play_circle),
                      title: Text(discount.isActive ? 'Deactivate' : 'Activate'),
                    )),
                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.error), title: Text('Delete', style: TextStyle(color: AppTheme.error)))),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem('Start', formatDate(discount.startDate)),
                _infoItem('End', formatDate(discount.endDate)),
                _infoItem('Status', isActive ? 'Active' : 'Expired'),
                _infoItem('Scope', discount.productId != null ? 'Product' : discount.categoryId != null ? 'Category' : 'All'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }

  void _showDiscountForm(BuildContext context, {Discount? discount}) {
    final nameCtrl = TextEditingController(text: discount?.name ?? '');
    final valueCtrl = TextEditingController(text: discount?.value.toString() ?? '');
    String type = discount?.type ?? 'percentage';
    DateTime startDate = discount?.startDate ?? DateTime.now();
    DateTime endDate = discount?.endDate ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = discount?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(discount == null ? 'Create Offer' : 'Edit Offer'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Offer Name')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Discount Type'),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                          DropdownMenuItem(value: 'flat', child: Text('Flat Amount (₹)')),
                        ],
                        onChanged: (v) => setDialogState(() => type = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: valueCtrl, decoration: InputDecoration(labelText: type == 'percentage' ? 'Percentage' : 'Amount (₹)'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
                                if (d != null) setDialogState(() => startDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Start Date'),
                                child: Text(formatDate(startDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: ctx, initialDate: endDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
                                if (d != null) setDialogState(() => endDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'End Date'),
                                child: Text(formatDate(endDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (v) => setDialogState(() => isActive = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    if (discount == null) {
                      ref.read(discountsProvider.notifier).add(Discount(
                        id: 'd${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text,
                        type: type,
                        value: double.tryParse(valueCtrl.text) ?? 0,
                        startDate: startDate,
                        endDate: endDate,
                        isActive: isActive,
                      ));
                    } else {
                      ref.read(discountsProvider.notifier).update(discount.copyWith(
                        name: nameCtrl.text,
                        type: type,
                        value: double.tryParse(valueCtrl.text),
                        startDate: startDate,
                        endDate: endDate,
                        isActive: isActive,
                      ));
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(discount == null ? 'Offer created' : 'Offer updated')),
                    );
                  },
                  child: Text(discount == null ? 'Create' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
