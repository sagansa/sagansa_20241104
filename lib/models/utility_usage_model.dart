class UtilityUsageModel {
  final int id;
  final int utilityId;
  final String result;
  final int status;
  final String? notes;
  final String? image;
  final int? createdById;
  final String? createdByName;
  final int? approvedById;
  final String? approvedByName;
  final String? createdAt;

  // nested utility object
  final int? utilityIdFromRel;
  final String? utilityNumber;
  final String? utilityName;
  final String? storeNickname;
  final String? providerName;
  final String? unitName;
  final int? storeId;

  UtilityUsageModel({
    required this.id,
    required this.utilityId,
    required this.result,
    required this.status,
    this.notes,
    this.image,
    this.createdById,
    this.createdByName,
    this.approvedById,
    this.approvedByName,
    this.createdAt,
    this.utilityIdFromRel,
    this.utilityNumber,
    this.utilityName,
    this.storeNickname,
    this.providerName,
    this.unitName,
    this.storeId,
  });

  String get utilityDisplayName {
    if (utilityName != null && utilityName!.isNotEmpty) {
      return utilityName!;
    }
    if (storeNickname != null && providerName != null) {
      return '$storeNickname | $providerName';
    }
    if (utilityNumber != null) {
      return utilityNumber!;
    }
    return 'Utility #$utilityId';
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Belum Diperiksa';
      case 2:
        return 'Valid';
      case 3:
        return 'Diperbaiki';
      case 4:
        return 'Periksa Ulang';
      default:
        return 'Unknown';
    }
  }

  String get formattedResult {
    try {
      final num = int.tryParse(result.replaceAll('.', '')) ?? 0;
      return num.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    } catch (_) {
      return result;
    }
  }

  String get cleanNotes {
    if (notes == null) return '';
    return notes!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  factory UtilityUsageModel.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) => v?.toString();

    final utility = json['utility'] as Map<String, dynamic>?;
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    final approvedBy = json['approved_by'] as Map<String, dynamic>?;
    final store = utility?['store'] as Map<String, dynamic>?;
    final provider = utility?['utility_provider'] as Map<String, dynamic>?;
    final unit = utility?['unit'] as Map<String, dynamic>?;

    return UtilityUsageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      utilityId: json['utility_id'] is int
          ? json['utility_id']
          : int.parse(json['utility_id'].toString()),
      result: s(json['result']) ?? '0',
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '1') ?? 1,
      notes: s(json['notes']),
      image: s(json['image']),
      createdById: json['created_by_id'] == null
          ? null
          : (json['created_by_id'] is int
              ? json['created_by_id']
              : int.tryParse(json['created_by_id'].toString())),
      createdByName: s(createdBy?['name']),
      approvedById: json['approved_by_id'] == null
          ? null
          : (json['approved_by_id'] is int
              ? json['approved_by_id']
              : int.tryParse(json['approved_by_id'].toString())),
      approvedByName: s(approvedBy?['name']),
      createdAt: s(json['created_at']),
      utilityIdFromRel: utility?['id'],
      utilityNumber: s(utility?['number']),
      utilityName: s(utility?['utility_name']),
      storeNickname: s(store?['nickname']),
      providerName: s(provider?['name']),
      unitName: s(unit?['unit']),
      storeId: utility?['store_id'] is int
          ? utility!['store_id'] as int
          : int.tryParse(utility?['store_id']?.toString() ?? '') ?? 0,
    );
  }
}