/// Item-level procurement approval helpers.
///
/// ## Business Rule (dievaluasi backend saat create request)
library;

///
/// Approval dibutuhkan jika kombinasi payment_type antara detail_request
/// dan product default menyimpang dari pola transfer:
///
/// | Detail Request | Product Default | Hasil                       |
/// |----------------|-----------------|-----------------------------|
/// | Transfer       | Transfer        | ✅ langsung approved         |
/// | Transfer       | Tunai           | ✅ langsung approved         |
/// | Tunai          | Transfer        | ⚠️ butuh admin approval     |
/// | Tunai          | Tunai           | ✅ langsung approved         |
///
/// Rationale: transfer tercatat di bank statement (self-audit), jadi
/// tidak butuh approval tambahan. Tunai sulit diaudit, jadi kalau
/// dipakai untuk product yang seharusnya transfer = cash deviation
/// yang butuh verifikasi admin.
///
/// ## Frontend tidak menghitung rule ini
///
/// Backend mengevaluasi rule di atas saat create request dan menyimpan
/// hasilnya sebagai `detail_request.status`:
///   '1' = Process (pending admin approval)
///   '2' = Done
///   '3' = Rejected
///   '4' = Approved
///
/// Frontend hanya MEMBACA status. Helper di bawah dipakai untuk
/// menghitung statistik (stats strip, count pending) di workflow page.

/// Status backend untuk item yang masih pending admin approval.
const kPendingApprovalStatus = '1';

/// True jika ada minimal satu item dengan status pending ('1').
bool hasPendingApprovalItems(List<String?> itemStatuses) {
  if (itemStatuses.isEmpty) return false;
  return itemStatuses.any((s) => s == kPendingApprovalStatus);
}

/// Hitung jumlah item dengan status pending ('1').
int pendingItemCount(List<String?> itemStatuses) {
  return itemStatuses.where((s) => s == kPendingApprovalStatus).length;
}
