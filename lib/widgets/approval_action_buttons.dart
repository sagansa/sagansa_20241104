import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standardized SnackBar-inspired Approval & Rejection action buttons.
/// Sleek pill-shaped capsule design with status-tinted backgrounds,
/// vibrant icons, and high-contrast labels.
class ApprovalActionButtons extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String approveText;
  final String rejectText;
  final bool isLoading;
  final double height;

  const ApprovalActionButtons({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.approveText = 'Setujui',
    this.rejectText = 'Tolak',
    this.isLoading = false,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Row(
      children: [
        // Reject Button (Solid Red SnackBar Style)
        Expanded(
          child: SizedBox(
            height: height,
            child: FilledButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
              label: Text(
                rejectText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Approve Button (Solid Green SnackBar Style)
        Expanded(
          child: SizedBox(
            height: height,
            child: FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              label: Text(
                approveText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
