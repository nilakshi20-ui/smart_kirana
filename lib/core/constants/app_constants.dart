// lib/core/constants/app_constants.dart
class AppConstants {
  // Supabase - Replace with your actual values after creating project
  static const String supabaseUrl = 'https://pqjxjzqmsedhetejofxu.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxanhqenFtc2VkaGV0ZWpvZnh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMTE3ODQsImV4cCI6MjA5MDY4Nzc4NH0.6V1JE2ONk61cOpAopgsT4FRHf9he-4j3-yrLu1oKY6Y';

  // App Info
  static const String appName = 'Smart Kirana';
  static const String appVersion = '1.0.0';

  // Database
  static const String localDbName = 'kirana_local.db';
  static const int localDbVersion = 1;

  // Low stock threshold default
  static const int defaultLowStockThreshold = 10;

  // Pagination
  static const int pageSize = 20;

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Tax
  static const double defaultGstRate = 0.18; // 18%

  // Product Categories
  static const List<String> productCategories = [
    'Grains & Pulses',
    'Spices & Masala',
    'Oil & Ghee',
    'Dairy Products',
    'Beverages',
    'Snacks & Biscuits',
    'Personal Care',
    'Cleaning Products',
    'Fruits & Vegetables',
    'Frozen Foods',
    'Stationery',
    'Other',
  ];

  // Payment Modes
  static const String paymentCash = 'cash';
  static const String paymentUpi = 'upi';
  static const String paymentCredit = 'credit';

  // Sync Status
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String syncConflict = 'conflict';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeDashboard = '/dashboard';
  static const String routeInventory = '/inventory';
  static const String routeAddProduct = '/inventory/add';
  static const String routeEditProduct = '/inventory/edit';
  static const String routeBilling = '/billing';
  static const String routeCreateBill = '/billing/create';
  static const String routeCustomers = '/customers';
  static const String routeAddCustomer = '/customers/add';
  static const String routeEditCustomer = '/customers/edit';
  static const String routeReports = '/reports';
  static const String routeSettings = '/settings';
}
