import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/extras.dart';

final List<Customer> mockCustomers = [
  Customer(id: 'cust1', name: 'Rahul Gupta', phone: '+91 99001 10001', email: 'rahul@email.com', totalPurchases: 12500, orderCount: 15, createdAt: DateTime(2024, 6, 1)),
  Customer(id: 'cust2', name: 'Sneha Iyer', phone: '+91 99001 10002', email: 'sneha@email.com', totalPurchases: 8700, orderCount: 10, createdAt: DateTime(2024, 7, 5)),
  Customer(id: 'cust3', name: 'Mohammad Farhan', phone: '+91 99001 10003', totalPurchases: 22000, orderCount: 22, createdAt: DateTime(2024, 5, 12)),
  Customer(id: 'cust4', name: 'Lakshmi Devi', phone: '+91 99001 10004', totalPurchases: 5200, orderCount: 6, createdAt: DateTime(2024, 8, 20)),
  Customer(id: 'cust5', name: 'Arjun Malhotra', phone: '+91 99001 10005', email: 'arjun.m@email.com', totalPurchases: 15800, orderCount: 18, createdAt: DateTime(2024, 4, 1)),
  Customer(id: 'cust6', name: 'Pooja Desai', phone: '+91 99001 10006', totalPurchases: 9400, orderCount: 12, createdAt: DateTime(2024, 6, 15)),
  Customer(id: 'cust7', name: 'Sanjay Kulkarni', phone: '+91 99001 10007', email: 'sanjay.k@email.com', totalPurchases: 31200, orderCount: 28, createdAt: DateTime(2024, 3, 10)),
  Customer(id: 'cust8', name: 'Meena Krishnan', phone: '+91 99001 10008', totalPurchases: 7100, orderCount: 8, createdAt: DateTime(2024, 9, 1)),
  Customer(id: 'cust9', name: 'Deepa Srinivasan', phone: '+91 99001 10009', email: 'deepa.s@email.com', totalPurchases: 18200, orderCount: 20, createdAt: DateTime(2024, 2, 18)),
  Customer(id: 'cust10', name: 'Naveen Joshi', phone: '+91 99001 10010', totalPurchases: 4500, orderCount: 5, createdAt: DateTime(2024, 10, 5)),
];

final List<Order> mockOrders = List.generate(50, (index) {
  final id = 'ord${index + 1}';
  final date = DateTime(2026, 2, 28).subtract(Duration(hours: index * 12));
  final items = _generateOrderItems(index);
  final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  final discount = index % 5 == 0 ? subtotal * 0.05 : 0.0;
  final taxAmount = items.fold<double>(0, (sum, item) => sum + item.lineTax);
  final total = subtotal - discount + taxAmount;
  final paymentModes = [PaymentMode.cash, PaymentMode.card, PaymentMode.upi];
  final statusList = [OrderStatus.completed, OrderStatus.completed, OrderStatus.completed, OrderStatus.pending, OrderStatus.cancelled];

  return Order(
    id: id,
    invoiceNumber: 'INV-${(1000 + index).toString()}',
    vendorId: 'v1',
    cashierId: index % 2 == 0 ? 'u4' : 'u5',
    cashierName: index % 2 == 0 ? 'Deepak Verma' : 'Kavitha Nair',
    customerId: index % 3 == 0 ? 'cust${(index % 10) + 1}' : null,
    customerName: index % 3 == 0 ? mockCustomers[index % 10].name : null,
    items: items,
    subtotal: subtotal,
    discountAmount: discount,
    taxAmount: taxAmount,
    totalAmount: total,
    cashTendered: paymentModes[index % 3] == PaymentMode.cash ? (total + 50 - (total % 50)).ceilToDouble() : null,
    changeAmount: paymentModes[index % 3] == PaymentMode.cash ? ((total + 50 - (total % 50)).ceilToDouble()) - total : null,
    paymentMode: paymentModes[index % 3],
    status: statusList[index % 5],
    createdAt: date,
  );
});

List<CartItem> _generateOrderItems(int orderIndex) {
  final productSets = [
    [
      const CartItem(productId: 'p1', productName: 'Tata Salt (1kg)', sku: 'GRC001', unitPrice: 22, taxPercent: 5, quantity: 2),
      const CartItem(productId: 'p26', productName: 'Amul Milk (1L)', sku: 'DRY001', unitPrice: 60, taxPercent: 0, quantity: 3),
      const CartItem(productId: 'p181', productName: 'White Bread (400g)', sku: 'BKR001', unitPrice: 40, taxPercent: 5, quantity: 1),
    ],
    [
      const CartItem(productId: 'p66', productName: 'Lays Classic Salted (52g)', sku: 'SNK001', unitPrice: 20, taxPercent: 12, quantity: 4),
      const CartItem(productId: 'p46', productName: 'Coca Cola (2L)', sku: 'BEV001', unitPrice: 88, taxPercent: 18, quantity: 2),
      const CartItem(productId: 'p108', productName: 'Colgate Toothpaste (200g)', sku: 'PRC001', unitPrice: 105, taxPercent: 18, quantity: 1),
      const CartItem(productId: 'p31', productName: 'Eggs (Pack of 12)', sku: 'DRY006', unitPrice: 78, taxPercent: 0, quantity: 1),
    ],
    [
      const CartItem(productId: 'p3', productName: 'India Gate Basmati Rice (5kg)', sku: 'GRC003', unitPrice: 450, taxPercent: 5, quantity: 1),
      const CartItem(productId: 'p4', productName: 'Aashirvaad Atta (5kg)', sku: 'GRC004', unitPrice: 270, taxPercent: 5, quantity: 1),
      const CartItem(productId: 'p5', productName: 'Toor Dal (1kg)', sku: 'GRC005', unitPrice: 135, taxPercent: 5, quantity: 2),
      const CartItem(productId: 'p2', productName: 'Fortune Sunflower Oil (1L)', sku: 'GRC002', unitPrice: 145, taxPercent: 5, quantity: 1),
      const CartItem(productId: 'p8', productName: 'Sugar (1kg)', sku: 'GRC008', unitPrice: 45, taxPercent: 5, quantity: 2),
    ],
    [
      const CartItem(productId: 'p128', productName: 'Banana (1 dozen)', sku: 'FNV001', unitPrice: 48, taxPercent: 0, quantity: 2),
      const CartItem(productId: 'p129', productName: 'Apple (1kg)', sku: 'FNV002', unitPrice: 160, taxPercent: 0, quantity: 1),
      const CartItem(productId: 'p130', productName: 'Tomato (1kg)', sku: 'FNV003', unitPrice: 35, taxPercent: 0, quantity: 2),
      const CartItem(productId: 'p131', productName: 'Onion (1kg)', sku: 'FNV004', unitPrice: 30, taxPercent: 0, quantity: 3),
    ],
    [
      const CartItem(productId: 'p88', productName: 'Surf Excel (1kg)', sku: 'HHD001', unitPrice: 225, taxPercent: 18, quantity: 1),
      const CartItem(productId: 'p89', productName: 'Vim Dishwash Bar (500g)', sku: 'HHD002', unitPrice: 36, taxPercent: 18, quantity: 2),
      const CartItem(productId: 'p90', productName: 'Harpic Toilet Cleaner (1L)', sku: 'HHD003', unitPrice: 140, taxPercent: 18, quantity: 1),
    ],
  ];

  return productSets[orderIndex % productSets.length];
}

final List<AuditLog> mockAuditLogs = [
  AuditLog(id: 'log1', userId: 'u1', userName: 'Arjun Mehta', action: 'Created', module: 'Vendors', details: 'Added new vendor DailyNeeds Mart', timestamp: DateTime(2026, 2, 28, 14, 30)),
  AuditLog(id: 'log2', userId: 'u2', userName: 'Rajesh Kumar', action: 'Updated', module: 'Products', details: 'Updated price of Tata Salt', timestamp: DateTime(2026, 2, 28, 12, 15)),
  AuditLog(id: 'log3', userId: 'u4', userName: 'Deepak Verma', action: 'Created', module: 'Orders', details: 'New order INV-1049 created', timestamp: DateTime(2026, 2, 28, 10, 45)),
  AuditLog(id: 'log4', userId: 'u1', userName: 'Arjun Mehta', action: 'Deactivated', module: 'Users', details: 'Deactivated user account', timestamp: DateTime(2026, 2, 27, 16, 20)),
  AuditLog(id: 'log5', userId: 'u3', userName: 'Priya Sharma', action: 'Updated', module: 'Inventory', details: 'Stock adjustment for Amul Milk', timestamp: DateTime(2026, 2, 27, 14, 0)),
  AuditLog(id: 'log6', userId: 'u5', userName: 'Kavitha Nair', action: 'Created', module: 'Orders', details: 'New order INV-1048 created', timestamp: DateTime(2026, 2, 27, 11, 30)),
  AuditLog(id: 'log7', userId: 'u2', userName: 'Rajesh Kumar', action: 'Created', module: 'Products', details: 'Added 5 new products', timestamp: DateTime(2026, 2, 26, 15, 45)),
  AuditLog(id: 'log8', userId: 'u1', userName: 'Arjun Mehta', action: 'Updated', module: 'Settings', details: 'Updated system configuration', timestamp: DateTime(2026, 2, 26, 9, 0)),
  AuditLog(id: 'log9', userId: 'u6', userName: 'Ravi Shankar', action: 'Created', module: 'Orders', details: 'New order INV-1047 created', timestamp: DateTime(2026, 2, 25, 17, 30)),
  AuditLog(id: 'log10', userId: 'u2', userName: 'Rajesh Kumar', action: 'Deleted', module: 'Products', details: 'Removed expired product listing', timestamp: DateTime(2026, 2, 25, 13, 15)),
];

final List<Discount> mockDiscounts = [
  Discount(id: 'd1', name: 'Weekend Special', type: 'percentage', value: 10, categoryId: 'c4', startDate: DateTime(2026, 2, 1), endDate: DateTime(2026, 3, 31), isActive: true),
  Discount(id: 'd2', name: 'Dairy Delight', type: 'flat', value: 15, categoryId: 'c2', startDate: DateTime(2026, 2, 15), endDate: DateTime(2026, 3, 15), isActive: true),
  Discount(id: 'd3', name: 'Beverage Bonanza', type: 'percentage', value: 5, categoryId: 'c3', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 2, 28), isActive: false),
  Discount(id: 'd4', name: 'Fresh Produce Sale', type: 'percentage', value: 8, categoryId: 'c7', startDate: DateTime(2026, 3, 1), endDate: DateTime(2026, 3, 31), isActive: true),
  Discount(id: 'd5', name: 'Baby Week Offer', type: 'flat', value: 25, categoryId: 'c9', startDate: DateTime(2026, 2, 20), endDate: DateTime(2026, 3, 5), isActive: true),
];
