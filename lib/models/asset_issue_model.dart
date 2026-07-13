/// Issue/temuan pemeriksaan aset (modul sederhana: status open/closed).
class AssetIssueModel {
  final int id;
  final int assetId;
  final int? assetCheckId;
  final int severity; // 2=ringan, 3=sedang, 4=berat
  final String? description;
  final int status; // 1=open, 2=closed
  final int? reportedByUserId;
  final String? reportedByName;
  final int? resolvedByUserId;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? notes;
  final DateTime? createdAt;
  final String? assetName;
  final String? assetCode;

  AssetIssueModel({
    required this.id,
    required this.assetId,
    this.assetCheckId,
    required this.severity,
    this.description,
    required this.status,
    this.reportedByUserId,
    this.reportedByName,
    this.resolvedByUserId,
    this.resolvedByName,
    this.resolvedAt,
    this.notes,
    this.createdAt,
    this.assetName,
    this.assetCode,
  });

  factory AssetIssueModel.fromJson(Map<String, dynamic> json) {
    return AssetIssueModel(
      id: json['id'],
      assetId: json['asset_id'] ?? 0,
      assetCheckId: json['asset_check_id'],
      severity: json['severity'] ?? 2,
      description: json['description'],
      status: json['status'] ?? 1,
      reportedByUserId: json['reported_by_id'],
      reportedByName: json['reported_by']?['name'],
      resolvedByUserId: json['resolved_by_id'],
      resolvedByName: json['resolved_by']?['name'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      assetName: json['asset']?['name'],
      assetCode: json['asset']?['code'],
    );
  }

  bool get isOpen => status == 1;
  bool get isClosed => status == 2;

  String get severityText {
    switch (severity) {
      case 2:
        return 'Ringan';
      case 3:
        return 'Sedang';
      case 4:
        return 'Berat';
      default:
        return 'Tidak Diketahui';
    }
  }

  String get statusText => isClosed ? 'Closed' : 'Open';
}
