// lib/features/billing/screens/bill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/bill_model.dart';
import '../../../core/theme/app_theme.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Bill? _bill;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final billRow = await LocalDatabase.queryById('bills', widget.billId);
    if (billRow == null) { setState(() => _loading = false); return; }
    final itemRows = await LocalDatabase.query('bill_items',
        where: 'bill_id = ?', whereArgs: [widget.billId]);
    final items = itemRows.map((r) => BillItem.fromMap(r)).toList();
    setState(() {
      _bill = Bill.fromMap(billRow, items);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_bill == null) return const Scaffold(body: Center(child: Text('Bill not found')));

    final bill = _bill!;
    final fmt = DateFormat('d MMMM y, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {}, // TODO: PDF share
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text('₹${bill.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                  Text(fmt.format(bill.createdAt),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bill.paymentMode.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (bill.customerName != null) ...[
              _InfoRow(Icons.person_outline, 'Customer', bill.customerName!),
              const SizedBox(height: 20),
            ],

            // Items
            Text('Items', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  ...bill.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('${item.quantity} × ₹${item.unitPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryLight)),
                              ],
                            )),
                            Text('₹${item.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      ),
                      if (i < bill.items.length - 1)
                        const Divider(height: 1, indent: 14, endIndent: 14),
                    ]);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(children: [
                _SummaryRow('Subtotal', '₹${bill.subtotal.toStringAsFixed(2)}'),
                if (bill.discountAmount > 0)
                  _SummaryRow('Discount',
                      '-₹${bill.discountAmount.toStringAsFixed(2)}',
                      color: AppTheme.secondary),
                if (bill.taxAmount > 0)
                  _SummaryRow('GST',
                      '+₹${bill.taxAmount.toStringAsFixed(2)}'),
                const Divider(height: 16),
                _SummaryRow('Total', '₹${bill.totalAmount.toStringAsFixed(2)}',
                    isBold: true, color: AppTheme.primary),
                if (bill.creditAmount > 0)
                  _SummaryRow('Udhar (Pending)',
                      '₹${bill.creditAmount.toStringAsFixed(2)}',
                      color: AppTheme.warning),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppTheme.textSecondaryLight),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(
          fontSize: 13, color: AppTheme.textSecondaryLight)),
      Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _SummaryRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: color ?? AppTheme.textSecondaryLight)),
        Text(value, style: TextStyle(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppTheme.textPrimaryLight)),
      ],
    ),
  );
}
