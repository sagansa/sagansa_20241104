import 'dart:io';

import '../models/readiness_model.dart';
import 'api_client.dart';
import 'image_upload_service.dart';

class ReadinessService {
  final ApiClient _api = ApiClient();

  static const _endpoint = 'readiness';

  Future<Map<String, dynamic>> checkStatus() async {
    final data = await _api.get('$_endpoint/status');
    return data as Map<String, dynamic>;
  }

  /// Riwayat kesiapan diri milik sendiri (terpaginasi).
  Future<Map<String, dynamic>> getHistory({int page = 1, int perPage = 15}) async {
    final json = await _api.getRaw('$_endpoint/history', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    return _parsePaged(json);
  }

  /// Daftar kesiapan diri seluruh karyawan (admin/super_admin, terpaginasi).
  /// [date] opsional format YYYY-MM-DD.
  Future<Map<String, dynamic>> getAdminList({
    int page = 1,
    int perPage = 15,
    String? date,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (date != null && date.isNotEmpty) qp['date'] = date;
    final json = await _api.getRaw('$_endpoint/admin', queryParams: qp);
    return _parsePaged(json);
  }

  Map<String, dynamic> _parsePaged(dynamic json) {
    final map = json as Map<String, dynamic>;
    final ok = map['success'] == true || map['status'] == 'success';
    if (!ok) {
      throw Exception(map['message'] ?? 'Gagal memuat kesiapan diri.');
    }
    final list = (map['data'] as List? ?? [])
        .map((e) => ReadinessModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = (map['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final currentPage = (meta['current_page'] ?? 1) as num;
    final lastPage = (meta['last_page'] ?? 1) as num;
    return {
      'data': list,
      'has_more': currentPage < lastPage,
    };
  }

  /// Ubah status kesiapan diri (admin/super_admin).
  /// Status: 1 = belum diperiksa, 2 = sudah diperiksa.
  Future<ReadinessModel> updateStatus(int id, int status) async {
    final data = await _api.patch('$_endpoint/$id/status', body: {
      'status': status,
    });
    return ReadinessModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> submitReadiness({
    required String selfiePath,
    required String leftHandPath,
    required String rightHandPath,
  }) async {
    final uploadedSelfie =
        await ImageUploadService.upload(File(selfiePath), directory: 'images/Readiness');
    if (uploadedSelfie == null) throw Exception('Gagal upload selfie.');
    final uploadedLeft =
        await ImageUploadService.upload(File(leftHandPath), directory: 'images/Readiness');
    if (uploadedLeft == null) throw Exception('Gagal upload left hand.');
    final uploadedRight =
        await ImageUploadService.upload(File(rightHandPath), directory: 'images/Readiness');
    if (uploadedRight == null) throw Exception('Gagal upload right hand.');

    final fields = <String, String>{
      'image_selfie': uploadedSelfie,
      'left_hand': uploadedLeft,
      'right_hand': uploadedRight,
    };

    final data = await _api.multipart(
      method: 'POST',
      path: _endpoint,
      fields: fields,
    );
    return data as Map<String, dynamic>;
  }
}
