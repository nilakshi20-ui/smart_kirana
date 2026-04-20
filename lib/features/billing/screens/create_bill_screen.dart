// lib/features/billing/screens/create_bill_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/bill_model.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  List<CartItem> _cart = [];
  List<Product> _products = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  String _paymentMode = AppConstants.paymentCash;
  double _discount = 0;
  bool _applyGst = false;
  String _productSearch = '';
  bool _loading = false;
  final TextEditingController _walkInNameCtrl = TextEditingController();
  final TextEditingController _walkInPhoneCtrl = TextEditingController();

  double get _subtotal =>
      _cart.fold(0, (sum, item) => sum + item.totalPrice);
  double get _taxAmount => _applyGst ? _subtotal * AppConstants.defaultGstRate : 0;
  double get _total => _subtotal - _discount + _taxAmount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = SupabaseService.userId!;
    final productRows = await LocalDatabase.query('products',
        where: 'user_id = ? AND is_active = 1 AND quantity > 0',
        whereArgs: [userId],
        orderBy: 'name ASC');
    final customerRows = await LocalDatabase.query('customers',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'name ASC');
    setState(() {
      _products = productRows.map((r) => Product.fromMap(r)).toList();
      _customers = customerRows.map((r) => Customer.fromMap(r)).toList();
    });
  }

  void _addToCart(Product product) {
    final idx = _cart.indexWhere((i) => i.product.id == product.id);
    setState(() {
      if (idx >= 0) {
        if (_cart[idx].quantity < product.quantity) {
          _cart[idx].quantity++;
        }
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() => _cart.removeWhere((i) => i.product.id == item.product.id));
  }

  void _updateQty(CartItem item, int delta) {
    final idx = _cart.indexWhere((i) => i.product.id == item.product.id);
    if (idx < 0) return;
    setState(() {
      _cart[idx].quantity += delta;
      if (_cart[idx].quantity <= 0) _cart.removeAt(idx);
    });
  }

  Future<void> _completeBill() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one product to the cart'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_paymentMode == AppConstants.paymentCredit && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select a customer for credit (Udhar) payment'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final userId = SupabaseService.userId!;
      final billId = const Uuid().v4();

      final billItems = _cart.map((item) =>
        BillItem.fromProduct(billId: billId, product: item.product, quantity: item.quantity)
      ).toList();

      String? finalCustomerName = _selectedCustomer?.name;
      if (_selectedCustomer == null && (_walkInNameCtrl.text.isNotEmpty || _walkInPhoneCtrl.text.isNotEmpty)) {
        finalCustomerName = '${_walkInNameCtrl.text.trim()} ${_walkInPhoneCtrl.text.trim()}'.trim();
      }

      final bill = Bill.create(
        userId: userId,
        customerId: _selectedCustomer?.id,
        customerName: finalCustomerName,
        items: billItems,
        subtotal: _subtotal,
        discountAmount: _discount,
        taxAmount: _taxAmount,
        paymentMode: _paymentMode,
        amountPaid: _paymentMode != AppConstants.paymentCredit ? _total : 0,
      );

      // Save bill to local DB
      await LocalDatabase.insert('bills', bill.toMap()); // without id override
      for (final item in billItems) {
        await LocalDatabase.insert('bill_items', item.toMap());
      }

      // Deduct inventory
      for (final cartItem in _cart) {
        final newQty = cartItem.product.quantity - cartItem.quantity;
        await LocalDatabase.update('products',
            {'quantity': newQty, 'updated_at': DateTime.now().toIso8601String()},
            cartItem.product.id);
      }

      // Update customer credit
      if (_paymentMode == AppConstants.paymentCredit && _selectedCustomer != null) {
        final newCredit = _selectedCustomer!.totalCredit + _total;
        await LocalDatabase.update('customers',
            {'total_credit': newCredit, 'updated_at': DateTime.now().toIso8601String()},
            _selectedCustomer!.id);

        // Credit transaction
        await LocalDatabase.insert('credit_transactions', {
          'id': const Uuid().v4(),
          'customer_id': _selectedCustomer!.id,
          'bill_id': bill.id,
          'amount': _total,
          'type': 'credit',
          'notes': 'Bill #${bill.id.substring(0, 8)}',
          'sync_status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Cloud sync (fire and forget)
      SupabaseService.insertBill(
        bill.toMap(),
        billItems.map((i) => i.toMap()).toList(),
      ).catchError((_) {});

      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Bill created successfully! ✅'),
          backgroundColor: AppTheme.secondary,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) =>
      _productSearch.isEmpty ||
      p.name.toLowerCase().contains(_productSearch.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Bill')),
      body: Row(
        children: [
          // Left: Product Search
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (v) => setState(() => _productSearch = v),
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final p = filteredProducts[i];
                      return GestureDetector(
                        onTap: () => _addToCart(p),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text('Qty: ${p.quantity} • ₹${p.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondaryLight)),
                                ],
                              )),
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: Cart
          Container(
            width: MediaQuery.of(context).size.width * 0.48,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Cart (${_cart.length} items)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Cart Items
                Expanded(
                  child: _cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('Tap products to add',
                                style: TextStyle(color: Colors.grey.shade400,
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _cart.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = _cart[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text('₹${item.totalPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                )),
                                Row(
                                  children: [
                                    _QtyBtn(icon: Icons.remove,
                                        onTap: () => _updateQty(item, -1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text('${item.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                    ),
                                    _QtyBtn(icon: Icons.add,
                                        onTap: () => _updateQty(item, 1)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    border: const Border(top: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer
                      DropdownButtonFormField<Customer?>(
                        value: _selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'Customer (optional)',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<Customer?>(
                            value: null,
                            child: Text('Walk-in Customer',
                                style: TextStyle(fontSize: 13))),
                          ..._customers.map((c) => DropdownMenuItem<Customer?>(
                            value: c,
                            child: Text('${c.id.substring(0, 5).toUpperCase()} | ${c.name} | ${c.phone}',
                                style: const TextStyle(fontSize: 13)))),
                        ],
                        onChanged: (v) => setState(() => _selectedCustomer = v),
                      ),
                      if (_selectedCustomer == null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _walkInNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Walk-in Name',
                                  prefixIcon: Icon(Icons.person, size: 16),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _walkInPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone No.',
                                  prefixIcon: Icon(Icons.phone, size: 16),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Discount
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() =>
                            _discount = double.tryParse(v) ?? 0),
                        decoration: const InputDecoration(
                          labelText: 'Discount (₹)',
                          prefixIcon: Icon(Icons.discount_outlined, size: 18),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // GST
                      Row(
                        children: [
                          Checkbox(
                              value: _applyGst,
                              onChanged: (v) =>
                                  setState(() => _applyGst = v!),
                              visualDensity: VisualDensity.compact),
                          const Text('Apply GST (18%)',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      // Payment Mode
                      const SizedBox(height: 4),
                      const Text('Payment Mode',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _PayModeChip(
                              label: 'Cash',
                              icon: Icons.money,
                              isSelected: _paymentMode == AppConstants.paymentCash,
                              onTap: () => setState(() =>
                                  _paymentMode = AppConstants.paymentCash)),
                          const SizedBox(width: 6),
                          _PayModeChip(
                              label: 'UPI',
                              icon: Icons.phone_android_rounded,
                              isSelected: _paymentMode == AppConstants.paymentUpi,
                              onTap: () => setState(() =>
                                  _paymentMode = AppConstants.paymentUpi)),
                          const SizedBox(width: 6),
                          _PayModeChip(
                              label: 'Udhar',
                              icon: Icons.account_balance_wallet,
                              isSelected: _paymentMode == AppConstants.paymentCredit,
                              onTap: () => setState(() =>
                                  _paymentMode = AppConstants.paymentCredit)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Totals
                      _TotalRow('Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
                      if (_discount > 0)
                        _TotalRow('Discount', '-₹${_discount.toStringAsFixed(0)}',
                            color: AppTheme.secondary),
                      if (_taxAmount > 0)
                        _TotalRow('GST (18%)', '+₹${_taxAmount.toStringAsFixed(0)}'),
                      const Divider(height: 12),
                      _TotalRow('TOTAL', '₹${_total.toStringAsFixed(0)}',
                          isBold: true, color: AppTheme.primary),
                      const SizedBox(height: 10),
                      GradientButton(
                        text: 'Complete Bill',
                        onTap: _loading ? null : _completeBill,
                        isLoading: _loading,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: AppTheme.primary),
    ),
  );
}

class _PayModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _PayModeChip({
    required this.label, required this.icon,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: isSelected ? Colors.white : AppTheme.textSecondaryLight),
            Text(label, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondaryLight)),
          ],
        ),
      ),
    ),
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _TotalRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: color ?? AppTheme.textSecondaryLight)),
        Text(value, style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppTheme.textPrimaryLight)),
      ],
    ),
  );
}
