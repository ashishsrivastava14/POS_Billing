import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/constants/app_constants.dart';

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
                    value: _paperSize,
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
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bluetooth, color: Colors.grey),
                  ),
                  title: const Text('Bluetooth Printer'),
                  subtitle: const Text('Not connected'),
                  trailing: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning for Bluetooth printers (mock)...'))),
                    child: const Text('Scan'),
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
                  leading: const Icon(Icons.backup, color: AppTheme.primaryColor),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Last backup: Today, 10:30 AM'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creating backup (mock)...'))),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppTheme.accentColor),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore from backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore data (mock)'))),
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
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  title: Text('App Version'),
                  trailing: Text('1.0.0', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy, color: AppTheme.primaryColor),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
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

  void _showEditProfileDialog(currentUser) {
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

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text('This will permanently delete all local data including orders, products, and settings. This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared (mock)')));
              },
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
}
