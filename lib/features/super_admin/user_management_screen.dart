import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/user.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final filtered = users.where((u) {
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<UserRole?>(
                  value: _roleFilter,
                  hint: const Text('All Roles'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Roles')),
                    ...UserRole.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r == UserRole.superAdmin ? 'Super Admin' : r == UserRole.admin ? 'Admin' : 'Cashier'),
                    )),
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final user = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                      child: Text(
                        user.name[0],
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getRoleColor(user.role)),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.roleLabel,
                            style: TextStyle(fontSize: 11, color: _getRoleColor(user.role), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (user.vendorName != null)
                          Text(user.vendorName!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.isActive ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'toggle') {
                              ref.read(usersProvider.notifier).toggleActive(user.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(user.isActive ? 'User deactivated' : 'User activated')),
                              );
                            } else if (action == 'reset') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password reset link sent (mock)')),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'toggle', child: Text(user.isActive ? 'Deactivate' : 'Activate')),
                            const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                          ],
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return AppTheme.error;
      case UserRole.admin: return AppTheme.primaryColor;
      case UserRole.cashier: return AppTheme.success;
    }
  }
}
