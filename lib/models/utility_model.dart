class UtilityModel {
  final int id;
  final String? number;
  final String? name;
  final int? storeId;
  final String? storeNickname;
  final int? status;
  final String? unit;
  final int? utilityProviderId;
  final String? utilityProviderName;
  final int? prePost;
  final int? category;

  UtilityModel({
    required this.id,
    this.number,
    this.name,
    this.storeId,
    this.storeNickname,
    this.status,
    this.unit,
    this.utilityProviderId,
    this.utilityProviderName,
    this.prePost,
    this.category,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (storeNickname != null && utilityProviderName != null) {
      return '$storeNickname | $utilityProviderName';
    }
    if (number != null) return number!;
    return 'Utility #$id';
  }

  String get categoryLabel {
    switch (category) {
      case 1:
        return 'Listrik';
      case 2:
        return 'Air';
      case 3:
        return 'Internet';
      default:
        return 'Lainnya';
    }
  }

  String get prePostLabel {
    switch (prePost) {
      case 1:
        return 'Prabayar';
      case 2:
        return 'Pascabayar';
      default:
        return '-';
    }
  }

  String get statusText => status == 1 ? 'Aktif' : 'Nonaktif';

  UtilityModel copyWith({int? status}) => UtilityModel(
        id: id,
        number: number,
        name: name,
        storeId: storeId,
        storeNickname: storeNickname,
        status: status ?? this.status,
        unit: unit,
        utilityProviderId: utilityProviderId,
        utilityProviderName: utilityProviderName,
        prePost: prePost,
        category: category,
      );

  factory UtilityModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.parse(json['id'].toString());
    int? toInt(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return UtilityModel(
      id: id,
      number: json['number']?.toString(),
      name: json['name']?.toString(),
      storeId: toInt(json['store_id']),
      storeNickname: json['store_nickname']?.toString(),
      status: toInt(json['status']),
      unit: json['unit']?.toString(),
      utilityProviderId: toInt(json['utility_provider_id']),
      utilityProviderName: json['utility_provider_name']?.toString(),
      prePost: toInt(json['pre_post']),
      category: toInt(json['category']),
    );
  }
}
