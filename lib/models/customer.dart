class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final double totalPurchases;
  final int orderCount;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.totalPurchases = 0,
    this.orderCount = 0,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    double? totalPurchases,
    int? orderCount,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
