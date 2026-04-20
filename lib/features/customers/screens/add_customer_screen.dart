// lib/features/customers/screens/add_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/local_database.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AddCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _pendingCtrl = TextEditingController();
  bool _loading = false;
  XFile? _selectedImage;
  
  bool get _isEditing => widget.customerId != null;
  Customer? _existingCustomer;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() => _loading = true);
    final data = await LocalDatabase.queryById('customers', widget.customerId!);
    if (data != null) {
      _existingCustomer = Customer.fromMap(data);
      _nameCtrl.text = _existingCustomer!.name;
      _phoneCtrl.text = _existingCustomer!.phone;
      _notesCtrl.text = _existingCustomer!.notes ?? '';
      _pendingCtrl.text = _existingCustomer!.totalCredit.toStringAsFixed(0);
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? finalProfileUrl = _existingCustomer?.profileUrl;
      
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.name.split('.').last;
        finalProfileUrl = await SupabaseService.uploadProfilePicture('customers', bytes, ext);
      }

      final double totalCredit = double.tryParse(_pendingCtrl.text) ?? 0.0;
      
      final customer = _isEditing && _existingCustomer != null
        ? _existingCustomer!.copyWith(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
            totalCredit: totalCredit,
            profileUrl: finalProfileUrl,
          )
        : Customer.create(
            userId: SupabaseService.userId!,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
            profileUrl: finalProfileUrl,
            totalCredit: totalCredit,
          );

      if (_isEditing) {
        await LocalDatabase.update('customers', customer.toMap(), customer.id);
      } else {
        await LocalDatabase.insert('customers', customer.toMap());
      }

      if (kIsWeb) {
        await SupabaseService.upsertCustomer(customer.toMap());
      } else {
        SupabaseService.upsertCustomer(customer.toMap()).catchError((_) {});
      }

      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Customer updated successfully! ✅' : 'Customer added successfully! ✅'),
          backgroundColor: AppTheme.secondary,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Customer' : 'Add Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final cropped = await ImageCropper().cropImage(
                      sourcePath: image.path,
                      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                      uiSettings: [
                        WebUiSettings(
                          context: context,
                          presentStyle: WebPresentStyle.page,
                        ),
                      ],
                    );
                    if (cropped != null) {
                      setState(() => _selectedImage = XFile(cropped.path));
                    }
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        image: _selectedImage != null
                            ? DecorationImage(image: NetworkImage(_selectedImage!.path), fit: BoxFit.cover)
                            : (_isEditing && _existingCustomer?.profileUrl != null)
                                ? DecorationImage(image: NetworkImage(_existingCustomer!.profileUrl!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: (_selectedImage == null && !(_isEditing && _existingCustomer?.profileUrl != null))
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 44)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            CustomTextField(
              controller: _nameCtrl,
              label: 'Customer Name *',
              hint: 'e.g. Ramesh Kumar',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _phoneCtrl,
              label: 'Phone Number *',
              hint: '10-digit mobile number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Phone is required';
                if (v.length < 10) return 'Enter valid 10-digit number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _pendingCtrl,
              label: 'Initial Udhar/Pending Amount (₹)',
              hint: '0',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              hint: 'e.g. Prefers payment on 1st',
              prefixIcon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: _isEditing ? 'Update Customer' : 'Add Customer',
              onTap: _loading ? null : _save,
              isLoading: _loading,
              icon: _isEditing ? Icons.save_rounded : Icons.person_add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
