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

  Future<List<ReadinessModel>> getHistory() async {
    final data = await _api.get('$_endpoint/history');
    final list = data as List<dynamic>? ?? [];
    return list.map((item) => ReadinessModel.fromJson(item)).toList();
  }

  /// List kesiapan diri seluruh user (khusus admin/super_admin).
  /// [date] opsional format YYYY-MM-DD (default hari ini di backend).
  Future<List<ReadinessModel>> getAdminList({String? date}) async {
    final queryParams = <String, String>{};
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final data = await _api.get(
      '$_endpoint/admin',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = data as List<dynamic>? ?? [];
    return list.map((item) => ReadinessModel.fromJson(item)).toList();
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
