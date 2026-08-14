import '../services/image_service.dart';

class UtilityBillModel {
  final int id;
  final int utilityId;
  final String date;
  final String amount;
  final String initialIndicator;
  final String lastIndicator;
  final String? image;

  // nested utility object
  final int? utilityIdFromRel;
  final String? utilityNumber;
  final String? utilityName;
  final String? storeNickname;
  final String? providerName;
  final String? unitName;
  final int? storeId;

  UtilityBillModel({
    required this.id,
    required this.utilityId,
    required this.date,
    required this.amount,
    required this.initialIndicator,
    required this.lastIndicator,
    this.image,
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

  String get formattedAmount {
    try {
      final num = int.tryParse(amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 'Rp ${num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
    } catch (_) {
      return 'Rp $amount';
    }
  }

  String get formattedInitialIndicator {
    try {
      final num = double.tryParse(initialIndicator.replaceAll(',', '.')) ?? 0;
      if (num == num.roundToDouble()) {
        return num.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
      }
      return num.toStringAsFixed(2).replaceAll('.', ',');
    } catch (_) {
      return initialIndicator;
    }
  }

  String get formattedLastIndicator {
    try {
      final num = double.tryParse(lastIndicator.replaceAll(',', '.')) ?? 0;
      if (num == num.roundToDouble()) {
        return num.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
      }
      return num.toStringAsFixed(2).replaceAll('.', ',');
    } catch (_) {
      return lastIndicator;
    }
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date;
    }
  }

  String? get imageUrl => ImageService.buildUrl(image);

  factory UtilityBillModel.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) => v?.toString();

    final utility = json['utility'] as Map<String, dynamic>?;
    final store = utility?['store'] as Map<String, dynamic>?;
    final provider = utility?['utility_provider'] as Map<String, dynamic>?;
    final unit = utility?['unit'] as Map<String, dynamic>?;

    return UtilityBillModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      utilityId: json['utility_id'] is int
          ? json['utility_id']
          : int.parse(json['utility_id'].toString()),
      date: s(json['date']) ?? '',
      amount: s(json['amount']) ?? '0',
      initialIndicator: s(json['initial_indicator']) ?? '0',
      lastIndicator: s(json['last_indicator']) ?? '0',
      image: s(json['image']),
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
