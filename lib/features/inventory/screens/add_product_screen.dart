// lib/features/inventory/screens/add_product_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'inventory_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '10');
  final _supplierCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();

  String _selectedCategory = AppConstants.productCategories.first;
  String _selectedUnit = 'piece';
  bool _loading = false;
  bool _isEditing = false;
  Product? _existingProduct;

  static const units = ['piece', 'kg', 'gram', 'litre', 'ml', 'pack', 'dozen', 'box'];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEditing = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final row = await LocalDatabase.queryById('products', widget.productId!);
    if (row != null) {
      _existingProduct = Product.fromMap(row);
      setState(() {
        _nameCtrl.text = _existingProduct!.name;
        _priceCtrl.text = _existingProduct!.price.toString();
        _costCtrl.text = _existingProduct!.costPrice.toString();
        _qtyCtrl.text = _existingProduct!.quantity.toString();
        _thresholdCtrl.text = _existingProduct!.lowStockThreshold.toString();
        _supplierCtrl.text = _existingProduct!.supplier ?? '';
        _barcodeCtrl.text = _existingProduct!.barcode ?? '';
        _selectedCategory = _existingProduct!.category;
        _selectedUnit = _existingProduct!.unit;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final userId = SupabaseService.userId!;
      Product product;

      if (_isEditing && _existingProduct != null) {
        product = _existingProduct!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceCtrl.text),
          costPrice: double.parse(_costCtrl.text),
          quantity: int.parse(_qtyCtrl.text),
          lowStockThreshold: int.parse(_thresholdCtrl.text),
          supplier: _supplierCtrl.text.trim().isNotEmpty
              ? _supplierCtrl.text.trim()
              : null,
          barcode: _barcodeCtrl.text.trim().isNotEmpty
              ? _barcodeCtrl.text.trim()
              : null,
          unit: _selectedUnit,
        );
        await LocalDatabase.update('products', product.toMap(), product.id);
      } else {
        product = Product.create(
          userId: userId,
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceCtrl.text),
          costPrice: double.parse(_costCtrl.text),
          quantity: int.parse(_qtyCtrl.text),
          lowStockThreshold: int.parse(_thresholdCtrl.text),
          supplier: _supplierCtrl.text.trim().isNotEmpty
              ? _supplierCtrl.text.trim()
              : null,
          barcode: _barcodeCtrl.text.trim().isNotEmpty
              ? _barcodeCtrl.text.trim()
              : null,
          unit: _selectedUnit,
        );
        await LocalDatabase.insert('products', product.toMap());
      }

      // Try cloud sync
      if (kIsWeb) {
        await SupabaseService.upsertProduct(product.toMap());
      } else {
        SupabaseService.upsertProduct(product.toMap()).catchError((_) {});
      }

      // Invalidate dashboard stats so count updates immediately
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing
              ? 'Product updated successfully!'
              : 'Product added successfully!'),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && _existingProduct != null) {
      await LocalDatabase.update(
          'products', {'is_active': 0}, _existingProduct!.id);
      if (kIsWeb) {
        await SupabaseService.deleteProduct(_existingProduct!.id);
      } else {
        SupabaseService.deleteProduct(_existingProduct!.id).catchError((_) {});
      }
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productsProvider);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _costCtrl.dispose();
    _qtyCtrl.dispose(); _thresholdCtrl.dispose();
    _supplierCtrl.dispose(); _barcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Info Section
            _SectionHeader(title: 'Basic Information'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nameCtrl,
              label: 'Product Name *',
              hint: 'e.g. Tata Salt 1kg',
              prefixIcon: Icons.shopping_bag_outlined,
              validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 14),
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_outlined, size: 20),
              ),
              items: AppConstants.productCategories.map((cat) =>
                DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)))
              ).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 14),
            // Unit
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unit',
                prefixIcon: Icon(Icons.straighten_outlined, size: 20),
              ),
              items: units.map((u) =>
                DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 14)))
              ).toList(),
              onChanged: (v) => setState(() => _selectedUnit = v!),
            ),
            const SizedBox(height: 24),

            // Pricing Section
            _SectionHeader(title: 'Pricing'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _priceCtrl,
                    label: 'Selling Price (₹) *',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    controller: _costCtrl,
                    label: 'Cost Price (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee_rounded,
                    validator: (v) {
                      if (v != null && v.isNotEmpty &&
                          double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stock Section
            _SectionHeader(title: 'Stock Management'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _qtyCtrl,
                    label: 'Current Quantity *',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.inventory_2_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    controller: _thresholdCtrl,
                    label: 'Low Stock Alert At',
                    hint: '10',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Optional
            _SectionHeader(title: 'Optional Details'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _supplierCtrl,
              label: 'Supplier Name',
              hint: 'e.g. ABC Distributors',
              prefixIcon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _barcodeCtrl,
              label: 'Barcode',
              hint: 'Scan or enter barcode',
              prefixIcon: Icons.qr_code_scanner,
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                onPressed: () {}, // TODO: implement scanner
              ),
            ),
            const SizedBox(height: 32),
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _delete,
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                      label: const Text('Delete', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.danger.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      text: 'Update Product',
                      onTap: _loading ? null : _save,
                      isLoading: _loading,
                      icon: Icons.save_rounded,
                    ),
                  ),
                ],
              )
            else
              GradientButton(
                text: 'Add Product',
                onTap: _loading ? null : _save,
                isLoading: _loading,
                icon: Icons.add_rounded,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18,
            decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
