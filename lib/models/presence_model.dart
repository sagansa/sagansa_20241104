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
      store: json['store'] ?? '',
      shiftStore: json['shift_store'] ?? '',
      status: json['status']?.toString() ?? '0',
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'],
      latitudeIn: json['latitude_in'] ?? '',
      longitudeIn: json['longitude_in'] ?? '',
      latitudeOut: json['latitude_out'],
      longitudeOut: json['longitude_out'],
      shiftStartTime: json['shift_start_time'] ?? '',
      shiftEndTime: json['shift_end_time'] ?? '',
      checkInStatus: json['check_in_status'] ?? '',
      checkOutStatus: json['check_out_status'],
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
