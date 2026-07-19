/// Cash-deviation approval rule helpers.
///
/// Konvensi payment_type_id:
///   1 = Transfer (ada jejak bank statement)
///   2 = Tunai (perlu kontrol tambahan)
///
/// Lihat spec section 2: "Cash Control Mechanism".
library;

/// Rule 3: invoice tunai + product transfer → butuh admin approval.
/// Semua kombinasi lain → auto-approved.
bool needsCashDeviationApproval({
  required int? invoicePaymentTypeId,
  required int? productPaymentTypeId,
}) {
  if (invoicePaymentTypeId == null || productPaymentTypeId == null) return false;
  // Rule 3: tunai + transfer = cash deviation
  return invoicePaymentTypeId == 2 && productPaymentTypeId == 1;
}

/// Status string yang dianggap "pending admin approval".
const kPendingApprovalStatus = 'pending_approval';

/// True jika list status item invoice mengandung minimal 1 pending.
bool hasPendingApprovalItems({
  required int? invoicePaymentTypeId,
  required List<String?> itemStatuses,
}) {
  if (itemStatuses.isEmpty) return false;
  return itemStatuses.any((s) => s == kPendingApprovalStatus);
}

/// Hitung jumlah item dengan status pending.
int pendingItemCount(List<String?> itemStatuses) {
  return itemStatuses.where((s) => s == kPendingApprovalStatus).length;
}
