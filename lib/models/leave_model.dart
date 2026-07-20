class LeaveModel {
  final int id;
  final int reason;
  final String reasonText;
  final DateTime fromDate;
  final DateTime untilDate;
  final int status;
  final String statusText;
  final String? notes;
  final CreatedBy createdBy;
  final dynamic approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveModel({
    required this.id,
    required this.reason,
    required this.reasonText,
    required this.fromDate,
    required this.untilDate,
    required this.status,
    required this.statusText,
    this.notes,
    required this.createdBy,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'],
      reason: int.tryParse(json['reason']?.toString() ?? '0') ?? 0,
      reasonText: json['reason_text'] ?? '',
      fromDate: DateTime.parse(json['from_date']),
      untilDate: DateTime.parse(json['until_date']),
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      statusText: json['status_text'] ?? '',
      notes: json['notes'],
      createdBy: CreatedBy.fromJson(
        json['created_by'] is Map<String, dynamic>
            ? json['created_by']
            : {'id': 0, 'name': json['created_by']?.toString() ?? 'User'},
      ),
      approvedBy: json['approved_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  int get durationDays {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(untilDate.year, untilDate.month, untilDate.day);
    final diff = end.difference(start).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  String get durationText => '$durationDays Hari';

  String get formattedReason {
    if (reasonText.isNotEmpty) return reasonText;
    switch (reason) {
      case 1:
        return 'Cuti Menikah';
      case 2:
        return 'Sakit';
      case 3:
        return 'Pulang Kampung / Izin';
      case 4:
        return 'Libur / Cuti Tahunan';
      case 5:
        return 'Duka / Keluarga Meninggal';
      default:
        return 'Izin / Cuti';
    }
  }

  String? get approvedByName {
    if (approvedBy == null) return null;
    if (approvedBy is Map) {
      return approvedBy['name']?.toString();
    }
    return approvedBy.toString();
  }
}

typedef Leave = LeaveModel;

class CreatedBy {
  final int id;
  final String name;

  CreatedBy({
    required this.id,
    required this.name,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['id'],
      name: json['name'],
    );
  }
}
