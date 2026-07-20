/// Status invoice procurement.
///
/// Mapping (perlu dikonfirmasi dari backend):
/// - `'1'` → [draft]
/// - `'2'` → [done]
/// - `'3'` → [void_]
enum InvoiceStatus {
  draft,
  done,
  void_,
  unknown;

  static InvoiceStatus fromApi(String? code) {
    return switch (code) {
      '1' => InvoiceStatus.draft,
      '2' => InvoiceStatus.done,
      '3' => InvoiceStatus.void_,
      _ => InvoiceStatus.unknown,
    };
  }

  String toApi() {
    return switch (this) {
      InvoiceStatus.draft => '1',
      InvoiceStatus.done => '2',
      InvoiceStatus.void_ => '3',
      InvoiceStatus.unknown => '0',
    };
  }

  String get displayLabel => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.done => 'Done',
        InvoiceStatus.void_ => 'Void',
        InvoiceStatus.unknown => 'Unknown',
      };

  bool get isDraft => this == InvoiceStatus.draft;
  bool get isDone => this == InvoiceStatus.done;
  bool get isVoid => this == InvoiceStatus.void_;
  bool get isUnknown => this == InvoiceStatus.unknown;
}
