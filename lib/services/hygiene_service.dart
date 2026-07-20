import 'dart:io';

import '../models/hygiene_model.dart';
import 'api_client.dart';
import 'image_upload_service.dart';

class HygieneService {
  final ApiClient _api = ApiClient();

  Future<List<RoomModel>> getRooms() async {
    final data = await _api.get('hygiene/rooms') as List<dynamic>? ?? [];
    return data.map((e) => RoomModel.fromJson(e)).toList();
  }

  Future<bool> checkTodayStatus({int? storeId}) async {
    final queryParams =
        storeId != null ? {'store_id': storeId.toString()} : null;
    final data =
        await _api.get('hygiene/today-status', queryParams: queryParams);
    return data?['has_submitted_today'] ?? false;
  }

  Future<HygieneModel> submitHygiene({
    required int storeId,
    required List<Map<String, dynamic>> rooms,
  }) async {
    final fields = <String, String>{
      'store_id': storeId.toString(),
    };

    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      fields['rooms[$i][room_id]'] = room['room_id'].toString();

      if (room['condition'] != null) {
        fields['rooms[$i][condition]'] = room['condition'].toString();
      }
      if (room['notes'] != null) {
        fields['rooms[$i][notes]'] = room['notes'] as String;
      }
      if (room['image_path'] != null) {
        final path = await ImageUploadService.upload(
          File(room['image_path'] as String),
          directory: 'images/Hygiene',
        );
        if (path == null) throw Exception('Gagal upload gambar ke img service.');
        fields['rooms[$i][image]'] = path;
      }
    }

    final data = await _api.multipart(
      method: 'POST',
      path: 'hygiene',
      fields: fields,
    );
    return HygieneModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getHistory({int page = 1, int perPage = 15}) async {
    final json = await _api.getRaw('hygiene', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });

    final data = json['data'] as List<dynamic>? ?? [];
    final items = data.map((e) => HygieneModel.fromJson(e)).toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return {
      'data': items,
      'meta': meta,
    };
  }

  Future<HygieneModel> getDetail(int id) async {
    final data = await _api.get('hygiene/$id');
    return HygieneModel.fromJson(data);
  }

  Future<HygieneModel> updateStatus(int id, int status) async {
    final data = await _api.put('hygiene/$id', body: {'status': status});
    return HygieneModel.fromJson(data);
  }

  Future<HygieneRoomModel> updateRoomStatus(int roomId, int condition) async {
    final data = await _api.put(
      'hygiene/of-rooms/$roomId',
      body: {'condition': condition},
    );
    return HygieneRoomModel.fromJson(data);
  }
}
