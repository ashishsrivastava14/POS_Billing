import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/user.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _search = '';
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final staffUsers = users.where((u) => u.role != UserRole.superAdmin).toList();
    final filtered = staffUsers.where((u) {
      final matchSearch = u.name.toLowerCase().contains(_search.toLowerCase()) || u.email.toLowerCase().contains(_search.toLowerCase());
      final matchRole = _roleFilter == null || u.role == _roleFilter;
      return matchSearch && matchRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Search staff...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Admin'),
                  selected: _roleFilter == UserRole.admin,
                  onSelected: (_) => setState(() => _roleFilter = _roleFilter == UserRole.admin ? null : UserRole.admin),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Cashier'),
                  selected: _roleFilter == UserRole.cashier,
                  onSelected: (_) => setState(() => _roleFilter = _roleFilter == UserRole.cashier ? null : UserRole.cashier),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final user = filtered[index];
                final roleColor = user.role == UserRole.admin ? AppTheme.primaryColor : AppTheme.accentColor;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.1),
                      child: Text(user.name[0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(user.roleLabel, style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.isActive ? AppTheme.success : Colors.grey,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            switch (v) {
                              case 'edit':
                                _showStaffForm(context, user: user);
                                break;
                              case 'toggle':
                                ref.read(usersProvider.notifier).toggleActive(user.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(user.isActive ? 'Staff deactivated' : 'Staff activated')),
                                );
                                break;
                              case 'reset':
                                _showResetPasswordDialog(context, user);
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                            PopupMenuItem(value: 'toggle', child: ListTile(leading: Icon(user.isActive ? Icons.block : Icons.check_circle), title: Text(user.isActive ? 'Deactivate' : 'Activate'))),
                            const PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(Icons.lock_reset), title: Text('Reset Password'))),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppUser user) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Reset Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setting new password for ${user.name}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm password';
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Reset'),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                ref.read(usersProvider.notifier).update(
                      user.copyWith(password: newPassCtrl.text.trim()),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset for ${user.name}'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffForm(BuildContext context, {AppUser? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    UserRole selectedRole = user?.role ?? UserRole.cashier;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(user == null ? 'Add Staff' : 'Edit Staff'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: [UserRole.admin, UserRole.cashier].map((r) => DropdownMenuItem(value: r, child: Text(r == UserRole.admin ? 'Admin' : 'Cashier'))).toList(),
                      onChanged: (v) => setDialogState(() => selectedRole = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                    if (user == null) {
                      ref.read(usersProvider.notifier).add(AppUser(
                        id: 'u${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        password: 'default123',
                        role: selectedRole,
                        vendorId: 'v1',
                        createdAt: DateTime.now(),
                      ));
                    } else {
                      ref.read(usersProvider.notifier).update(user.copyWith(
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        role: selectedRole,
                      ));
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(user == null ? 'Staff added' : 'Staff updated')),
                    );
                  },
                  child: Text(user == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
