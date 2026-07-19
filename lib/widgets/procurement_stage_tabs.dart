import 'package:flutter/material.dart';

/// 3-tab stage fixed: Request | Invoice | Payment.
/// Menggantikan 4-perspektif tab di versi lama.
///
/// Index:
///   0 = Request (warna orange #FF9800)
///   1 = Invoice (warna biru #2196F3)
///   2 = Payment (warna ungu #9C27B0)
class ProcurementStageTabs extends StatelessWidget {
  final int activeStage;
  final int requestCount;
  final int invoiceCount;
  final int paymentCount;
  final void Function(int stageIndex)? onTabTap;

  const ProcurementStageTabs({
    super.key,
    required this.activeStage,
    required this.requestCount,
    required this.invoiceCount,
    required this.paymentCount,
    this.onTabTap,
  });

  static const _stageColors = [
    Color(0xFFFF9800), // orange - Request
    Color(0xFF2196F3), // blue   - Invoice
    Color(0xFF9C27B0), // purple - Payment
  ];

  static const _stageLabels = ['Request', 'Invoice', 'Payment'];
  static const _stageEmojis = ['📋', '🧾', '💳'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: List.generate(3, (i) => _buildTab(context, i)),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final isActive = activeStage == index;
    final color = _stageColors[index];
    final count = [requestCount, invoiceCount, paymentCount][index];

    return Expanded(
      child: InkWell(
        onTap: () => onTabTap?.call(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_stageEmojis[index], style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                _stageLabels[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
