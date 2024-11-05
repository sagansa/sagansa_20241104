import 'package:flutter/material.dart';

class PresenceModel {
  final String store;
  final String shiftStore;
  final String status;
  final String checkIn;
  final String? checkOut;
  final double latitudeIn;
  final double longitudeIn;
  final double? latitudeOut;
  final double? longitudeOut;
  final String shiftStartTime;
  final String shiftEndTime;
  final String checkInStatus;
  final String? checkOutStatus;

  PresenceModel({
    required this.store,
    required this.shiftStore,
    required this.status,
    required this.checkIn,
    this.checkOut,
    required this.latitudeIn,
    required this.longitudeIn,
    this.latitudeOut,
    this.longitudeOut,
    required this.shiftStartTime,
    required this.shiftEndTime,
    required this.checkInStatus,
    this.checkOutStatus,
  });

  factory PresenceModel.fromJson(Map<String, dynamic> json) {
    return PresenceModel(
      store: json['store']?.toString() ?? '',
      shiftStore: json['shift_store']?.toString() ?? '',
      status: json['status']?.toString() ?? '0',
      checkIn: json['check_in']?.toString() ?? '',
      checkOut: json['check_out']?.toString(),
      latitudeIn: (json['latitude_in'] != null)
          ? double.tryParse(json['latitude_in'].toString()) ?? 0.0
          : 0.0,
      longitudeIn: (json['longitude_in'] != null)
          ? double.tryParse(json['longitude_in'].toString()) ?? 0.0
          : 0.0,
      latitudeOut: json['latitude_out'] != null
          ? double.tryParse(json['latitude_out'].toString())
          : null,
      longitudeOut: json['longitude_out'] != null
          ? double.tryParse(json['longitude_out'].toString())
          : null,
      shiftStartTime: json['shift_start_time']?.toString() ?? '',
      shiftEndTime: json['shift_end_time']?.toString() ?? '',
      checkInStatus: json['check_in_status']?.toString() ?? '',
      checkOutStatus: json['check_out_status']?.toString(),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'tepat_waktu':
        return Colors.green;
      case 'terlambat':
        return Colors.red;
      case 'pulang_cepat':
        return Colors.orange;
      case 'tidak_absen':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case 'tepat_waktu':
        return 'sesuai';
      case 'terlambat':
        return 'Terlambat';
      case 'pulang_cepat':
        return 'Pulang Cepat';
      case 'tidak_absen':
        return 'Tidak Absen';
      default:
        return '-';
    }
  }
}
