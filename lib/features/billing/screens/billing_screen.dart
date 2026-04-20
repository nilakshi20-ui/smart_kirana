// lib/features/billing/screens/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/bill_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

final billsProvider = FutureProvider.autoDispose<List<Bill>>((ref) async {
  final userId = SupabaseService.userId;
  if (userId == null) return [];
  final rows = await LocalDatabase.query('bills',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 100);
  return rows.map((r) => Bill.fromMap(r, [])).toList();
});

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () => context.push(AppConstants.routeCreateBill)
                .then((_) => ref.invalidate(billsProvider)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No bills yet',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Bill'),
                    onPressed: () => context.push(AppConstants.routeCreateBill),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _BillCard(bill: bills[i], invoiceId: bills.length - i),
          );
        },
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final int invoiceId;
  const _BillCard({required this.bill, required this.invoiceId});

  Color get _paymentColor => bill.paymentMode == AppConstants.paymentCash
      ? AppTheme.secondary
      : bill.paymentMode == AppConstants.paymentUpi
          ? AppTheme.primary
          : AppTheme.warning;

  String get _paymentLabel => bill.paymentMode == AppConstants.paymentCash
      ? 'Cash'
      : bill.paymentMode == AppConstants.paymentUpi
          ? 'UPI'
          : 'Udhar';

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y, h:mm a');
    return GestureDetector(
      onTap: () => context.push('/billing/${bill.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _paymentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                bill.paymentMode == AppConstants.paymentCash
                    ? Icons.money
                    : bill.paymentMode == AppConstants.paymentUpi
                        ? Icons.phone_android_rounded
                        : Icons.account_balance_wallet,
                color: _paymentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$invoiceId',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        bill.customerName ?? 'Walk-in Customer',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(fmt.format(bill.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondaryLight)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _paymentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_paymentLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _paymentColor)),
                  ),
                ],
              ),
            ),
            Text('₹${bill.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryLight)),
          ],
        ),
      ),
    );
  }
}
