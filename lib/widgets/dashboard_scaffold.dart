import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_drawer.dart';
import 'modern_bottom_nav.dart';
import 'theme_toggle_button.dart';

/// Scaffold dashboard reusable: AppBar (logo + nama user + toggle tema),
/// Drawer seragam (Beranda/Printer/Bantuan/Logout), body berisi header
/// + daftar [DashboardMenuItem], dan [ModernBottomNav].
///
/// Tujuan: menghilangkan duplikasi ~600 baris AppBar/Drawer/_buildMenuRow
/// yang sebelumnya di-copy ke tiap dashboard. Dark mode adaptif otomatis
/// karena seluruh warna memakai `colorScheme`.
///
/// Ikon menu selalu memakai `colorScheme.primary` (seragam antar dashboard).
class DashboardScaffold extends StatelessWidget {
  final int currentIndex;
  final String title;
  final String? subtitle;
  final List<DashboardMenuItem> menuItems;
  final Widget? bottomAction;

  const DashboardScaffold({
    super.key,
    required this.currentIndex,
    required this.title,
    this.subtitle,
    required this.menuItems,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AppDrawer.loadUserData(),
      builder: (context, snapshot) {
        final userName = snapshot.data?['name'] ?? '';
        final companyName = snapshot.data?['company'] ?? 'SAGANSA';
        final isAdmin = snapshot.data?['isAdmin'] ?? false;
        return _buildScaffold(context, userName, companyName, isAdmin);
      },
    );
  }

  Widget _buildScaffold(
      BuildContext context, String userName, String companyName, bool isAdmin) {
    return Scaffold(
      appBar: _buildAppBar(context, userName, companyName),
      drawer: AppDrawer(
        userName: userName,
        companyName: companyName,
        showAppVersion: true,
        extraItems: AppDrawer.buildStandardExtraItems(
          context,
          isAdmin: isAdmin,
        ),
      ),
      body: _buildBody(context),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {},
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, String userName, String companyName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      leading: Builder(
        builder: (context) => InkWell(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              width: 36,
              fit: BoxFit.contain,
              height: 36,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(userName, style: theme.textTheme.titleSmall),
          Text(
            companyName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: const [
        ThemeToggleButton(),
        SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleItems = menuItems.where((m) => m.visible).toList();
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            AppSpacing.gapVerticalXS,
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          AppSpacing.gapVerticalLG,
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: visibleItems
                .map((item) => _DashboardMenuCard(item: item))
                .toList(),
          ),
          if (bottomAction != null) ...[
            AppSpacing.gapVerticalLG,
            bottomAction!,
          ],
        ],
      ),
    );
  }
}

///
/// Catatan: tidak ada parameter `color` — ikon selalu memakai
/// `colorScheme.primary` agar seragam antar dashboard (sesuai keputusan
/// desain). Warna khusus cukup diberikan via [trailing] jika diperlukan.
class DashboardMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool visible;

  const DashboardMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.visible = true,
  });
}

class _DashboardMenuCard extends StatelessWidget {
  final DashboardMenuItem item;
  const _DashboardMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppSpacing.borderRadiusLG,
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Icon(item.icon, color: color, size: 28),
              ),
              AppSpacing.gapHorizontalMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.trailing != null) item.trailing!,
              if (item.trailing == null)
                Icon(Icons.chevron_right, color: AppColors.info),
            ],
          ),
        ),
      ),
    );
  }
}
