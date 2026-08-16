// ====================================================================
// Model notifikasi dari Notification Center (endpoint /notifications).
// ====================================================================

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'].toString()),
      createdAt: DateTime.tryParse(json['created_at'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isRead => readAt != null;

  /// id record terkait (invoice_id / receipt_id / sales_order_id) bila ada di data.
  int? get recordId {
    if (data == null) return null;
    final raw = switch (type) {
      'invoice_transfer_created' => data!['invoice_id'],
      'sales_order_online_created' => data!['sales_order_id'],
      _ => data!['receipt_id'],
    };
    return raw == null ? null : int.tryParse(raw.toString());
  }
}
