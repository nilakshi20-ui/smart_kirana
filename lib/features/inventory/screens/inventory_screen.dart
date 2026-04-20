// lib/features/inventory/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final userId = SupabaseService.userId;
  if (userId == null) return [];
  final rows = await LocalDatabase.query('products',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'name ASC');
  return rows.map((r) => Product.fromMap(r)).toList();
});

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppConstants.routeAddProduct)
                .then((_) => ref.invalidate(productsProvider)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''))
                    : null,
              ),
            ),
          ),
          // Category Filter
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: AppConstants.productCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = i == 0 ? null : AppConstants.productCategories[i - 1];
                final isSelected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat ?? 'All'),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = isSelected ? null : cat),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
          // Products List
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: AppTheme.danger))),
              data: (products) {
                final filtered = products.where((p) {
                  final matchSearch = _search.isEmpty ||
                      p.name.toLowerCase().contains(_search.toLowerCase());
                  final matchCat = _selectedCategory == null ||
                      p.category == _selectedCategory;
                  return matchSearch && matchCat;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No products found',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          onPressed: () =>
                              context.push(AppConstants.routeAddProduct),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _ProductCard(product: filtered[i], onRefresh: () {
                        ref.invalidate(productsProvider);
                      }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRefresh;
  const _ProductCard({required this.product, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context
          .push('${AppConstants.routeEditProduct}/${product.id}')
          .then((_) => onRefresh()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: product.isLowStock
                ? AppTheme.warning.withOpacity(0.4)
                : AppTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2_rounded,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(product.category,
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondaryLight)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Low Stock',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w600)),
                        )
                      else
                        Text('Qty: ${product.quantity} ${product.unit}',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.primary)),
                Text('Cost: ₹${product.costPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
