import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/vendor.dart';
import '../models/extras.dart';
import '../mock_data/users_mock.dart';
import '../mock_data/products_mock.dart';
import '../mock_data/vendors_mock.dart';
import '../mock_data/orders_mock.dart';
import 'constants/app_constants.dart';

// ── AUTH PROVIDER ──
class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  bool login(String email, String password) {
    try {
      final user = mockUsers.firstWhere(
        (u) => u.email == email && u.password == password && u.isActive,
      );
      state = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    state = null;
  }

  void updateProfile({String? name, String? email, String? phone, String? password}) {
    if (state == null) return;
    state = state!.copyWith(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) => AuthNotifier());

// ── THEME PROVIDER ──
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// ── VENDORS PROVIDER ──
class VendorsNotifier extends StateNotifier<List<Vendor>> {
  VendorsNotifier() : super(mockVendors);

  void add(Vendor vendor) {
    state = [...state, vendor];
  }

  void update(Vendor vendor) {
    state = state.map((v) => v.id == vendor.id ? vendor : v).toList();
  }

  void toggleActive(String id) {
    state = state.map((v) => v.id == id ? v.copyWith(isActive: !v.isActive) : v).toList();
  }
}

final vendorsProvider = StateNotifierProvider<VendorsNotifier, List<Vendor>>((ref) => VendorsNotifier());

// ── USERS PROVIDER ──
class UsersNotifier extends StateNotifier<List<AppUser>> {
  UsersNotifier() : super(mockUsers);

  void add(AppUser user) {
    state = [...state, user];
  }

  void update(AppUser user) {
    state = state.map((u) => u.id == user.id ? user : u).toList();
  }

  void toggleActive(String id) {
    state = state.map((u) => u.id == id ? u.copyWith(isActive: !u.isActive) : u).toList();
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, List<AppUser>>((ref) => UsersNotifier());

// ── CATEGORIES PROVIDER ──
class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super(mockCategories);

  void add(Category cat) {
    state = [...state, cat];
  }

  void update(Category cat) {
    state = state.map((c) => c.id == cat.id ? cat : c).toList();
  }

  void delete(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) => CategoriesNotifier());

// ── PRODUCTS PROVIDER ──
class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super(mockProducts);

  void add(Product product) {
    state = [...state, product];
  }

  void update(Product product) {
    state = state.map((p) => p.id == product.id ? product : p).toList();
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void adjustStock(String id, int adjustment) {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(stockQty: (p.stockQty + adjustment).clamp(0, 99999));
      }
      return p;
    }).toList();
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>((ref) => ProductsNotifier());

// ── CUSTOMERS PROVIDER ──
class CustomersNotifier extends StateNotifier<List<Customer>> {
  CustomersNotifier() : super(mockCustomers);

  void add(Customer customer) {
    state = [...state, customer];
  }

  void update(Customer customer) {
    state = state.map((c) => c.id == customer.id ? customer : c).toList();
  }

  void delete(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, List<Customer>>((ref) => CustomersNotifier());

// ── ORDERS PROVIDER ──
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(mockOrders);

  void add(Order order) {
    state = [order, ...state];
  }

  void updateStatus(String id, OrderStatus status) {
    state = state.map((o) => o.id == id ? o.copyWith(status: status) : o).toList();
  }

  void remove(String id) {
    state = state.where((o) => o.id != id).toList();
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) => OrdersNotifier());

// ── CART PROVIDER ──
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product) {
    final existingIndex = state.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      if (existing.quantity < product.stockQty) {
        state = [
          ...state.sublist(0, existingIndex),
          existing.copyWith(quantity: existing.quantity + 1),
          ...state.sublist(existingIndex + 1),
        ];
      }
    } else {
      state = [
        ...state,
        CartItem(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          unitPrice: product.sellingPrice,
          taxPercent: product.taxPercent,
          quantity: 1,
        ),
      ];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    state = state.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: qty);
      }
      return item;
    }).toList();
  }

  void applyDiscount(String productId, double discount) {
    state = state.map((item) {
      if (item.productId == productId) {
        return item.copyWith(discount: discount);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  void restoreCart(List<CartItem> items) {
    state = [...items];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.lineTotal);
  double get totalTax => state.fold(0, (sum, item) => sum + item.lineTax);
  double get grandTotal => subtotal + totalTax;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

// ── HELD ORDERS PROVIDER ──
final heldOrdersProvider = StateProvider<List<List<CartItem>>>((ref) => []);

// ── DISCOUNT PROVIDER ──
class DiscountsNotifier extends StateNotifier<List<Discount>> {
  DiscountsNotifier() : super(mockDiscounts);

  void add(Discount d) { state = [...state, d]; }
  void update(Discount d) { state = state.map((x) => x.id == d.id ? d : x).toList(); }
  void toggleActive(String id) {
    state = state.map((x) => x.id == id ? x.copyWith(isActive: !x.isActive) : x).toList();
  }
  void delete(String id) { state = state.where((x) => x.id != id).toList(); }
}

final discountsProvider = StateNotifierProvider<DiscountsNotifier, List<Discount>>((ref) => DiscountsNotifier());

// ── AUDIT LOGS PROVIDER ──
final auditLogsProvider = Provider<List<AuditLog>>((ref) => mockAuditLogs);

// ── SHIFT PROVIDER ──
class ShiftNotifier extends StateNotifier<Shift?> {
  ShiftNotifier() : super(null);

  void openShift(String cashierId, String cashierName, double openingCash) {
    state = Shift(
      id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
      cashierId: cashierId,
      cashierName: cashierName,
      openingCash: openingCash,
      openedAt: DateTime.now(),
    );
  }

  void closeShift(double closingCash) {
    if (state != null) {
      state = state!.copyWith(
        closingCash: closingCash,
        closedAt: DateTime.now(),
        isOpen: false,
      );
    }
  }

  void recordSale(double amount) {
    if (state != null) {
      state = state!.copyWith(
        totalOrders: state!.totalOrders + 1,
        totalSales: state!.totalSales + amount,
      );
    }
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, Shift?>((ref) => ShiftNotifier());

// ── SHIFT HISTORY PROVIDER ──
final shiftHistoryProvider = StateProvider<List<Shift>>((ref) => []);

// ── RECEIPT SETTINGS PROVIDER ──
class ReceiptSettings {
  final String paperSize;
  final bool showLogo;
  final bool showGST;
  final String header;
  final String footer;

  const ReceiptSettings({
    this.paperSize = '80mm',
    this.showLogo = true,
    this.showGST = true,
    this.header = AppConstants.receiptHeader,
    this.footer = AppConstants.receiptFooter,
  });

  ReceiptSettings copyWith({
    String? paperSize,
    bool? showLogo,
    bool? showGST,
    String? header,
    String? footer,
  }) {
    return ReceiptSettings(
      paperSize: paperSize ?? this.paperSize,
      showLogo: showLogo ?? this.showLogo,
      showGST: showGST ?? this.showGST,
      header: header ?? this.header,
      footer: footer ?? this.footer,
    );
  }
}

class ReceiptSettingsNotifier extends StateNotifier<ReceiptSettings> {
  ReceiptSettingsNotifier() : super(const ReceiptSettings());

  void update(ReceiptSettings settings) => state = settings;
}

final receiptSettingsProvider =
    StateNotifierProvider<ReceiptSettingsNotifier, ReceiptSettings>(
        (ref) => ReceiptSettingsNotifier());

// ── TAX SETTINGS PROVIDER ──
class TaxSettings {
  final bool gstEnabled;
  final bool inclusiveTax;
  final double defaultTaxRate;

  const TaxSettings({
    this.gstEnabled = true,
    this.inclusiveTax = false,
    this.defaultTaxRate = 18.0,
  });

  TaxSettings copyWith({
    bool? gstEnabled,
    bool? inclusiveTax,
    double? defaultTaxRate,
  }) {
    return TaxSettings(
      gstEnabled: gstEnabled ?? this.gstEnabled,
      inclusiveTax: inclusiveTax ?? this.inclusiveTax,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
    );
  }
}

class TaxSettingsNotifier extends StateNotifier<TaxSettings> {
  TaxSettingsNotifier() : super(const TaxSettings());

  void update(TaxSettings settings) => state = settings;
}

final taxSettingsProvider =
    StateNotifierProvider<TaxSettingsNotifier, TaxSettings>(
        (ref) => TaxSettingsNotifier());

// ── CASH MOVEMENTS PROVIDER (Cash In / Cash Out during shift) ──
final cashMovementsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// ── CART DISCOUNT PROVIDER ──
final cartDiscountProvider = StateProvider<double?>((ref) => null);

// ── SELECTED CUSTOMER PROVIDER ──
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

// ── SEARCH QUERY PROVIDERS ──
final productSearchProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
