import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/home_dashboard_provider.dart';
import '../home_compact_card.dart';

/// Admin card #4: Invoice Unpaid Transfer.
/// Baca procurement.unpaidTransferInvoicesCount dari provider.
class HomeInvoiceUnpaidCard extends StatelessWidget {
  const HomeInvoiceUnpaidCard({super.key});

  @override
  Widget build(BuildContext context) {
    final procurement = context.select<HomeDashboardProvider, HomeProcurementState>(
        (p) => p.procurement);

    return HomeCompactCard(
      icon: Icons.receipt_outlined,
      iconColor: Theme.of(context).colorScheme.tertiary,
      value: '${procurement.unpaidTransferInvoicesCount}',
      label: 'Invoice Unpaid',
      isLoading: procurement.isLoading,
    );
  }
}
