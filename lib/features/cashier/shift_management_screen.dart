import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../models/extras.dart';

class ShiftManagementScreen extends ConsumerWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Shift Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      shift != null ? Icons.timer : Icons.timer_off,
                      size: 56,
                      color: shift != null ? AppTheme.success : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      shift != null ? 'Shift Active' : 'No Active Shift',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: shift != null ? AppTheme.success : Colors.grey,
                      ),
                    ),
                    if (shift != null) ...[
                      const SizedBox(height: 8),
                      Text('Started: ${formatDateTime(shift.openedAt)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text('Cashier: ${shift.cashierName}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: shift == null
                          ? ElevatedButton.icon(
                              onPressed: () {
                                ref.read(shiftProvider.notifier).openShift(
                                  currentUser?.id ?? '',
                                  currentUser?.name ?? '',
                                  5000,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Shift opened successfully'), backgroundColor: AppTheme.success),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Open Shift', style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _confirmCloseShift(context, ref, shift),
                              icon: const Icon(Icons.stop),
                              label: const Text('Close Shift', style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shift Summary
            if (shift != null) ...[
              const Text('Current Shift Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard('Opening Cash', formatCurrency(shift.openingCash), Icons.account_balance_wallet, AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  _summaryCard('Total Sales', formatCurrency(shift.totalSales), Icons.point_of_sale, AppTheme.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard('Transactions', '${shift.totalOrders}', Icons.receipt, AppTheme.accentColor),
                  const SizedBox(width: 12),
                  _summaryCard('Expected Cash', formatCurrency(shift.openingCash + shift.totalSales), Icons.calculate, AppTheme.primaryColor),
                ],
              ),
            ],

            const SizedBox(height: 24),
            // Shift History (mock)
            const Text('Recent Shifts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._mockShiftHistory().map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.grey),
                ),
                title: Text(s['cashier']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${s['date']} • ${s['transactions']} transactions', style: const TextStyle(fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s['sales']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 14)),
                    Text(s['duration']!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCloseShift(BuildContext context, WidgetRef ref, Shift shift) {
    final cashCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Close Shift'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Expected cash in drawer:', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(formatCurrency(shift.openingCash + shift.totalSales), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 16),
                TextField(
                  controller: cashCtrl,
                  decoration: const InputDecoration(labelText: 'Actual Cash Count (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text('Enter the actual cash amount in the drawer', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final closingBalance = double.tryParse(cashCtrl.text) ?? (shift.openingCash + shift.totalSales);
                ref.read(shiftProvider.notifier).closeShift(closingBalance);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shift closed successfully'), backgroundColor: AppTheme.success),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              child: const Text('Close Shift'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, String>> _mockShiftHistory() {
    return [
      {'cashier': 'Deepak Kumar', 'date': '27 Feb 2026', 'transactions': '42', 'sales': '₹28,450', 'duration': '8h 15m'},
      {'cashier': 'Kavitha S', 'date': '26 Feb 2026', 'transactions': '38', 'sales': '₹24,680', 'duration': '7h 45m'},
      {'cashier': 'Ravi P', 'date': '25 Feb 2026', 'transactions': '45', 'sales': '₹31,200', 'duration': '8h 30m'},
      {'cashier': 'Deepak Kumar', 'date': '24 Feb 2026', 'transactions': '36', 'sales': '₹22,100', 'duration': '7h 20m'},
      {'cashier': 'Kavitha S', 'date': '23 Feb 2026', 'transactions': '41', 'sales': '₹26,950', 'duration': '8h 00m'},
    ];
  }
}
