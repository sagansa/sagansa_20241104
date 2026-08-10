import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/admin_profile_list_page.dart';
import '../pages/home_page.dart';
import '../pages/printer_settings_page.dart';
import '../pages/profile_page.dart';
import '../providers/auth_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/error_utils.dart';
import '../widgets/app_version_text.dart';

/// Drawer navigasi seragam untuk seluruh halaman (Home maupun dashboard
/// operasional). Tujuannya menghilangkan duplikasi Drawer copy-paste yang
/// sebelumnya berbeda antara HomePage dan DashboardScaffold.
///
/// item dasar: Beranda, Printer Thermal, Bantuan, Logout.
/// [extraItems] dipakai untuk menu khusus (mis. Profil Saya, Kelola Profil).
/// [showAppVersion] menampilkan [AppVersionText] di bagian bawah.
class AppDrawer extends StatelessWidget {
  final String userName;
  final String companyName;
  final List<Widget> extraItems;
  final bool showAppVersion;
  final Future<void> Function(BuildContext context)? onLogout;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.companyName,
    this.extraItems = const [],
    this.showAppVersion = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 48,
                    fit: BoxFit.contain,
                    height: 48,
                  ),
                ),
                AppSpacing.gapVerticalSM,
                Text(
                  userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  companyName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () {
              Navigator.pop(context);
              // Bila route saat ini sudah HomePage, cukup tutup drawer
              // (sama seperti perilaku drawer lama di home). Jika tidak,
              // ganti ke HomePage.
              final route = ModalRoute.of(context);
              final isHome = route is MaterialPageRoute &&
                  route.builder(context) is HomePage;
              if (isHome) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
          ...extraItems,
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Printer Thermal'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Bantuan'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('Logout', style: TextStyle(color: colorScheme.error)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                Navigator.pop(context);
                if (onLogout != null) {
                  await onLogout!(context);
                } else {
                  await _logout(context);
                }
              }
            },
          ),
          if (showAppVersion) ...[
            const AppVersionText(),
          ],
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorUtils.sanitize(e))),
        );
      }
    }
  }

  /// Helper pembaca data user dari SharedPreferences (seragam dengan
  /// DashboardScaffold) agar pemanggil tidak perlu duplikasi.
  /// Mengembalikan name, company, dan isAdmin.
  static Future<Map<String, dynamic>> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final roles = List<String>.from(userData['roles'] ?? []);
        final isAdmin =
            roles.contains('admin') || roles.contains('super_admin');
        return {
          'name': userData['name'] ?? '',
          'company': userData['company']?['name'] ?? 'SAGANSA',
          'isAdmin': isAdmin,
        };
      }
    } catch (_) {}
    return {'name': '', 'company': 'SAGANSA', 'isAdmin': false};
  }

  /// Set menu tambahan yang seragam untuk seluruh halaman (Home maupun
  /// dashboard operasional): Profil Saya, dan Kelola Profil (khusus admin).
  static List<Widget> buildStandardExtraItems(BuildContext context,
      {required bool isAdmin}) {
    return [
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text('Profil Saya'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
      ),
      if (isAdmin)
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('Kelola Profil'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminProfileListPage()),
            );
          },
        ),
    ];
  }
}
