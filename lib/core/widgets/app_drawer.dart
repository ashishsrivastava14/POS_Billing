import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/user.dart';
import '../../app/theme.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            accountName: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            otherAccountsPictures: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    user.roleLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._buildMenuItems(context, user.role),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return [
          _buildDrawerItem(context, icon: Icons.dashboard, title: 'Dashboard', route: '/super-admin'),
          _buildDrawerItem(context, icon: Icons.store, title: 'Vendor Management', route: '/super-admin/vendors'),
          _buildDrawerItem(context, icon: Icons.people, title: 'User Management', route: '/super-admin/users'),
          _buildDrawerItem(context, icon: Icons.bar_chart, title: 'System Reports', route: '/super-admin/reports'),
          _buildDrawerItem(context, icon: Icons.history, title: 'Audit Logs', route: '/super-admin/audit-logs'),
          const Divider(),
          _buildDrawerItem(context, icon: Icons.assessment, title: 'Sales Report', route: '/reports/sales'),
          _buildDrawerItem(context, icon: Icons.inventory_2, title: 'Inventory Report', route: '/reports/inventory'),
          _buildDrawerItem(context, icon: Icons.receipt_long, title: 'Tax Report', route: '/reports/tax'),
        ];
      case UserRole.admin:
        return [
          _buildDrawerItem(context, icon: Icons.dashboard, title: 'Dashboard', route: '/admin'),
          _buildDrawerItem(context, icon: Icons.inventory, title: 'Products', route: '/admin/products'),
          _buildDrawerItem(context, icon: Icons.category, title: 'Categories', route: '/admin/categories'),
          _buildDrawerItem(context, icon: Icons.warehouse, title: 'Inventory', route: '/admin/inventory'),
          _buildDrawerItem(context, icon: Icons.badge, title: 'Staff', route: '/admin/staff'),
          _buildDrawerItem(context, icon: Icons.group, title: 'Customers', route: '/admin/customers'),
          _buildDrawerItem(context, icon: Icons.local_offer, title: 'Discounts & Offers', route: '/admin/discounts'),
          const Divider(),
          _buildDrawerItem(context, icon: Icons.assessment, title: 'Sales Report', route: '/reports/sales'),
          _buildDrawerItem(context, icon: Icons.inventory_2, title: 'Inventory Report', route: '/reports/inventory'),
          _buildDrawerItem(context, icon: Icons.receipt_long, title: 'Tax Report', route: '/reports/tax'),
        ];
      case UserRole.cashier:
        return [
          _buildDrawerItem(context, icon: Icons.point_of_sale, title: 'POS Billing', route: '/cashier'),
          _buildDrawerItem(context, icon: Icons.pause_circle, title: 'Held Orders', route: '/cashier/hold-orders'),
          _buildDrawerItem(context, icon: Icons.schedule, title: 'Shift Management', route: '/cashier/shift'),
        ];
    }
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? AppTheme.primaryColor : null,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
