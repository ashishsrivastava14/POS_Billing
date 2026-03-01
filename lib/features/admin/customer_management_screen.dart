import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';

class CustomerManagementScreen extends ConsumerStatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  ConsumerState<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends ConsumerState<CustomerManagementScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final orders = ref.watch(ordersProvider);
    final filtered = customers.where((c) => c.name.toLowerCase().contains(_search.toLowerCase()) || c.phone.contains(_search)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Search by name or phone...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          // Summary row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _summaryChip(Icons.people, '${customers.length}', 'Total'),
                const SizedBox(width: 12),
                _summaryChip(Icons.shopping_cart, '${orders.length}', 'Orders'),
                const SizedBox(width: 12),
                _summaryChip(Icons.currency_rupee, formatCurrency(customers.fold(0.0, (sum, c) => sum + c.totalPurchases)), 'Revenue'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final customer = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(customer.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatCurrency(customer.totalPurchases), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13)),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _showCustomerForm(context, customer: customer);
                            if (v == 'delete') {
                              ref.read(customersProvider.notifier).delete(customer.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.error), title: Text('Delete', style: TextStyle(color: AppTheme.error)))),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _detailItem('Email', customer.email ?? 'N/A'),
                                _detailItem('Orders', '${customer.orderCount}'),
                                _detailItem('Avg. Order', customer.orderCount > 0 ? formatCurrency(customer.totalPurchases / customer.orderCount) : '₹0'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            const SizedBox(height: 8),
                            ...orders.where((o) => o.customerId == customer.id).take(3).map((o) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                o.status.name == 'completed' ? Icons.check_circle : o.status.name == 'cancelled' ? Icons.cancel : Icons.pending,
                                color: o.status.name == 'completed' ? AppTheme.success : o.status.name == 'cancelled' ? AppTheme.error : AppTheme.warning,
                                size: 20,
                              ),
                              title: Text('#${o.id.substring(0, 8)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              subtitle: Text(formatDate(o.createdAt), style: const TextStyle(fontSize: 11)),
                              trailing: Text(formatCurrency(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  void _showCustomerForm(BuildContext context, {Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (optional)'), keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                if (customer == null) {
                  ref.read(customersProvider.notifier).add(Customer(
                    id: 'cust${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
                    createdAt: DateTime.now(),
                  ));
                } else {
                  ref.read(customersProvider.notifier).update(customer.copyWith(
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
                  ));
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(customer == null ? 'Customer added' : 'Customer updated')),
                );
              },
              child: Text(customer == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }
}
