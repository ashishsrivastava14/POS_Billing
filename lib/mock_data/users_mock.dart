import '../models/user.dart';

final List<AppUser> mockUsers = [
  // Super Admin
  AppUser(
    id: 'u1',
    name: 'Arjun Mehta',
    email: 'admin@posbilling.com',
    phone: '+91 99999 00001',
    password: 'admin123',
    role: UserRole.superAdmin,
    isActive: true,
    createdAt: DateTime(2024, 1, 1),
  ),

  // Admins (Shop owners)
  AppUser(
    id: 'u2',
    name: 'Rajesh Kumar',
    email: 'rajesh@freshmart.com',
    phone: '+91 98765 43210',
    password: 'admin123',
    role: UserRole.admin,
    vendorId: 'v1',
    vendorName: 'FreshMart Supermarket',
    isActive: true,
    createdAt: DateTime(2024, 1, 15),
  ),
  AppUser(
    id: 'u3',
    name: 'Priya Sharma',
    email: 'priya@greenbasket.com',
    phone: '+91 87654 32109',
    password: 'admin123',
    role: UserRole.admin,
    vendorId: 'v2',
    vendorName: 'GreenBasket Groceries',
    isActive: true,
    createdAt: DateTime(2024, 3, 20),
  ),

  // Cashiers
  AppUser(
    id: 'u4',
    name: 'Deepak Verma',
    email: 'deepak@freshmart.com',
    phone: '+91 77777 11111',
    password: 'cashier123',
    role: UserRole.cashier,
    vendorId: 'v1',
    vendorName: 'FreshMart Supermarket',
    isActive: true,
    createdAt: DateTime(2024, 2, 1),
  ),
  AppUser(
    id: 'u5',
    name: 'Kavitha Nair',
    email: 'kavitha@freshmart.com',
    phone: '+91 77777 22222',
    password: 'cashier123',
    role: UserRole.cashier,
    vendorId: 'v1',
    vendorName: 'FreshMart Supermarket',
    isActive: true,
    createdAt: DateTime(2024, 2, 15),
  ),
  AppUser(
    id: 'u6',
    name: 'Ravi Shankar',
    email: 'ravi@greenbasket.com',
    phone: '+91 77777 33333',
    password: 'cashier123',
    role: UserRole.cashier,
    vendorId: 'v2',
    vendorName: 'GreenBasket Groceries',
    isActive: true,
    createdAt: DateTime(2024, 4, 1),
  ),
];
