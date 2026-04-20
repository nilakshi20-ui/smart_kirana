// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/add_product_screen.dart';
import '../../features/billing/screens/billing_screen.dart';
import '../../features/billing/screens/create_bill_screen.dart';
import '../../features/billing/screens/bill_detail_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/customers/screens/add_customer_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../constants/app_constants.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeSignup ||
          state.matchedLocation == AppConstants.routeSplash;

      if (!isLoggedIn && !isAuthRoute) {
        return AppConstants.routeLogin;
      }
      if (isLoggedIn && isAuthRoute &&
          state.matchedLocation != AppConstants.routeSplash) {
        return AppConstants.routeDashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSignup,
        builder: (_, __) => const SignupScreen(),
      ),
      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeDashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppConstants.routeInventory,
            builder: (_, __) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppConstants.routeBilling,
            builder: (_, __) => const BillingScreen(),
          ),
          GoRoute(
            path: AppConstants.routeCustomers,
            builder: (_, __) => const CustomersScreen(),
          ),
          GoRoute(
            path: AppConstants.routeReports,
            builder: (_, __) => const ReportsScreen(),
          ),
        ],
      ),
      // Full-screen routes (no bottom nav)
      GoRoute(
        path: AppConstants.routeAddProduct,
        builder: (_, __) => const AddProductScreen(),
      ),
      GoRoute(
        path: '${AppConstants.routeEditProduct}/:id',
        builder: (_, state) =>
            AddProductScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: AppConstants.routeCreateBill,
        builder: (_, __) => const CreateBillScreen(),
      ),
      GoRoute(
        path: '/billing/:id',
        builder: (_, state) =>
            BillDetailScreen(billId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppConstants.routeAddCustomer,
        builder: (_, __) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '${AppConstants.routeEditCustomer}/:id',
        builder: (_, state) =>
            AddCustomerScreen(customerId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (_, state) =>
            CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
