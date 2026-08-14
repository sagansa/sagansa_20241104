import 'package:flutter/material.dart';

import '../../../pages/specific_gravity_calculator_page.dart';
import '../../../theme/app_colors.dart';
import '../home_dashboard_card.dart';

/// Kartu entry Kalkulator Berat Jenis untuk storage-staff.
class HomeSpecificGravityCard extends StatelessWidget {
  const HomeSpecificGravityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDashboardCard(
      icon: Icons.scale_outlined,
      iconColor: AppColors.primary,
      title: 'Kalkulator Berat Jenis',
      value: '19 L',
      subtitle: 'Hitung & simpan produksi',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SpecificGravityCalculatorPage(),
          ),
        );
      },
    );
  }
}
