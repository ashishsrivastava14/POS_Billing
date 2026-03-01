class Vendor {
  final String id;
  final String shopName;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String gstNumber;
  final String plan;
  final bool isActive;
  final DateTime joinedDate;
  final int staffCount;
  final double totalRevenue;

  const Vendor({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.gstNumber,
    required this.plan,
    this.isActive = true,
    required this.joinedDate,
    this.staffCount = 0,
    this.totalRevenue = 0,
  });

  Vendor copyWith({
    String? id,
    String? shopName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? gstNumber,
    String? plan,
    bool? isActive,
    DateTime? joinedDate,
    int? staffCount,
    double? totalRevenue,
  }) {
    return Vendor(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      gstNumber: gstNumber ?? this.gstNumber,
      plan: plan ?? this.plan,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      staffCount: staffCount ?? this.staffCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }
}
