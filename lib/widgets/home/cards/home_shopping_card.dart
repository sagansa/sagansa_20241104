import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../home_dashboard_card.dart';

/// Staff "Belanja" dashboard card.
/// Baca procurement.unpaidInvoicesCount/invoiceDraftCount/invoiceDoneCount dari provider.
class HomeShoppingCard extends StatelessWidget {
  const HomeShoppingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final procurement = context.select<HomeDashboardProvider,
        HomeProcurementState>((p) => p.procurement);
    final colorScheme = Theme.of(context).colorScheme;

    return HomeDashboardCard(
      icon: Icons.shopping_cart_outlined,
      iconColor: colorScheme.tertiary,
      title: 'Belanja',
      value: procurement.isLoading
          ? 'Loading...'
          : (procurement.unpaidInvoicesCount > 0
              ? '${procurement.unpaidInvoicesCount} Blm Lunas'
              : 'Invoice Lunas'),
      subtitle:
          'Draft: ${procurement.invoiceDraftCount} | Done: ${procurement.invoiceDoneCount}',
    );
  }
}
