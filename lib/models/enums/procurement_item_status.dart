/// Status item permintaan procurement (RequestPurchaseItem.status).
///
/// Mapping ke kode string yang dikirim backend:
/// - `'1'` → [pending]
/// - `'2'` → [done]
/// - `'3'` → [rejected]
/// - `'4'` → [partiallyApproved]
enum ProcurementItemStatus {
  pending,
  done,
  rejected,
  partiallyApproved,
  unknown;

  /// Decode dari kode string backend. Null / tidak dikenal → [unknown].
  static ProcurementItemStatus fromApi(String? code) {
    return switch (code) {
      '1' => ProcurementItemStatus.pending,
      '2' => ProcurementItemStatus.done,
      '3' => ProcurementItemStatus.rejected,
      '4' => ProcurementItemStatus.partiallyApproved,
      _ => ProcurementItemStatus.unknown,
    };
  }

  /// Encode ke kode string untuk request body. [unknown] → `'0'`.
  String toApi() {
    return switch (this) {
      ProcurementItemStatus.pending => '1',
      ProcurementItemStatus.done => '2',
      ProcurementItemStatus.rejected => '3',
      ProcurementItemStatus.partiallyApproved => '4',
      ProcurementItemStatus.unknown => '0',
    };
  }

  /// Label Indonesia untuk display.
  String get displayLabel {
    return switch (this) {
      ProcurementItemStatus.pending => 'Pending Approval',
      ProcurementItemStatus.done => 'Done',
      ProcurementItemStatus.rejected => 'Rejected',
      ProcurementItemStatus.partiallyApproved => 'Partially Approved',
      ProcurementItemStatus.unknown => 'Unknown',
    };
  }

  /// Predikat siap pakai — mengganti `status == '1'` dst.
  bool get isPending => this == ProcurementItemStatus.pending;
  bool get isDone => this == ProcurementItemStatus.done;
  bool get isRejected => this == ProcurementItemStatus.rejected;
  bool get isPartiallyApproved => this == ProcurementItemStatus.partiallyApproved;
  bool get isApproved => isDone || isPartiallyApproved;
  bool get isUnknown => this == ProcurementItemStatus.unknown;
}
