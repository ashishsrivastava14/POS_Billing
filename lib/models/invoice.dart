import 'cart_item.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String gstNumber;
  final String? customerName;
  final String? customerPhone;
  final String cashierName;
  final List<CartItem> items;
  final double subtotal;
  final double discountAmount;
  final double cgst;
  final double sgst;
  final double totalTax;
  final double totalAmount;
  final String paymentMode;
  final double? cashTendered;
  final double? changeAmount;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.gstNumber,
    this.customerName,
    this.customerPhone,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
    required this.totalAmount,
    required this.paymentMode,
    this.cashTendered,
    this.changeAmount,
    required this.createdAt,
  });
}
