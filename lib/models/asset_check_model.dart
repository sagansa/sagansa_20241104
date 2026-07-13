import '../services/image_service.dart';

/// Header hasil satu sesi pemeriksaan aset.
class AssetCheckModel {
  final int id;
  final int assetId;
  final int? checkedByUserId;
  final String? checkedByName;
  final String checkDate;
  final int conditionBefore;
  final int conditionAfter;
  final int severity; // 1=ok, 2=ringan, 3=sedang, 4=berat
  final int status; // 1=submitted, 2=approved
  final String? notes;
  final List<String> photos;
  List<String> get photoUrls => photos.map((p) => ImageService.buildUrl(p)).whereType<String>().toList();
  final double? latitude;
  final double? longitude;
  final List<AssetCheckItemModel> items;

  AssetCheckModel({
    required this.id,
    required this.assetId,
    this.checkedByUserId,
    this.checkedByName,
    required this.checkDate,
    required this.conditionBefore,
    required this.conditionAfter,
    required this.severity,
    required this.status,
    this.notes,
    this.photos = const [],
    this.latitude,
    this.longitude,
    this.items = const [],
  });

  factory AssetCheckModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    List<String> photoList = [];
    if (rawPhotos is List) {
      photoList = rawPhotos.map((e) => e.toString()).toList();
    }
    final rawItems = json['items'];
    List<AssetCheckItemModel> itemList = [];
    if (rawItems is List) {
      itemList = rawItems
          .map((e) => AssetCheckItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return AssetCheckModel(
      id: json['id'],
      assetId: json['asset_id'] ?? 0,
      checkedByUserId: json['checked_by_id'],
      checkedByName: json['checked_by']?['name'],
      checkDate: json['check_date'] ?? '',
      conditionBefore: json['condition_before'] ?? 1,
      conditionAfter: json['condition_after'] ?? 1,
      severity: json['severity'] ?? 1,
      status: json['status'] ?? 1,
      notes: json['notes'],
      photos: photoList,
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
      items: itemList,
    );
  }

  String get severityText {
    switch (severity) {
      case 1:
        return 'OK';
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
}

/// Snapshot item checklist per sesi check.
class AssetCheckItemModel {
  final int id;
  final String label;
  final int value; // 0=not_ok, 1=ok
  final String? note;

  AssetCheckItemModel({
    required this.id,
    required this.label,
    required this.value,
    this.note,
  });

  factory AssetCheckItemModel.fromJson(Map<String, dynamic> json) {
    return AssetCheckItemModel(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      value: json['value'] ?? 1,
      note: json['note'],
    );
  }

  bool get isOk => value == 1;
}
