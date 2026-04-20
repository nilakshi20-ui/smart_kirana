// lib/shared/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppConstants.routeInventory)) return 1;
    if (location.startsWith(AppConstants.routeBilling)) return 2;
    if (location.startsWith(AppConstants.routeCustomers)) return 3;
    if (location.startsWith(AppConstants.routeReports)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                    isActive: idx == 0,
                    onTap: () => context.go(AppConstants.routeDashboard)),
                _NavItem(icon: Icons.inventory_2_rounded, label: 'Inventory',
                    isActive: idx == 1,
                    onTap: () => context.go(AppConstants.routeInventory)),
                _BillingFab(onTap: () => context.push(AppConstants.routeCreateBill)),
                _NavItem(icon: Icons.people_rounded, label: 'Customers',
                    isActive: idx == 3,
                    onTap: () => context.go(AppConstants.routeCustomers)),
                _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports',
                    isActive: idx == 4,
                    onTap: () => context.go(AppConstants.routeReports)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? AppTheme.primary : AppTheme.textSecondaryLight),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppTheme.primary : AppTheme.textSecondaryLight,
                )),
          ],
        ),
      ),
    );
  }
}

class _BillingFab extends StatelessWidget {
  final VoidCallback onTap;
  const _BillingFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.receipt_long_rounded,
            color: Colors.white, size: 26),
      ),
    );
  }
}
