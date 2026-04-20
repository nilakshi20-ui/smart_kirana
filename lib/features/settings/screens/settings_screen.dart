// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _uploading = false;

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.signOut();
      if (context.mounted) context.go(AppConstants.routeLogin);
    }
  }

  Future<void> _changeProfilePic() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

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
    if (cropped == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await cropped.readAsBytes();
      final ext = cropped.path.split('.').last;
      final url = await SupabaseService.uploadProfilePicture('owners', bytes, ext);
      await SupabaseService.updateOwnerProfile(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final shopName = user?.userMetadata?['shop_name'] as String? ?? 'My Store';
    final ownerName = user?.userMetadata?['owner_name'] as String? ?? 'Owner';
    final phone = user?.userMetadata?['phone'] as String? ?? '';
    final profileUrl = user?.userMetadata?['profile_url'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploading ? null : _changeProfilePic,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                          child: profileUrl == null
                            ? Text(
                                ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 32,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                        ),
                        if (_uploading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
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
                  const SizedBox(height: 12),
                  Text(ownerName,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text(shopName,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  if (phone.isNotEmpty)
                    Text(phone,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Text(user?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Store'),
                  _SettingsTile(
                      icon: Icons.store_outlined,
                      title: 'Shop Name',
                      subtitle: shopName,
                      onTap: () {}),
                  _SettingsTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: phone,
                      onTap: () {}),

                  const SizedBox(height: 16),
                  _SectionLabel('Preferences'),
                  _SettingsTile(
                      icon: Icons.currency_rupee,
                      title: 'Currency',
                      subtitle: 'Indian Rupee (₹)',
                      onTap: () {}),
                  _SettingsTile(
                      icon: Icons.warning_amber_outlined,
                      title: 'Default Low Stock Threshold',
                      subtitle: '${AppConstants.defaultLowStockThreshold} units',
                      onTap: () {}),
                  _SettingsTile(
                      icon: Icons.receipt_outlined,
                      title: 'Default GST Rate',
                      subtitle: '${(AppConstants.defaultGstRate * 100).toInt()}%',
                      onTap: () {}),

                  const SizedBox(height: 16),
                  _SectionLabel('Data & Sync'),
                  _SettingsTile(
                      icon: Icons.sync_rounded,
                      title: 'Sync Data',
                      subtitle: 'Sync local data with cloud',
                      onTap: () {}),
                  _SettingsTile(
                      icon: Icons.download_outlined,
                      title: 'Export Data',
                      subtitle: 'Export as CSV',
                      onTap: () {}),
                  _SettingsTile(
                      icon: Icons.backup_outlined,
                      title: 'Backup',
                      subtitle: 'Create a data backup',
                      onTap: () {}),

                  const SizedBox(height: 16),
                  _SectionLabel('About'),
                  _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: AppConstants.appVersion,
                      onTap: () {}),
                  _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      onTap: () {}),

                  const SizedBox(height: 24),
                  // Sign Out
                  GestureDetector(
                    onTap: () => _signOut(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.danger.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: AppTheme.danger, size: 20),
                          const SizedBox(width: 10),
                          Text('Sign Out',
                              style: TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondaryLight,
          letterSpacing: 1.0),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18,
              color: AppTheme.textSecondaryLight),
        ],
      ),
    ),
  );
}
