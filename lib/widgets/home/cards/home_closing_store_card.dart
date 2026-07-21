import 'package:flutter/material.dart';
import '../../../pages/closing_store_page.dart';
import '../../../theme/app_colors.dart';
import '../home_dashboard_card.dart';

/// Staff "Closing Store" dashboard card.
/// Static card (no provider state) — tap navigates to ClosingStorePage.
class HomeClosingStoreCard extends StatelessWidget {
  const HomeClosingStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDashboardCard(
      icon: Icons.store_outlined,
      iconColor: AppColors.warning,
      title: 'Closing Store',
      value: 'Buka',
      subtitle: 'Laporan penutupan toko',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClosingStorePage()),
        );
      },
    );
  }
}
