import 'cart_item.dart';

enum OrderStatus { completed, pending, cancelled, held }

enum PaymentMode { cash, card, upi }

class Order {
  final String id;
  final String invoiceNumber;
  final String vendorId;
  final String cashierId;
  final String cashierName;
  final String? customerId;
  final String? customerName;
  final List<CartItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double? cashTendered;
  final double? changeAmount;
  final PaymentMode paymentMode;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.invoiceNumber,
    required this.vendorId,
    required this.cashierId,
    required this.cashierName,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.cashTendered,
    this.changeAmount,
    required this.paymentMode,
    required this.status,
    required this.createdAt,
  });

  Order copyWith({
    String? id,
    String? invoiceNumber,
    String? vendorId,
    String? cashierId,
    String? cashierName,
    String? customerId,
    String? customerName,
    List<CartItem>? items,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    double? cashTendered,
    double? changeAmount,
    PaymentMode? paymentMode,
    OrderStatus? status,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      vendorId: vendorId ?? this.vendorId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      cashTendered: cashTendered ?? this.cashTendered,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
