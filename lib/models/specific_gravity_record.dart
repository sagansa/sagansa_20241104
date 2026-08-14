/// Model riwayat perhitungan Berat Jenis (Specific Gravity) yang disimpan lokal.
library;

import 'dart:math';

/// Entri riwayat hasil perhitungan berat jenis per produksi.
class SpecificGravityRecord {
  final String id;
  final double gramPerLiter;
  final double totalKg;
  final double additionalGram;
  final DateTime timestamp;

  /// Total berat (kg) dengan 4 angka di belakang koma.
  String get totalKgFormatted => totalKg.toStringAsFixed(4);

  /// Berat tambahan (gram) dengan 1 angka di belakang koma.
  String get additionalGramFormatted => additionalGram.toStringAsFixed(1);

  SpecificGravityRecord({
    required this.id,
    required this.gramPerLiter,
    required this.totalKg,
    required this.additionalGram,
    required this.timestamp,
  });

  factory SpecificGravityRecord.create({
    required double gramPerLiter,
    required double totalKg,
    required double additionalGram,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final suffix = Random().nextInt(100000).toString().padLeft(5, '0');
    return SpecificGravityRecord(
      id: '${now.microsecondsSinceEpoch}_$suffix',
      gramPerLiter: gramPerLiter,
      totalKg: totalKg,
      additionalGram: additionalGram,
      timestamp: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gram_per_liter': gramPerLiter,
      'total_kg': totalKg,
      'additional_gram': additionalGram,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory SpecificGravityRecord.fromMap(Map<String, dynamic> map) {
    return SpecificGravityRecord(
      id: map['id'] as String,
      gramPerLiter: (map['gram_per_liter'] as num).toDouble(),
      totalKg: (map['total_kg'] as num).toDouble(),
      additionalGram: (map['additional_gram'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
