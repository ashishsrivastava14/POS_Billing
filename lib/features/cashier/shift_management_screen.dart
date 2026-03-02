import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../models/extras.dart';
import '../../models/order.dart';

class ShiftManagementScreen extends ConsumerStatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  ConsumerState<ShiftManagementScreen> createState() =>
      _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends ConsumerState<ShiftManagementScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final shift = ref.read(shiftProvider);
      if (shift != null && shift.isOpen) {
        setState(() {
          _elapsed = DateTime.now().difference(shift.openedAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showOpenShiftDialog() {
    final cashCtrl = TextEditingController(text: '5000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open New Shift'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the opening cash amount in the drawer:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cashCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Opening Cash (Rs.)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Open Shift'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final cash = double.tryParse(cashCtrl.text) ?? 0;
              final currentUser = ref.read(authProvider);
              ref
                  .read(shiftProvider.notifier)
                  .openShift(
                    currentUser?.id ?? '',
                    currentUser?.name ?? '',
                    cash,
                  );
              ref.read(cashMovementsProvider.notifier).state = [];
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shift opened with ${formatCurrency(cash)} opening cash',
                  ),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCashMovementDialog({required bool isIn}) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIn ? 'Cash In' : 'Cash Out'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (Rs.)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color: isIn ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason / Note',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isIn ? AppTheme.success : AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              final movements = List<Map<String, dynamic>>.from(
                ref.read(cashMovementsProvider),
              );
              movements.add({
                'type': isIn ? 'in' : 'out',
                'amount': amount,
                'note': noteCtrl.text.trim().isEmpty
                    ? (isIn ? 'Cash In' : 'Cash Out')
                    : noteCtrl.text.trim(),
                'time': DateTime.now(),
              });
              ref.read(cashMovementsProvider.notifier).state = movements;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${isIn ? 'Cash In' : 'Cash Out'}: ${formatCurrency(amount)} recorded',
                  ),
                  backgroundColor: isIn ? AppTheme.success : AppTheme.error,
                ),
              );
            },
            child: Text(isIn ? 'Record Cash In' : 'Record Cash Out'),
          ),
        ],
      ),
    );
  }

  void _confirmCloseShift(Shift shift) {
    final cashCtrl = TextEditingController();
    final movements = ref.read(cashMovementsProvider);
    final cashIn = movements
        .where((m) => m['type'] == 'in')
        .fold<double>(0, (s, m) => s + (m['amount'] as double));
    final cashOut = movements
        .where((m) => m['type'] == 'out')
        .fold<double>(0, (s, m) => s + (m['amount'] as double));
    final expectedCash =
        shift.openingCash + shift.totalSales + cashIn - cashOut;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            double? actualCash;
            double variance = 0;
            return AlertDialog(
              title: const Text('Close Shift'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogRow(
                      'Opening Cash',
                      formatCurrency(shift.openingCash),
                    ),
                    _dialogRow(
                      'Total Sales',
                      formatCurrency(shift.totalSales),
                      color: AppTheme.success,
                    ),
                    if (cashIn > 0)
                      _dialogRow(
                        'Cash In',
                        '+${formatCurrency(cashIn)}',
                        color: AppTheme.success,
                      ),
                    if (cashOut > 0)
                      _dialogRow(
                        'Cash Out',
                        '-${formatCurrency(cashOut)}',
                        color: AppTheme.error,
                      ),
                    const Divider(height: 16),
                    _dialogRow(
                      'Expected in Drawer',
                      formatCurrency(expectedCash),
                      isBold: true,
                      color: AppTheme.primaryColor,
                      fontSize: 15,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cashCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Actual Cash Count (Rs.)',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final entered = double.tryParse(v);
                        setStateDialog(() {
                          actualCash = entered;
                          variance = entered != null
                              ? entered - expectedCash
                              : 0;
                        });
                      },
                    ),
                    if (actualCash != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            variance >= 0 ? 'Overage' : 'Shortage',
                            style: TextStyle(
                              fontSize: 13,
                              color: variance >= 0
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                          Text(
                            formatCurrency(variance.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: variance >= 0
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Close Shift'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final closing =
                        double.tryParse(cashCtrl.text) ?? expectedCash;
                    final closedShift = shift.copyWith(
                      closingCash: closing,
                      closedAt: DateTime.now(),
                      isOpen: false,
                    );
                    final history = List<Shift>.from(
                      ref.read(shiftHistoryProvider),
                    );
                    history.insert(0, closedShift);
                    ref.read(shiftHistoryProvider.notifier).state = history;
                    ref.read(shiftProvider.notifier).closeShift(closing);
                    ref.read(cashMovementsProvider.notifier).state = [];
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shift closed successfully'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = ref.watch(shiftProvider);
    final movements = ref.watch(cashMovementsProvider);
    final history = ref.watch(shiftHistoryProvider);
    final orders = ref.watch(ordersProvider);

    List<Order> shiftOrders = [];
    if (shift != null && shift.isOpen) {
      shiftOrders = orders
          .where(
            (o) =>
                o.status == OrderStatus.completed &&
                o.createdAt.isAfter(shift.openedAt),
          )
          .toList();
    }
    final cashSales = shiftOrders
        .where((o) => o.paymentMode == PaymentMode.cash)
        .fold<double>(0, (s, o) => s + o.totalAmount);
    final cardSales = shiftOrders
        .where((o) => o.paymentMode == PaymentMode.card)
        .fold<double>(0, (s, o) => s + o.totalAmount);
    final upiSales = shiftOrders
        .where((o) => o.paymentMode == PaymentMode.upi)
        .fold<double>(0, (s, o) => s + o.totalAmount);

    final cashIn = movements
        .where((m) => m['type'] == 'in')
        .fold<double>(0, (s, m) => s + (m['amount'] as double));
    final cashOut = movements
        .where((m) => m['type'] == 'out')
        .fold<double>(0, (s, m) => s + (m['amount'] as double));

    if (shift != null && shift.isOpen) {
      _elapsed = DateTime.now().difference(shift.openedAt);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/cashier/billing'),
        ),
        actions: [
          if (shift != null && shift.isOpen) ...[
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Cash In',
              onPressed: () => _showCashMovementDialog(isIn: true),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Cash Out',
              onPressed: () => _showCashMovementDialog(isIn: false),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Shift Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      shift != null && shift.isOpen
                          ? Icons.timer
                          : Icons.timer_off,
                      size: 56,
                      color: shift != null && shift.isOpen
                          ? AppTheme.success
                          : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shift != null && shift.isOpen
                          ? 'Shift Active'
                          : 'No Active Shift',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: shift != null && shift.isOpen
                            ? AppTheme.success
                            : Colors.grey,
                      ),
                    ),
                    if (shift != null && shift.isOpen) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatDuration(_elapsed),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Started: ${formatDateTime(shift.openedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Cashier: ${shift.cashierName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: shift == null || !shift.isOpen
                          ? ElevatedButton.icon(
                              onPressed: _showOpenShiftDialog,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text(
                                'Open Shift',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _confirmCloseShift(shift),
                              icon: const Icon(Icons.stop),
                              label: const Text(
                                'Close Shift',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Active Shift Details
            if (shift != null && shift.isOpen) ...[
              const SizedBox(height: 24),
              const Text(
                'Current Shift Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard(
                    'Opening Cash',
                    formatCurrency(shift.openingCash),
                    Icons.account_balance_wallet,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _summaryCard(
                    'Total Sales',
                    formatCurrency(shift.totalSales),
                    Icons.point_of_sale,
                    AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard(
                    'Transactions',
                    '${shift.totalOrders}',
                    Icons.receipt,
                    AppTheme.accentColor,
                  ),
                  const SizedBox(width: 12),
                  _summaryCard(
                    'Expected Cash',
                    formatCurrency(
                      shift.openingCash + cashSales + cashIn - cashOut,
                    ),
                    Icons.calculate,
                    AppTheme.primaryColor,
                  ),
                ],
              ),

              // Payment Breakdown
              const SizedBox(height: 20),
              const Text(
                'Payment Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _paymentRow(
                        Icons.money,
                        'Cash',
                        cashSales,
                        Colors.green[700]!,
                      ),
                      const Divider(height: 16),
                      _paymentRow(
                        Icons.credit_card,
                        'Card',
                        cardSales,
                        Colors.blue[700]!,
                      ),
                      const Divider(height: 16),
                      _paymentRow(
                        Icons.qr_code,
                        'UPI',
                        upiSales,
                        Colors.purple[700]!,
                      ),
                      const Divider(height: 16),
                      _paymentRow(
                        Icons.summarize,
                        'Total',
                        cashSales + cardSales + upiSales,
                        AppTheme.primaryColor,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Cash Movements Log
              if (movements.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Cash Movements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ...movements.map(
                  (m) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor:
                            (m['type'] == 'in'
                                    ? AppTheme.success
                                    : AppTheme.error)
                                .withValues(alpha: 0.12),
                        child: Icon(
                          m['type'] == 'in'
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          color: m['type'] == 'in'
                              ? AppTheme.success
                              : AppTheme.error,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        m['note'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        formatDateTime(m['time'] as DateTime),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      trailing: Text(
                        '${m['type'] == 'in' ? '+' : '-'}${formatCurrency(m['amount'] as double)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: m['type'] == 'in'
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Quick Cash In/Out Buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCashMovementDialog(isIn: true),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.success,
                      ),
                      label: const Text(
                        'Cash In',
                        style: TextStyle(color: AppTheme.success),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCashMovementDialog(isIn: false),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppTheme.error,
                      ),
                      label: const Text(
                        'Cash Out',
                        style: TextStyle(color: AppTheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Shift History
            const SizedBox(height: 28),
            const Text(
              'Recent Shifts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              ..._mockShiftHistory().map(_buildHistoryTile)
            else ...[
              ...history.map(_buildShiftTile),
              ..._mockShiftHistory().map(_buildHistoryTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTile(Shift s) {
    final duration = s.closedAt != null
        ? s.closedAt!.difference(s.openedAt)
        : Duration.zero;
    final variance = (s.closingCash ?? 0) - (s.openingCash + s.totalSales);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          s.cashierName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${formatDateTime(s.openedAt)}  ${s.totalOrders} transactions',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(s.totalSales),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
                fontSize: 14,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (variance != 0)
              Text(
                variance >= 0
                    ? '+${formatCurrency(variance)}'
                    : '-${formatCurrency(variance.abs())}',
                style: TextStyle(
                  fontSize: 10,
                  color: variance >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, String> s) {
    return Card(
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
        title: Text(
          s['cashier']!,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${s['date']}  ${s['transactions']} transactions',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              s['sales']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
                fontSize: 14,
              ),
            ),
            Text(
              s['duration']!,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentRow(
    IconData icon,
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _mockShiftHistory() {
    return [
      {
        'cashier': 'Deepak Kumar',
        'date': '27 Feb 2026',
        'transactions': '42',
        'sales': 'Rs.28,450',
        'duration': '8h 15m',
      },
      {
        'cashier': 'Kavitha S',
        'date': '26 Feb 2026',
        'transactions': '38',
        'sales': 'Rs.24,680',
        'duration': '7h 45m',
      },
      {
        'cashier': 'Ravi P',
        'date': '25 Feb 2026',
        'transactions': '45',
        'sales': 'Rs.31,200',
        'duration': '8h 30m',
      },
      {
        'cashier': 'Deepak Kumar',
        'date': '24 Feb 2026',
        'transactions': '36',
        'sales': 'Rs.22,100',
        'duration': '7h 20m',
      },
      {
        'cashier': 'Kavitha S',
        'date': '23 Feb 2026',
        'transactions': '41',
        'sales': 'Rs.26,950',
        'duration': '8h 00m',
      },
    ];
  }
}
