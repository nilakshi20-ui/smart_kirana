// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

final dashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = SupabaseService.userId;
  if (userId == null) return {};
  
  final stats = await LocalDatabase.getDashboardStats(userId, DateTime.now());
  return stats;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = SupabaseService.currentUser;
    final shopName =
        user?.userMetadata?['shop_name'] as String? ?? 'My Store';
    final ownerName =
        user?.userMetadata?['owner_name'] as String? ?? 'Owner';
    final today = DateFormat('EEEE, d MMMM y').format(DateTime.now());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('नमस्ते, $ownerName! 🙏',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(shopName,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14)),
                            Text(today,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppConstants.routeSettings),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'K',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Cards
                statsAsync.when(
                  loading: () => _StatsGridSkeleton(),
                  error: (e, _) => Center(
                    child: Text('Failed to load stats',
                        style: TextStyle(color: AppTheme.danger))),
                  data: (stats) => _StatsGrid(stats: stats),
                ),
                const SizedBox(height: 20),

                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quick Actions',
                        style: Theme.of(context).textTheme.headlineSmall),
                    TextButton.icon(
                      onPressed: () => context.push(AppConstants.routeBilling),
                      icon: const Icon(Icons.history_rounded, size: 20),
                      label: const Text('Order History', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'New Bill',
                        color: AppTheme.primary,
                        onTap: () => context.push(AppConstants.routeCreateBill),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_box_rounded,
                        label: 'Add Product',
                        color: AppTheme.secondary,
                        onTap: () => context.push(AppConstants.routeAddProduct),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.person_add_rounded,
                        label: 'Add Customer',
                        color: AppTheme.warning,
                        onTap: () => context.push(AppConstants.routeAddCustomer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Mock Data',
                        color: const Color(0xFF0D9488),
                        onTap: () async {
                            final userId = SupabaseService.userId;
                            if (userId == null) return;
                            try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Adding mock products...'))
                                );
                                final existingRows = await LocalDatabase.query('products');
                                final existingNames = existingRows.map((r) => r['name'] as String).toSet();
                                
                                final brands = ['Tata', 'Aashirvaad', 'Amul', 'Britannia', 'Nestle', 'Parle', 'Godrej', 'Patanjali', 'Dabur', 'Haldirams', 'Everest', 'Fortune'];
                                final items = ['Atta', 'Salt', 'Milk', 'Biscuits', 'Coffee', 'Tea', 'Soap', 'Oil', 'Butter', 'Ghee', 'Juice', 'Noodles', 'Rice', 'Dal', 'Sugar', 'Poha'];
                                final weights = ['1kg', '500g', '5kg', '200g', '1L', '500ml', '250g', '100g'];
                                final cats = ['Groceries', 'Dairy', 'Snacks', 'Beverages', 'Personal Care', 'Spices'];
                                
                                List<Product> newMocks = [];
                                final rand = math.Random();
                                
                                int attempts = 0;
                                while(newMocks.length < 5 && attempts < 200) {
                                  attempts++;
                                  final name = '${brands[rand.nextInt(brands.length)]} ${items[rand.nextInt(items.length)]} ${weights[rand.nextInt(weights.length)]}';
                                  if (!existingNames.contains(name)) {
                                    existingNames.add(name);
                                    final cost = (rand.nextInt(200) + 20).toDouble();
                                    final price = cost + (cost * 0.2).roundToDouble();
                                    newMocks.add(Product.create(
                                      userId: userId,
                                      name: name,
                                      category: cats[rand.nextInt(cats.length)],
                                      price: price,
                                      costPrice: cost,
                                      quantity: rand.nextInt(100) + 10,
                                      unit: name.contains('L') || name.contains('ml') ? 'litre' : 'pack',
                                    ));
                                  }
                                }

                                for (var item in newMocks) {
                                   await SupabaseService.upsertProduct(item.toMap());
                                }
                                ref.invalidate(dashboardStatsProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Successfully loaded mock products!'), backgroundColor: Color(0xFF059669))
                                );
                            } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger)
                                );
                            }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Low stock alert
                statsAsync.maybeWhen(
                  data: (stats) {
                    final lowCount = stats['low_stock_count'] ?? 0;
                    if (lowCount == 0) return const SizedBox.shrink();
                    return _LowStockBanner(count: lowCount);
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: "Today's Sales",
          value: fmt.format(stats['total_sales'] ?? 0),
          icon: Icons.trending_up_rounded,
          gradient: AppTheme.primaryGradient,
          subtitle: '${stats['bill_count'] ?? 0} bills',
        ),
        _StatCard(
          title: 'Collected',
          value: fmt.format(stats['total_collected'] ?? 0),
          icon: Icons.payments_rounded,
          gradient: AppTheme.greenGradient,
          subtitle: 'Cash + UPI',
        ),
        _StatCard(
          title: 'Total Products',
          value: '${stats['product_count'] ?? 0}',
          icon: Icons.inventory_2_rounded,
          gradient: LinearGradient(colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF60A5FA)
          ]),
          subtitle: 'Active items',
        ),
        _StatCard(
          title: 'Udhar Pending',
          value: fmt.format(stats['total_credit'] ?? 0),
          icon: Icons.account_balance_wallet_rounded,
          gradient: AppTheme.warningGradient,
          subtitle: 'Outstanding credit',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: List.generate(4, (i) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      )),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  final int count;
  const _LowStockBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Low Stock Alert ⚠️',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warning,
                        fontSize: 14)),
                Text('$count product${count > 1 ? 's are' : ' is'} running low on stock',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppConstants.routeInventory),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
