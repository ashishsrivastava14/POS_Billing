class Product {
  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String categoryId;
  final String categoryName;
  final String brand;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double taxPercent;
  final int stockQty;
  final int minStockAlert;
  final String? imageUrl;
  final bool isActive;
  final String vendorId;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.categoryId,
    required this.categoryName,
    required this.brand,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.taxPercent,
    required this.stockQty,
    required this.minStockAlert,
    this.imageUrl,
    this.isActive = true,
    required this.vendorId,
  });

  bool get isLowStock => stockQty <= minStockAlert && stockQty > 0;
  bool get isOutOfStock => stockQty <= 0;
  bool get isDeadStock => stockQty > 50 && sellingPrice == 0;

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? categoryId,
    String? categoryName,
    String? brand,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    double? taxPercent,
    int? stockQty,
    int? minStockAlert,
    String? imageUrl,
    bool? isActive,
    String? vendorId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      stockQty: stockQty ?? this.stockQty,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}
