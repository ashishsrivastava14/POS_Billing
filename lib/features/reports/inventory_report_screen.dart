import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/product.dart';

class InventoryReportScreen extends ConsumerStatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  ConsumerState<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends ConsumerState<InventoryReportScreen> {
  bool _isExporting = false;
  String _sortBy = 'name'; // name | stock | value | category
  bool _sortAsc = true;

  // ── PDF Export ────────────────────────────────────────────────────────────
  Future<void> _exportPdf(List<Product> products) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _buildPdf(products);
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Inventory_Report_${formatDate(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<Uint8List> _buildPdf(List<Product> products) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final lowStock = products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final outOfStock = products.where((p) => p.isOutOfStock).toList();
    final totalCost = products.fold<double>(0, (s, p) => s + p.purchasePrice * p.stockQty);
    final totalRetail = products.fold<double>(0, (s, p) => s + p.sellingPrice * p.stockQty);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Center(
            child: pw.Column(children: [
              pw.Text(AppConstants.shopName,
                  style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.SizedBox(height: 4),
              pw.Text(AppConstants.shopAddress,
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center),
              pw.Text('GST: \${AppConstants.gstNumber}',
                  style: pw.TextStyle(font: font, fontSize: 10)),
            ]),
          ),
          pw.Divider(height: 20),
          pw.Center(
              child: pw.Text('INVENTORY REPORT',
                  style: pw.TextStyle(font: fontBold, fontSize: 14))),
          pw.Center(
              child: pw.Text('Generated on \${formatDateTime(DateTime.now())}',
                  style: pw.TextStyle(font: font, fontSize: 10))),
          pw.SizedBox(height: 16),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfKpi('Total Products', '\${products.length}', font, fontBold),
                _pdfKpi('Low Stock', '${lowStock.length}', font, fontBold),
                _pdfKpi('Out of Stock', '${outOfStock.length}', font, fontBold),
                _pdfKpi('Stock Cost Value', formatCurrency(totalCost), font, fontBold),
                _pdfKpi('Retail Value', formatCurrency(totalRetail), font, fontBold),
                _pdfKpi('Gross Margin', formatCurrency(totalRetail - totalCost), font, fontBold),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Products table
          pw.Text('Product Stock Details',
              style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey100),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _pdfCell('Product', fontBold),
                  _pdfCell('Category', fontBold),
                  _pdfCell('Stock', fontBold, align: pw.TextAlign.center),
                  _pdfCell('Min.', fontBold, align: pw.TextAlign.center),
                  _pdfCell('Purchase', fontBold, align: pw.TextAlign.right),
                  _pdfCell('Selling', fontBold, align: pw.TextAlign.right),
                  _pdfCell('Stock Value', fontBold, align: pw.TextAlign.right),
                ],
              ),
              ...products.map((p) => pw.TableRow(
                    decoration: p.isOutOfStock
                        ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFEBEE))
                        : p.isLowStock
                            ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF8E1))
                            : null,
                    children: [
                      _pdfCell(p.name, font),
                      _pdfCell(p.categoryName, font),
                      _pdfCell('\${p.stockQty}', font, align: pw.TextAlign.center),
                      _pdfCell('\${p.minStockAlert}', font, align: pw.TextAlign.center),
                      _pdfCell(formatCurrency(p.purchasePrice), font,
                          align: pw.TextAlign.right),
                      _pdfCell(formatCurrency(p.sellingPrice), font,
                          align: pw.TextAlign.right),
                      _pdfCell(
                          formatCurrency(p.purchasePrice * p.stockQty), fontBold,
                          align: pw.TextAlign.right),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfKpi(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
      ],
    );
  }

  pw.Widget _pdfCell(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 9), textAlign: align),
    );
  }

  // ── Sort helpers ──────────────────────────────────────────────────────────
  List<Product> _sortedProducts(List<Product> products) {
    final sorted = [...products];
    sorted.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'stock':
          cmp = a.stockQty.compareTo(b.stockQty);
          break;
        case 'value':
          cmp = (a.purchasePrice * a.stockQty)
              .compareTo(b.purchasePrice * b.stockQty);
          break;
        case 'category':
          cmp = a.categoryName.compareTo(b.categoryName);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    final totalProducts = products.length;
    final lowStockProducts =
        products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final outOfStockProducts = products.where((p) => p.isOutOfStock).toList();
    final totalStockValue = products.fold<double>(
        0, (s, p) => s + (p.purchasePrice * p.stockQty));
    final totalRetailValue = products.fold<double>(
        0, (s, p) => s + (p.sellingPrice * p.stockQty));

    final categoryStockMap = <String, int>{};
    for (final p in products) {
      categoryStockMap[p.categoryName] =
          (categoryStockMap[p.categoryName] ?? 0) + p.stockQty;
    }

    final colors = [
      AppTheme.primaryColor, AppTheme.accentColor, AppTheme.success,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
      Colors.brown, Colors.cyan, Colors.lime
    ];

    final sortedAll = _sortedProducts(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF',
              onPressed: () => _exportPdf(products),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs
            Row(
              children: [
                _kpi('Total Products', '$totalProducts', Icons.inventory_2,
                    AppTheme.primaryColor),
                const SizedBox(width: 12),
                _kpi('Low Stock', '\${lowStockProducts.length}', Icons.warning,
                    AppTheme.warning),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpi('Out of Stock', '\${outOfStockProducts.length}',
                    Icons.error, AppTheme.error),
                const SizedBox(width: 12),
                _kpi('Stock Value', formatCurrency(totalStockValue),
                    Icons.account_balance_wallet, AppTheme.success),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.trending_up, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Potential Revenue',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(formatCurrency(totalRetailValue),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Gross Margin',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                            formatCurrency(
                                totalRetailValue - totalStockValue),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category-wise stock chart
            const Text('Category Stock Distribution',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: categoryStockMap.isEmpty
                  ? const Center(child: Text('No data'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (categoryStockMap.values
                                .reduce((a, b) => a > b ? a : b) *
                            1.25),
                        gridData: FlGridData(
                            show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, meta) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, meta) {
                                final keys =
                                    categoryStockMap.keys.toList();
                                final idx = v.toInt();
                                if (idx < 0 || idx >= keys.length) {
                                  return const SizedBox.shrink();
                                }
                                final label = keys[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    label.length > 6
                                        ? '\${label.substring(0, 6)}.'
                                        : label,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: categoryStockMap.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) => BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.value.toDouble(),
                                      color: colors[
                                          e.key % colors.length],
                                      width: 18,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(4)),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Low stock alerts
            if (lowStockProducts.isNotEmpty) ...[
              Row(children: [
                const Icon(Icons.warning, color: AppTheme.warning, size: 20),
                const SizedBox(width: 8),
                const Text('Low Stock Alerts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              ...lowStockProducts.take(10).map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                            child: Text('\${p.stockQty}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warning))),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle: Text(
                          '\${p.categoryName} • Min: \${p.minStockAlert}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                          'Need \${p.minStockAlert - p.stockQty} more',
                          style: const TextStyle(
                              color: AppTheme.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  )),
            ],

            // Out of stock
            if (outOfStockProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.error, color: AppTheme.error, size: 20),
                const SizedBox(width: 8),
                const Text('Out of Stock',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              ...outOfStockProducts.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.error.withValues(alpha: 0.03),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.remove_shopping_cart,
                            size: 18, color: AppTheme.error),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle: Text(
                          '\${p.categoryName} • \${p.brand}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Text('REORDER',
                          style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  )),
            ],
            const SizedBox(height: 24),

            // Full product stock table
            Row(
              children: [
                const Text('All Products',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Sort by',
                  icon: const Icon(Icons.sort),
                  onSelected: (v) => setState(() {
                    if (_sortBy == v) {
                      _sortAsc = !_sortAsc;
                    } else {
                      _sortBy = v;
                      _sortAsc = true;
                    }
                  }),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                    PopupMenuItem(value: 'category', child: Text('Sort by Category')),
                    PopupMenuItem(value: 'stock', child: Text('Sort by Stock')),
                    PopupMenuItem(value: 'value', child: Text('Sort by Value')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 14,
                  headingRowColor: WidgetStatePropertyAll(
                      AppTheme.primaryColor.withValues(alpha: 0.06)),
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Stock'), numeric: true),
                    DataColumn(label: Text('Min'), numeric: true),
                    DataColumn(label: Text('Purchase ₹'), numeric: true),
                    DataColumn(label: Text('Selling ₹'), numeric: true),
                    DataColumn(label: Text('Stock Value'), numeric: true),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: sortedAll.map((p) {
                    final statusColor = p.isOutOfStock
                        ? AppTheme.error
                        : p.isLowStock
                            ? AppTheme.warning
                            : AppTheme.success;
                    final statusLabel = p.isOutOfStock
                        ? 'Out'
                        : p.isLowStock
                            ? 'Low'
                            : 'OK';
                    return DataRow(
                      color: WidgetStatePropertyAll(
                        p.isOutOfStock
                            ? AppTheme.error.withValues(alpha: 0.04)
                            : p.isLowStock
                                ? AppTheme.warning.withValues(alpha: 0.04)
                                : null,
                      ),
                      cells: [
                        DataCell(SizedBox(
                            width: 160,
                            child: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis))),
                        DataCell(Text(p.categoryName,
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text('\${p.stockQty}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor))),
                        DataCell(Text('\${p.minStockAlert}',
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(formatCurrency(p.purchasePrice),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(formatCurrency(p.sellingPrice),
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Text(
                            formatCurrency(p.purchasePrice * p.stockQty),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w700)),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
