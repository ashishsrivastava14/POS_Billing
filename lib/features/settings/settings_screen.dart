import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Shop Settings
  final _shopNameCtrl = TextEditingController(text: AppConstants.shopName);
  final _shopAddressCtrl = TextEditingController(text: AppConstants.shopAddress);
  final _gstCtrl = TextEditingController(text: AppConstants.gstNumber);
  final _phoneCtrl = TextEditingController(text: '080-12345678');

  // Receipt settings
  late final TextEditingController _receiptHeaderCtrl;
  late final TextEditingController _receiptFooterCtrl;
  bool _showLogo = true;
  bool _showGST = true;
  String _paperSize = '80mm';

  // Currency
  Map<String, String> _selectedCurrency = {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'icon': 'currency_rupee'};

  // Tax settings
  bool _gstEnabled = true;
  bool _inclusiveTax = false;
  double _defaultTaxRate = 18.0;

  // Bluetooth printer
  String? _btConnectedDevice;
  bool _btScanning = false;

  // Data management
  DateTime? _lastBackupTime;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    final rs = ref.read(receiptSettingsProvider);
    _paperSize = rs.paperSize;
    _showLogo  = rs.showLogo;
    _showGST   = rs.showGST;
    _receiptHeaderCtrl = TextEditingController(text: rs.header);
    _receiptFooterCtrl = TextEditingController(text: rs.footer);
    final ts = ref.read(taxSettingsProvider);
    _gstEnabled    = ts.gstEnabled;
    _inclusiveTax  = ts.inclusiveTax;
    _defaultTaxRate = ts.defaultTaxRate;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _gstCtrl.dispose();
    _phoneCtrl.dispose();
    _receiptHeaderCtrl.dispose();
    _receiptFooterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      (currentUser?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentUser?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(currentUser?.email ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(currentUser?.roleLabel ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditProfileDialog(currentUser),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Preferences
          _sectionHeader('App Preferences', Icons.tune),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryColor),
                  value: isDarkMode,
                  onChanged: (v) => ref.read(isDarkModeProvider.notifier).state = v,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.primaryColor),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguagePicker(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(_currencyIcon(_selectedCurrency['icon']!), color: AppTheme.primaryColor),
                  title: const Text('Currency'),
                  subtitle: Text('${_selectedCurrency['name']} (${_selectedCurrency['symbol']})'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCurrencyPicker(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Shop Settings
          _sectionHeader('Shop Settings', Icons.store),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', prefixIcon: Icon(Icons.store))),
                  const SizedBox(height: 12),
                  TextField(controller: _shopAddressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(controller: _gstCtrl, decoration: const InputDecoration(labelText: 'GST Number', prefixIcon: Icon(Icons.receipt))),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop settings saved (mock)'))),
                      child: const Text('Save Shop Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Receipt Settings
          _sectionHeader('Receipt Settings', Icons.receipt_long),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paperSize,
                    decoration: const InputDecoration(labelText: 'Paper Size', prefixIcon: Icon(Icons.straighten)),
                    items: const [
                      DropdownMenuItem(value: '58mm', child: Text('58mm (Thermal)')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm (Thermal)')),
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                    ],
                    onChanged: (v) => setState(() => _paperSize = v!),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Show Logo'),
                    value: _showLogo,
                    onChanged: (v) => setState(() => _showLogo = v),
                  ),
                  SwitchListTile(
                    title: const Text('Show GST Details'),
                    value: _showGST,
                    onChanged: (v) => setState(() => _showGST = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Receipt Header'),
                    controller: _receiptHeaderCtrl,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Receipt Footer'),
                    controller: _receiptFooterCtrl,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showTestPrintPreview(),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Test Print'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveReceiptSettings(),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tax Configuration
          _sectionHeader('Tax Configuration', Icons.calculate),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable GST'),
                  subtitle: const Text('Apply GST on all taxable products'),
                  value: _gstEnabled,
                  onChanged: (v) => setState(() => _gstEnabled = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Inclusive Tax'),
                  subtitle: const Text('Product prices include tax'),
                  value: _inclusiveTax,
                  onChanged: (v) => setState(() => _inclusiveTax = v),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default Tax Rate'),
                  subtitle: const Text('Tap to change GST slab'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_defaultTaxRate.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  onTap: _gstEnabled ? () => _showTaxRatePicker() : null,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveTaxSettings(),
                      child: const Text('Save Tax Settings'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Printer Settings
          _sectionHeader('Printer Settings', Icons.print),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print, color: AppTheme.success),
                  ),
                  title: const Text('Thermal Printer (USB)'),
                  subtitle: const Text('Connected • 80mm'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Connected', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_btConnectedDevice != null ? AppTheme.success : Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bluetooth,
                      color: _btConnectedDevice != null ? AppTheme.success : Colors.grey,
                    ),
                  ),
                  title: Text(_btConnectedDevice ?? 'Bluetooth Printer'),
                  subtitle: Text(_btConnectedDevice != null ? 'Connected' : 'Not connected'),
                  trailing: _btConnectedDevice != null
                      ? OutlinedButton(
                          onPressed: () => setState(() => _btConnectedDevice = null),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                          child: const Text('Disconnect'),
                        )
                      : OutlinedButton(
                          onPressed: _btScanning ? null : () => _showBluetoothScanDialog(),
                          child: _btScanning
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Scan'),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          _sectionHeader('Data Management', Icons.storage),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: _isBackingUp
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.backup, color: AppTheme.primaryColor),
                  title: const Text('Backup Data'),
                  subtitle: Text(
                    _lastBackupTime == null
                        ? 'No backup yet'
                        : 'Last backup: ${_formatDateTime(_lastBackupTime!)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isBackingUp ? null : () => _performBackup(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppTheme.accentColor),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore from a backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRestoreDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppTheme.error),
                  title: const Text('Clear All Data', style: TextStyle(color: AppTheme.error)),
                  subtitle: const Text('Delete all local data'),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.error),
                  onTap: () => _showClearDataDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          _sectionHeader('About', Icons.info),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  title: const Text('App Version'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppConstants.appVersion, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showAppInfoDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy, color: AppTheme.primaryColor),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPolicyDialog(
                    title: 'Privacy Policy',
                    icon: Icons.policy,
                    content: _privacyPolicyText,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPolicyDialog(
                    title: 'Terms & Conditions',
                    icon: Icons.description,
                    content: _termsText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Logout', style: TextStyle(color: AppTheme.error, fontSize: 16)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showBluetoothScanDialog() {
    final mockDevices = [
      {'name': 'XP-58 Thermal Printer',  'address': 'AA:BB:CC:11:22:33', 'signal': 'Strong'},
      {'name': 'BT Printer PT-210',       'address': 'DD:EE:FF:44:55:66', 'signal': 'Good'},
      {'name': 'RPP300 Mobile Printer',   'address': '11:22:33:AA:BB:CC', 'signal': 'Weak'},
    ];

    setState(() => _btScanning = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bluetooth_searching, size: 20),
              SizedBox(width: 8),
              Text('Scan for Printers'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder(
              future: Future.delayed(const Duration(seconds: 2)),
              builder: (_, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Scanning for Bluetooth printers...'),
                      ],
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mockDevices.length} device(s) found',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ...mockDevices.map((device) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.print, color: AppTheme.primaryColor),
                      title: Text(device['name']!),
                      subtitle: Text(device['address']!, style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            device['signal'] == 'Strong'
                                ? Icons.signal_wifi_4_bar
                                : device['signal'] == 'Good'
                                    ? Icons.network_wifi_3_bar
                                    : Icons.network_wifi_1_bar,
                            size: 16,
                            color: device['signal'] == 'Strong'
                                ? AppTheme.success
                                : device['signal'] == 'Good'
                                    ? AppTheme.accentColor
                                    : AppTheme.error,
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _btConnectedDevice = device['name'];
                                _btScanning = false;
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Connected to ${device['name']}'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Connect', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _btScanning = false);
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).whenComplete(() => setState(() => _btScanning = false));
  }

  void _saveTaxSettings() {
    ref.read(taxSettingsProvider.notifier).update(
      TaxSettings(
        gstEnabled:     _gstEnabled,
        inclusiveTax:   _inclusiveTax,
        defaultTaxRate: _defaultTaxRate,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax settings saved'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showTaxRatePicker() {
    const rates = [0.0, 5.0, 12.0, 18.0, 28.0];
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Default Tax Rate'),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: rates.map((rate) {
              final isSelected = rate == _defaultTaxRate;
              final label = rate == 0.0 ? 'No Tax (0%)' : '${rate.toStringAsFixed(0)}%';
              return ListTile(
                title: Text(label),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppTheme.primaryColor,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _defaultTaxRate = rate);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _saveReceiptSettings() {
    ref.read(receiptSettingsProvider.notifier).update(
      ReceiptSettings(
        paperSize: _paperSize,
        showLogo:  _showLogo,
        showGST:   _showGST,
        header:    _receiptHeaderCtrl.text.trim(),
        footer:    _receiptFooterCtrl.text.trim(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt settings saved'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showTestPrintPreview() {
    final currentUser = ref.read(authProvider);
    final header = _receiptHeaderCtrl.text.trim();
    final footer = _receiptFooterCtrl.text.trim();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.receipt_long, size: 20),
              SizedBox(width: 8),
              Text('Receipt Preview'),
            ],
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamily: 'monospace',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_showLogo)
                      Column(
                        children: [
                          const Icon(Icons.store, size: 36, color: Colors.black),
                          const SizedBox(height: 4),
                        ],
                      ),
                    Text(
                      AppConstants.shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(AppConstants.shopAddress, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 11)),
                    Text(AppConstants.shopPhone,   textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 11)),
                    if (_showGST) ...[
                      const SizedBox(height: 2),
                      Text('GSTIN: ${AppConstants.gstNumber}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 11)),
                    ],
                    const SizedBox(height: 6),
                    const Divider(color: Colors.black, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TEST RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(dateStr, style: const TextStyle(color: Colors.black)),
                      ],
                    ),
                    if (currentUser != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Cashier: ${currentUser.name}', style: const TextStyle(color: Colors.black)),
                      ),
                    Text('Paper: $_paperSize', style: const TextStyle(color: Colors.black)),
                    const Divider(color: Colors.black, thickness: 1),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sample Item x2', style: TextStyle(color: Colors.black)),
                        Text('₹200.00',        style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Divider(color: Colors.black, thickness: 1),
                    if (_showGST)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GST (18%)', style: TextStyle(color: Colors.black)),
                          Text('₹36.00',   style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('₹236.00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    const Divider(color: Colors.black, thickness: 1),
                    if (header.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(header, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black)),
                    ],
                    if (footer.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(footer, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black)),
                    ],
                    const SizedBox(height: 4),
                    const Text('* * *', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('App Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.point_of_sale, size: 56, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(AppConstants.appName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Version ${AppConstants.appVersion}',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            const Divider(),
            _infoRow('Build Date',    'March 2, 2026'),
            _infoRow('Platform',      'Flutter'),
            _infoRow('Developer',     'InHouse Websites'),
            _infoRow('Support',       'support@inhousewebsites.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showPolicyDialog({required String title, required IconData icon, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(content, style: const TextStyle(fontSize: 13, height: 1.6)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _privacyPolicyText = '''
Last updated: March 2, 2026

1. INFORMATION WE COLLECT
${AppConstants.appName} collects information you provide directly, such as shop name, GST number, and contact details entered during setup. All transaction data (orders, products, customers) is stored locally on your device.

2. HOW WE USE YOUR INFORMATION
We use the information solely to operate the POS system. No personal or business data is transmitted to external servers. All data remains on-device.

3. DATA STORAGE & SECURITY
All data is stored locally. We recommend performing regular backups using the Backup Data feature. We are not responsible for data loss due to device failure if backups have not been taken.

4. SHARING OF INFORMATION
We do not sell, trade, or transfer your data to third parties. Data is never shared without your explicit consent.

5. THIRD-PARTY SERVICES
This app does not integrate with any third-party analytics or advertising services.

6. CHILDREN'S PRIVACY
This application is intended for business use only and is not directed at children under the age of 13.

7. CHANGES TO THIS POLICY
We may update this Privacy Policy from time to time. Changes will be reflected in the app's About section with an updated date.

8. CONTACT US
For questions regarding this Privacy Policy, contact:
${AppConstants.shopName}
Email: support@inhousewebsites.com
''';

  static const String _termsText = '''
Last updated: March 2, 2026

1. ACCEPTANCE OF TERMS
By using ${AppConstants.appName}, you agree to these Terms & Conditions. If you do not agree, please discontinue use of the application.

2. LICENSE
This software is licensed for use by the registered business only. Redistribution, resale, or reverse engineering of the application is strictly prohibited.

3. USER RESPONSIBILITIES
You are responsible for:
• Maintaining the accuracy of shop, tax, and product data entered.
• Keeping your login credentials secure.
• Performing regular data backups.
• Complying with applicable tax (GST) regulations in your jurisdiction.

4. ACCURACY OF INFORMATION
While we strive for accuracy, ${AppConstants.appName} does not guarantee that billing calculations are error-free in all edge cases. You are responsible for verifying totals before finalising transactions.

5. DATA & PRIVACY
All data is stored locally on your device. Refer to our Privacy Policy for full details.

6. LIMITATION OF LIABILITY
To the maximum extent permitted by law, ${AppConstants.appName} and its developers shall not be liable for any indirect, incidental, or consequential damages arising from the use or inability to use this application, including data loss.

7. MODIFICATIONS
We reserve the right to modify these Terms at any time. Continued use of the application after changes constitutes acceptance of the new Terms.

8. GOVERNING LAW
These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in Mumbai, Maharashtra.

9. CONTACT
For queries regarding these Terms, contact:
support@inhousewebsites.com
''';

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  IconData _currencyIcon(String icon) {
    switch (icon) {
      case 'currency_pound': return Icons.currency_pound;
      case 'currency_yen':   return Icons.currency_yen;
      case 'euro':           return Icons.euro;
      case 'attach_money':   return Icons.attach_money;
      default:               return Icons.currency_rupee;
    }
  }

  void _showCurrencyPicker() {
    final currencies = [
      {'code': 'INR', 'name': 'Indian Rupee',     'symbol': '₹',   'icon': 'currency_rupee'},
      {'code': 'USD', 'name': 'US Dollar',         'symbol': '\$',   'icon': 'attach_money'},
      {'code': 'EUR', 'name': 'Euro',              'symbol': '€',   'icon': 'euro'},
      {'code': 'GBP', 'name': 'British Pound',     'symbol': '£',   'icon': 'currency_pound'},
      {'code': 'JPY', 'name': 'Japanese Yen',      'symbol': '¥',   'icon': 'currency_yen'},
      {'code': 'AED', 'name': 'UAE Dirham',        'symbol': 'د.إ', 'icon': 'attach_money'},
      {'code': 'SGD', 'name': 'Singapore Dollar',  'symbol': 'S\$', 'icon': 'attach_money'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'icon': 'attach_money'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Currency'),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currencies.length,
              itemBuilder: (_, i) {
                final c = currencies[i];
                final isSelected = c['code'] == _selectedCurrency['code'];
                return ListTile(
                  leading: Icon(
                    _currencyIcon(c['icon']!),
                    color: isSelected ? AppTheme.primaryColor : null,
                  ),
                  title: Text(c['name']!),
                  subtitle: Text('${c['code']} • ${c['symbol']}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedCurrency = c);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Currency set to ${c['name']} (${c['symbol']})')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam'].map((l) =>
              ListTile(
                title: Text(l),
                leading: Icon(l == 'English' ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: AppTheme.primaryColor),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language set to $l (mock)')));
                },
              ),
            ).toList(),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(AppUser? currentUser) {
    final nameCtrl = TextEditingController(text: currentUser?.name ?? '');
    final emailCtrl = TextEditingController(text: currentUser?.email ?? '');
    final phoneCtrl = TextEditingController(text: currentUser?.phone ?? '');
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'New Password (optional)',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 4) {
                            return 'Password must be at least 4 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (passwordCtrl.text.isNotEmpty && v != passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      nameCtrl.dispose();
                      emailCtrl.dispose();
                      phoneCtrl.dispose();
                      passwordCtrl.dispose();
                      confirmPasswordCtrl.dispose();
                    });
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    ref.read(authProvider.notifier).updateProfile(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      password: passwordCtrl.text.isNotEmpty ? passwordCtrl.text : null,
                    );
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      nameCtrl.dispose();
                      emailCtrl.dispose();
                      phoneCtrl.dispose();
                      passwordCtrl.dispose();
                      confirmPasswordCtrl.dispose();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (dtDay == today) return 'Today, $timeStr';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}, $timeStr';
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating backup…')),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isBackingUp = false;
      _lastBackupTime = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup created successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showRestoreDialog() {
    final backups = [
      {'label': 'Today, 10:30 AM',      'size': '2.4 MB', 'records': '1,240 orders'},
      {'label': 'Yesterday, 06:00 PM',  'size': '2.1 MB', 'records': '1,180 orders'},
      {'label': '01/03/2026, 09:15 AM', 'size': '1.8 MB', 'records': '1,050 orders'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restore, color: AppTheme.accentColor),
              SizedBox(width: 8),
              Text('Restore Data'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a backup to restore from. This will overwrite current data.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ...backups.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.folder_zip, color: AppTheme.accentColor),
                    title: Text(b['label']!),
                    subtitle: Text('${b['size']} • ${b['records']}'),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmRestore(b['label']!);
                      },
                      child: const Text('Restore'),
                    ),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRestore(String backupLabel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text(
          'Restore from "$backupLabel"?\n\nThis will replace all current orders, products, and customer data with the backup. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restoring data…')),
              );
              await Future.delayed(const Duration(seconds: 2));
              if (!mounted) return;
              // Reset providers to mock (initial) data
              ref.read(ordersProvider.notifier).reset();
              ref.read(productsProvider.notifier).reset();
              ref.read(customersProvider.notifier).reset();
              ref.read(categoriesProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data restored from "$backupLabel"'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text(
            'This will permanently delete all orders, products, customers, and settings. This action cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clearing all data…')),
                );
                await Future.delayed(const Duration(seconds: 1));
                if (!mounted) return;
                // Reset all data providers
                ref.read(ordersProvider.notifier).reset();
                ref.read(productsProvider.notifier).reset();
                ref.read(customersProvider.notifier).reset();
                ref.read(categoriesProvider.notifier).reset();
                ref.read(vendorsProvider.notifier).reset();
                ref.read(usersProvider.notifier).reset();
                // Reset settings providers
                ref.read(receiptSettingsProvider.notifier).update(const ReceiptSettings());
                ref.read(taxSettingsProvider.notifier).update(const TaxSettings());
                // Reset local state
                setState(() {
                  _lastBackupTime = null;
                  _paperSize = '80mm';
                  _showLogo = true;
                  _showGST = true;
                  _receiptHeaderCtrl.text = AppConstants.receiptHeader;
                  _receiptFooterCtrl.text = AppConstants.receiptFooter;
                  _gstEnabled = true;
                  _inclusiveTax = false;
                  _defaultTaxRate = 18.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              },
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
}
