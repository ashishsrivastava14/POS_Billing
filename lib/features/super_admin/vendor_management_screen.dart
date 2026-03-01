import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../models/vendor.dart';

class VendorManagementScreen extends ConsumerStatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  ConsumerState<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends ConsumerState<VendorManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);
    final filtered = vendors.where((v) =>
      v.shopName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      v.ownerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      v.city.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVendorForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vendor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final vendor = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      radius: 28,
                      child: Text(
                        vendor.shopName[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    title: Text(vendor.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${vendor.ownerName} • ${vendor.city}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: vendor.isActive ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                vendor.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: vendor.isActive ? AppTheme.success : AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                vendor.plan,
                                style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatCompactCurrency(vendor.totalRevenue),
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showVendorForm(context, vendor: vendor);
                        } else if (action == 'toggle') {
                          ref.read(vendorsProvider.notifier).toggleActive(vendor.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(vendor.isActive ? 'Vendor deactivated' : 'Vendor activated')),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(vendor.isActive ? 'Deactivate' : 'Activate'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVendorForm(BuildContext context, {Vendor? vendor}) {
    final nameCtrl = TextEditingController(text: vendor?.shopName ?? '');
    final ownerCtrl = TextEditingController(text: vendor?.ownerName ?? '');
    final emailCtrl = TextEditingController(text: vendor?.email ?? '');
    final phoneCtrl = TextEditingController(text: vendor?.phone ?? '');
    final addressCtrl = TextEditingController(text: vendor?.address ?? '');
    final cityCtrl = TextEditingController(text: vendor?.city ?? '');
    final gstCtrl = TextEditingController(text: vendor?.gstNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vendor == null ? 'Add Vendor' : 'Edit Vendor'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shop Name')),
                const SizedBox(height: 12),
                TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'Owner Name')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 12),
                TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 12),
                TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST Number')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              if (vendor == null) {
                ref.read(vendorsProvider.notifier).add(Vendor(
                  id: 'v${DateTime.now().millisecondsSinceEpoch}',
                  shopName: nameCtrl.text,
                  ownerName: ownerCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                  city: cityCtrl.text,
                  gstNumber: gstCtrl.text,
                  plan: 'Standard',
                  joinedDate: DateTime.now(),
                ));
              } else {
                ref.read(vendorsProvider.notifier).update(vendor.copyWith(
                  shopName: nameCtrl.text,
                  ownerName: ownerCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                  city: cityCtrl.text,
                  gstNumber: gstCtrl.text,
                ));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(vendor == null ? 'Vendor added' : 'Vendor updated')),
              );
            },
            child: Text(vendor == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
