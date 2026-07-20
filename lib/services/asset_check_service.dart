import 'dart:convert';
import 'dart:io';
import '../models/asset_check_model.dart';
import 'api_client.dart';
import 'image_upload_service.dart';

/// Service untuk submit & melihat riwayat pemeriksaan aset.
class AssetCheckService {
  final ApiClient _api = ApiClient();

  static const _endpoint = 'asset-checks';

  Future<List<AssetCheckModel>> getChecks({
    int? assetId,
    int? storeId,
    String? from,
    String? to,
    int? severity,
  }) async {
    final query = <String, String>{};
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;
    if (severity != null) query['severity'] = severity.toString();

    final json = await _api.getRaw(_endpoint, queryParams: query);
    final List data = json['data'] ?? [];
    return data
        .map((e) => AssetCheckModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getChecksPaged({
    int page = 1,
    int perPage = 20,
    int? assetId,
    int? storeId,
    String? from,
    String? to,
    int? severity,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString()
    };
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;
    if (severity != null) query['severity'] = severity.toString();

    final json = await _api.getRaw(_endpoint, queryParams: query);
    final List data = json['data'] ?? [];
    final meta = json['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {
      'data': data
          .map((e) => AssetCheckModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'has_more': hasMore,
    };
  }

  Future<AssetCheckModel> getCheck(int id) async {
    final data = await _api.get('$_endpoint/$id');
    return AssetCheckModel.fromJson(data as Map<String, dynamic>);
  }

  /// Submit pemeriksaan aset. Mengirim multipart: field + checklist (JSON
  /// string) + banyak file foto + lat/lng.
  Future<Map<String, dynamic>> submitCheck({
    required int assetId,
    required String checkDate,
    required int conditionBefore,
    required int conditionAfter,
    required int severity,
    required double latitude,
    required double longitude,
    String? notes,
    List<File> photos = const [],
    List<Map<String, dynamic>> checklist = const [],
  }) async {
    final fields = <String, String>{
      'asset_id': assetId.toString(),
      'check_date': checkDate,
      'condition_before': conditionBefore.toString(),
      'condition_after': conditionAfter.toString(),
      'severity': severity.toString(),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (notes != null && notes.isNotEmpty) fields['notes'] = notes;
    if (checklist.isNotEmpty) {
      fields['checklist'] = jsonEncode(checklist);
    }
    for (int i = 0; i < photos.length; i++) {
      final path =
          await ImageUploadService.upload(photos[i], directory: 'images/AssetCheck');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['photos[$i]'] = path;
    }

    final data = await _api.multipart(
      method: 'POST',
      path: _endpoint,
      fields: fields,
    );
    return data as Map<String, dynamic>;
  }

  /// Cek apakah aset sudah diperiksa hari ini.
  Future<bool> hasCheckedToday(int assetId) async {
    try {
      final data = await _api.get('$_endpoint/today-status/$assetId');
      if (data is Map<String, dynamic>) {
        return data['has_checked'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
