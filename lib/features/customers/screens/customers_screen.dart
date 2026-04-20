// lib/features/customers/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';

final customersProvider =
    FutureProvider.autoDispose<List<Customer>>((ref) async {
  final userId = SupabaseService.userId;
  if (userId == null) return [];
  final rows = await LocalDatabase.query('customers',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC');
  return rows.map((r) => Customer.fromMap(r)).toList();
});

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => context.push(AppConstants.routeAddCustomer)
                .then((_) => ref.invalidate(customersProvider)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (customers) {
                final filtered = customers.where((c) =>
                  _search.isEmpty ||
                  c.name.toLowerCase().contains(_search.toLowerCase()) ||
                  c.phone.contains(_search)
                ).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No customers yet',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Customer'),
                          onPressed: () =>
                              context.push(AppConstants.routeAddCustomer),
                        ),
                      ],
                    ),
                  );
                }

                // Summary bar
                final totalCredit = customers.fold(
                    0.0, (sum, c) => sum + c.totalCredit);
                return Column(
                  children: [
                    if (totalCredit > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: AppTheme.warning, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Udhar Pending: ₹${totalCredit.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.warning),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _CustomerCard(customer: filtered[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/customers/${customer.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: customer.hasCredit
                ? AppTheme.warning.withOpacity(0.4)
                : AppTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (customer.profileUrl != null) {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => FullScreenImageViewer(
                        imageUrl: customer.profileUrl!,
                        tag: 'profile_list_${customer.id}',
                      ),
                    ),
                  );
                }
              },
              child: Hero(
                tag: 'profile_list_${customer.id}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  backgroundImage: customer.profileUrl != null ? NetworkImage(customer.profileUrl!) : null,
                  child: customer.profileUrl == null
                      ? Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppTheme.primary),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(customer.phone,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondaryLight)),
                ],
              ),
            ),
            if (customer.hasCredit)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Udhar',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.warning,
                          fontWeight: FontWeight.w600)),
                  Text('₹${customer.totalCredit.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.warning)),
                ],
              )
            else
              Icon(Icons.check_circle_outline,
                  color: AppTheme.secondary, size: 22),
          ],
        ),
      ),
    );
  }
}
