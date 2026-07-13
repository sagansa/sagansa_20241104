/// Kategori aset. Menentukan frekuensi pemeriksaan (frequencyDays) dan
/// checklist baku (checklistItems) yang dipakai oleh form pemeriksaan.
class AssetCategoryModel {
  final int id;
  final String name;
  final String? description;
  final int frequencyDays;
  final List<AssetChecklistItem> checklistItems;
  final bool isActive;

  AssetCategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.frequencyDays,
    this.checklistItems = const [],
    this.isActive = true,
  });

  factory AssetCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist_definition'];
    List<AssetChecklistItem> items = [];
    if (rawChecklist is List) {
      items = rawChecklist
          .map((e) => AssetChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return AssetCategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      frequencyDays: json['frequency_days'] is int
          ? json['frequency_days']
          : int.tryParse(json['frequency_days']?.toString() ?? '30') ?? 30,
      checklistItems: items,
      isActive: json['is_active'] ?? true,
    );
  }

  /// Label ramah-tampilan untuk frekuensi, mis. "Bulanan".
  String get frequencyLabel {
    switch (frequencyDays) {
      case 1:
        return 'Harian';
      case 7:
        return 'Mingguan';
      case 30:
        return 'Bulanan';
      case 90:
        return 'Triwulan';
      case 180:
        return 'Semester';
      case 365:
        return 'Tahunan';
      default:
        return 'Setiap $frequencyDays hari';
    }
  }
}

/// Satu item definisi checklist pada kategori.
class AssetChecklistItem {
  final String label;
  final String type;

  AssetChecklistItem({required this.label, this.type = 'check'});

  factory AssetChecklistItem.fromJson(Map<String, dynamic> json) {
    return AssetChecklistItem(
      label: json['label'] ?? '',
      type: json['type'] ?? 'check',
    );
  }
}
