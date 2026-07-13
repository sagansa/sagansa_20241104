import '../services/image_service.dart';

/// Instance aset terlacak. Bisa tercipta manual via UI atau otomatis dari
/// invoice pembelian produk ber-flag is_asset (lihat field sourceDetailInvoiceId).
class AssetModel {
  final int id;
  final String code;
  final String name;
  final int? productId;
  final String? productName;
  final int assetCategoryId;
  final String? assetCategoryName;
  final int? frequencyDays;
  final int storeId;
  final String? storeName;
  final int condition; // 1=baik, 2=rusak_ringan, 3=rusak_berat, 4=hilang
  final int status; // 1=aktif, 2=dipelihara, 3=non_aktif
  final String? photo;
  String? get photoUrl => ImageService.buildUrl(photo);
  final String? purchaseDate;
  final DateTime? nextCheckAt;
  final DateTime? lastCheckAt;
  final int? sourceDetailInvoiceId;
  final int? createdByUserId;
  final String? createdByName;
  final String? notes;
  final int openIssuesCount;

  AssetModel({
    required this.id,
    required this.code,
    required this.name,
    this.productId,
    this.productName,
    required this.assetCategoryId,
    this.assetCategoryName,
    this.frequencyDays,
    required this.storeId,
    this.storeName,
    required this.condition,
    required this.status,
    this.photo,
    this.purchaseDate,
    this.nextCheckAt,
    this.lastCheckAt,
    this.sourceDetailInvoiceId,
    this.createdByUserId,
    this.createdByName,
    this.notes,
    this.openIssuesCount = 0,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      productId: json['product_id'],
      productName: json['product']?['name'],
      assetCategoryId: json['asset_category_id'] ?? 0,
      assetCategoryName: json['category']?['name'],
      frequencyDays: json['category']?['frequency_days'] is int
          ? json['category']['frequency_days']
          : null,
      storeId: json['store_id'] ?? 0,
      storeName: json['store']?['nickname'] ?? json['store']?['name'],
      condition: json['condition'] ?? 1,
      status: json['status'] ?? 1,
      photo: json['photo'],
      purchaseDate: json['purchase_date'],
      nextCheckAt: json['next_check_at'] != null
          ? DateTime.tryParse(json['next_check_at'].toString())
          : null,
      lastCheckAt: json['last_check_at'] != null
          ? DateTime.tryParse(json['last_check_at'].toString())
          : null,
      sourceDetailInvoiceId: json['source_detail_invoice_id'],
      createdByUserId: json['created_by_id'],
      createdByName: json['created_by']?['name'],
      notes: json['notes'],
      openIssuesCount: json['open_issues_count'] ?? 0,
    );
  }

  String get conditionText {
    switch (condition) {
      case 1:
        return 'Baik';
      case 2:
        return 'Rusak Ringan';
      case 3:
        return 'Rusak Berat';
      case 4:
        return 'Hilang';
      default:
        return 'Tidak Diketahui';
    }
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Aktif';
      case 2:
        return 'Dipelihara';
      case 3:
        return 'Non-Aktif';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Status "jatuh tempo": overdue (lewat), dueToday (hari ini), upcoming (mingu depan).
  String get dueStatus {
    if (nextCheckAt == null) return 'none';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextCheckAt!.year, nextCheckAt!.month, nextCheckAt!.day);
    if (due.isBefore(today)) return 'overdue';
    if (due.isAtSameMomentAs(today)) return 'today';
    if (due.isBefore(today.add(const Duration(days: 7)))) return 'upcoming';
    return 'later';
  }
}
