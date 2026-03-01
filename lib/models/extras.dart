class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String module;
  final String details;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.details,
    required this.timestamp,
  });
}

class Discount {
  final String id;
  final String name;
  final String type; // 'percentage' or 'flat'
  final double value;
  final String? productId;
  final String? categoryId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const Discount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.productId,
    this.categoryId,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  Discount copyWith({
    String? id,
    String? name,
    String? type,
    double? value,
    String? productId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Discount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Shift {
  final String id;
  final String cashierId;
  final String cashierName;
  final double openingCash;
  final double? closingCash;
  final int totalOrders;
  final double totalSales;
  final DateTime openedAt;
  final DateTime? closedAt;
  final bool isOpen;

  const Shift({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.openingCash,
    this.closingCash,
    this.totalOrders = 0,
    this.totalSales = 0,
    required this.openedAt,
    this.closedAt,
    this.isOpen = true,
  });

  Shift copyWith({
    String? id,
    String? cashierId,
    String? cashierName,
    double? openingCash,
    double? closingCash,
    int? totalOrders,
    double? totalSales,
    DateTime? openedAt,
    DateTime? closedAt,
    bool? isOpen,
  }) {
    return Shift(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSales: totalSales ?? this.totalSales,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
