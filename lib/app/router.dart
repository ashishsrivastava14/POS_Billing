import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/super_admin/super_admin_dashboard.dart';
import '../features/super_admin/vendor_management_screen.dart';
import '../features/super_admin/user_management_screen.dart';
import '../features/super_admin/system_reports_screen.dart';
import '../features/super_admin/audit_logs_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/product_management_screen.dart';
import '../features/admin/category_management_screen.dart';
import '../features/admin/inventory_management_screen.dart';
import '../features/admin/staff_management_screen.dart';
import '../features/admin/customer_management_screen.dart';
import '../features/admin/discount_offers_screen.dart';
import '../features/cashier/pos_billing_screen.dart';
import '../features/cashier/invoice_screen.dart';
import '../features/cashier/hold_orders_screen.dart';
import '../features/cashier/shift_management_screen.dart';
import '../features/reports/sales_report_screen.dart';
import '../features/reports/inventory_report_screen.dart';
import '../features/reports/tax_report_screen.dart';
import '../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),

      // Super Admin
      GoRoute(path: '/super-admin', builder: (_, _) => const SuperAdminDashboard()),
      GoRoute(path: '/super-admin/vendors', builder: (_, _) => const VendorManagementScreen()),
      GoRoute(path: '/super-admin/users', builder: (_, _) => const UserManagementScreen()),
      GoRoute(path: '/super-admin/reports', builder: (_, _) => const SystemReportsScreen()),
      GoRoute(path: '/super-admin/audit-logs', builder: (_, _) => const AuditLogsScreen()),

      // Admin
      GoRoute(path: '/admin', builder: (_, _) => const AdminDashboard()),
      GoRoute(path: '/admin/products', builder: (_, _) => const ProductManagementScreen()),
      GoRoute(path: '/admin/categories', builder: (_, _) => const CategoryManagementScreen()),
      GoRoute(path: '/admin/inventory', builder: (_, _) => const InventoryManagementScreen()),
      GoRoute(path: '/admin/staff', builder: (_, _) => const StaffManagementScreen()),
      GoRoute(path: '/admin/customers', builder: (_, _) => const CustomerManagementScreen()),
      GoRoute(path: '/admin/discounts', builder: (_, _) => const DiscountOffersScreen()),

      // Cashier
      GoRoute(path: '/cashier', builder: (_, _) => const PosBillingScreen()),
      GoRoute(path: '/cashier/billing', builder: (_, _) => const PosBillingScreen()),
      GoRoute(path: '/cashier/invoice/:orderId', builder: (_, state) => InvoiceScreen(orderId: state.pathParameters['orderId']!)),
      GoRoute(path: '/cashier/held-orders', builder: (_, _) => const HoldOrdersScreen()),
      GoRoute(path: '/cashier/shift', builder: (_, _) => const ShiftManagementScreen()),

      // Reports
      GoRoute(path: '/reports/sales', builder: (_, _) => const SalesReportScreen()),
      GoRoute(path: '/reports/inventory', builder: (_, _) => const InventoryReportScreen()),
      GoRoute(path: '/reports/tax', builder: (_, _) => const TaxReportScreen()),

      // Settings
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});

String getDashboardRoute(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return '/super-admin';
    case UserRole.admin:
      return '/admin';
    case UserRole.cashier:
      return '/cashier';
  }
}
