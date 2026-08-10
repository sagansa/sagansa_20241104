import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../pages/admin_profile_list_page.dart';
import '../../pages/printer_settings_page.dart';
import '../../pages/profile_page.dart';
import '../../theme/app_spacing.dart';
import '../app_version_text.dart';

/// Drawer aplikasi di Home.
///
/// Mengikuti sebagian besar behavior lama: menampilkan header dengan logo,
/// nama user, nama perusahaan; menu navigasi; dan tombol logout dengan
/// dialog konfirmasi.
class HomeDrawer extends StatelessWidget {
  final String userName;
  final String companyName;
  final bool isAdmin;

  /// Dipanggil saat user mengkonfirmasi logout.
  final Future<void> Function() onLogout;

  const HomeDrawer({
    super.key,
    required this.userName,
    required this.companyName,
    required this.isAdmin,
    required this.onLogout,
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
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil Saya'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Printer Thermal'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrinterSettingsPage()),
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
                      builder: (context) => const AdminProfileListPage()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Bantuan'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implementasi halaman bantuan
            },
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
                await onLogout();
              }
            },
          ),
          const AppVersionText(),
        ],
      ),
    );
  }
}
