import 'dart:convert';
import 'dart:io';

import 'api_client.dart';
import 'image_upload_service.dart';

/// Service untuk fitur Bensin & Servis (fuel service).
///
/// Sebelumnya method-method ini menempel pada [ClosingStoreService] walau
/// secara semantik merupakan feature terpisah. Dipisah ke file sendiri
/// agar naming konsisten dengan pages/widgets/provider fuel-service.
class FuelServiceService {
  final ApiClient _api = ApiClient();

  /// Buat transaksi bensin/servis baru (dengan upload foto bukti).
  Future<Map<String, dynamic>> createFuelService(
    Map<String, dynamic> data, {
    File? imageFile,
  }) async {
    final fields = <String, String>{};
    data.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          fields[key] = json.encode(value);
        } else {
          fields[key] = value.toString();
        }
      }
    });

    if (imageFile != null) {
      final path = await ImageUploadService.upload(imageFile,
          directory: 'images/FuelService');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['image'] = path;
    }

    final result = await _api.multipart(
      method: 'POST',
      path: 'closing-stores/fuel-services',
      fields: fields,
    );
    return result as Map<String, dynamic>;
  }

  /// Ambil daftar fuel service untuk dropdown pilih item di payment receipt
  /// (transfer type, status 1 = unpaid).
  Future<List<dynamic>> getFuelServicesForPayment({int? createdById}) async {
    final params = <String, String>{};
    if (createdById != null) {
      params['created_by_id'] = createdById.toString();
    }
    final data = await _api.get('closing-stores/fuel-services-for-payment',
        queryParams: params.isNotEmpty ? params : null);
    return data as List<dynamic>? ?? [];
  }

  /// Ambil daftar user yang punya fuel service records (untuk filter admin).
  Future<List<dynamic>> getUsersForFuelServicePayment() async {
    final data = await _api.get('closing-stores/fuel-services/users');
    return data as List<dynamic>? ?? [];
  }

  /// Ambil semua fuel service (tanpa paginasi — per page 1000).
  Future<List<dynamic>> getFuelServices({bool allStores = false}) async {
    final query = <String, String>{'per_page': '1000'};
    if (allStores) query['all_stores'] = '1';
    final data =
        await _api.get('closing-stores/fuel-services', queryParams: query);
    return data as List<dynamic>? ?? [];
  }

  /// Ambil fuel service dengan paginasi + filter.
  ///
  /// Konvensi:
  /// - createdById: null (semua user, admin only) atau id user spesifik
  /// - status: null (semua), '1' (Pending), '2' (Lunas)
  /// - fuelService: null (semua), '1' (Fuel), '2' (Service)
  /// - paymentTypeId: null (semua), '1' (Transfer), '2' (Tunai)
  Future<Map<String, dynamic>> getFuelServicesPaged({
    bool allStores = false,
    int page = 1,
    int perPage = 20,
    int? createdById,
    String? status,
    String? fuelService,
    String? paymentTypeId,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (allStores) query['all_stores'] = '1';
    if (createdById != null) query['created_by_id'] = createdById.toString();
    if (status != null) query['status'] = status;
    if (fuelService != null) query['fuel_service'] = fuelService;
    if (paymentTypeId != null) query['payment_type_id'] = paymentTypeId;

    final response = await _api.getRaw('closing-stores/fuel-services',
        queryParams: query);
    final List data = response['data'] as List<dynamic>? ?? [];
    final meta = response['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {'data': data.cast<Map<String, dynamic>>(), 'has_more': hasMore};
  }
}
