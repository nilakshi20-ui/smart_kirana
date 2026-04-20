// lib/features/auth/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await SupabaseService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        shopName: _shopNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) context.go(AppConstants.routeDashboard);
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set up your store 🏪',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text('Fill in your details to get started',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                    ),
                    child: Text(_error!,
                        style: TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                CustomTextField(
                  controller: _shopNameCtrl,
                  label: 'Shop Name',
                  hint: 'e.g. Ram Kirana Store',
                  prefixIcon: Icons.storefront_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Shop name required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _ownerNameCtrl,
                  label: 'Owner Name',
                  hint: 'Your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Owner name required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: '10-digit mobile number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone required';
                    if (v.length < 10) return 'Enter valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: 'Min 6 characters',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Create Account',
                  onTap: _loading ? null : _signup,
                  isLoading: _loading,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                            color: AppTheme.textSecondaryLight, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
