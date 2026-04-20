// lib/features/customers/screens/customer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/models/bill_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';

import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  List<Bill> _bills = [];
  List<Map<String, dynamic>> _creditHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await LocalDatabase.queryById('customers', widget.customerId);
    if (row == null) { setState(() => _loading = false); return; }

    final billRows = await LocalDatabase.query('bills',
        where: 'customer_id = ?',
        whereArgs: [widget.customerId],
        orderBy: 'created_at DESC',
        limit: 20);
    final creditRows = await LocalDatabase.query('credit_transactions',
        where: 'customer_id = ?',
        whereArgs: [widget.customerId],
        orderBy: 'created_at DESC');

    setState(() {
      _customer = Customer.fromMap(row);
      _bills = billRows.map((r) => Bill.fromMap(r, [])).toList();
      _creditHistory = creditRows;
      _loading = false;
    });
  }

  Future<void> _recordPayment() async {
    final amtCtrl = TextEditingController();
    
    double effectiveCredit = _customer!.totalCredit;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Outstanding: ₹${effectiveCredit.toStringAsFixed(0)}',
                style: TextStyle(color: AppTheme.warning,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Record'),
          ),
        ],
      ),
    );

    if (confirmed == true && amtCtrl.text.isNotEmpty) {
      final amount = double.tryParse(amtCtrl.text) ?? 0;
      if (amount <= 0) return;

      final newCredit = (effectiveCredit - amount).clamp(0, double.infinity);
      await LocalDatabase.update('customers',
          {'total_credit': newCredit, 'updated_at': DateTime.now().toIso8601String()},
          _customer!.id);
      await LocalDatabase.insert('credit_transactions', {
        'id': const Uuid().v4(),
        'customer_id': _customer!.id,
        'bill_id': null,
        'amount': amount,
        'type': 'payment',
        'notes': 'Payment received',
        'sync_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment of ₹${amount.toStringAsFixed(0)} recorded!'),
          backgroundColor: AppTheme.secondary,
        ));
      }
    }
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDatabase.delete('customers', widget.customerId);
      SupabaseService.deleteCustomer(widget.customerId).catchError((_){});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_customer == null) return const Scaffold(body: Center(child: Text('Customer not found')));

    final c = _customer!;
    final fmt = DateFormat('d MMM y');
    
    double effectiveCredit = c.totalCredit;
    final bool displayHasCredit = effectiveCredit > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (c.profileUrl != null) {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => FullScreenImageViewer(
                              imageUrl: c.profileUrl!,
                              tag: 'profile_${c.id}',
                            ),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: 'profile_${c.id}',
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        backgroundImage: c.profileUrl != null ? NetworkImage(c.profileUrl!) : null,
                        child: c.profileUrl == null
                            ? Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 28,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(c.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text(c.phone,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  if (c.notes != null && c.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Notes: ${c.notes}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (displayHasCredit) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Text('Udhar Pending',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                        Text('₹${effectiveCredit.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24,
                                fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Record Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                        ),
                        onPressed: _recordPayment,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        const Text('No Pending Dues',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    ),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                        label: const Text('Edit User', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => context.push('${AppConstants.routeEditCustomer}/${c.id}').then((_) => _load()),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent),
                        label: const Text('Delete User', style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _deleteCustomer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bills
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchase History (${_bills.length})',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  if (_bills.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No purchases yet',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ),
                    )
                  else
                    ...(_bills.map((bill) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmt.format(bill.createdAt),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(bill.paymentMode.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondaryLight)),
                            ],
                          )),
                          Text('₹${bill.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16,
                                  color: AppTheme.primary)),
                        ],
                      ),
                    ))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
