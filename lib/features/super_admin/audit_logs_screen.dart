import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/formatters.dart';
import '../../app/theme.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColor(log.action).withValues(alpha: 0.1),
              child: Icon(_getIcon(log.action), color: _getColor(log.action), size: 20),
            ),
            title: Text(log.details, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            subtitle: Text(
              '${log.userName} • ${log.module} • ${formatDateTime(log.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getColor(log.action).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                log.action,
                style: TextStyle(fontSize: 11, color: _getColor(log.action), fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColor(String action) {
    switch (action) {
      case 'Created': return AppTheme.success;
      case 'Updated': return AppTheme.info;
      case 'Deleted': return AppTheme.error;
      case 'Deactivated': return AppTheme.warning;
      default: return Colors.grey;
    }
  }

  IconData _getIcon(String action) {
    switch (action) {
      case 'Created': return Icons.add_circle;
      case 'Updated': return Icons.edit;
      case 'Deleted': return Icons.delete;
      case 'Deactivated': return Icons.block;
      default: return Icons.info;
    }
  }
}
