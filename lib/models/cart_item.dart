class CartItem {
  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double taxPercent;
  final int quantity;
  final double discount;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.taxPercent,
    required this.quantity,
    this.discount = 0,
  });

  double get lineTotal => (unitPrice * quantity) - discount;
  double get lineTax => lineTotal * (taxPercent / 100);
  double get lineTotalWithTax => lineTotal + lineTax;

  CartItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    double? unitPrice,
    double? taxPercent,
    int? quantity,
    double? discount,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}
