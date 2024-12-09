import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presence_today_model.dart';
import '../models/store_model.dart';
import '../models/shift_store_model.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../models/presence_model.dart';
import '../models/presence_status_model.dart';

class PresenceService {
  static const String tokenKey = 'token';
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    print('Token yang diambil: $token');
    return token;
  }

  static Future<List<StoreModel>> getStores() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.stores),
        headers: ApiConstants.headers(await getToken()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['data'] != null) {
          final List<dynamic> storesData = data['data'];
          return storesData.map((store) => StoreModel.fromJson(store)).toList();
        } else {
          throw Exception('Data stores tidak ditemukan');
        }
      } else {
        throw Exception('Gagal memuat data stores: ${response.statusCode}');
      }
    } catch (e) {
      print('Error dalam getStores: $e');
      throw Exception('Gagal memuat data stores: $e');
    }
  }

  static Future<List<ShiftStoreModel>> getShiftStores() async {
    print('Memulai getShiftStores()');
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http
          .get(
            Uri.parse(ApiConstants.shiftStores),
            headers: ApiConstants.headers(token),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          final List<dynamic> shiftStoresData = responseData['data'];
          return shiftStoresData
              .map((json) => ShiftStoreModel.fromJson(json))
              .toList();
        } else {
          throw Exception('Format respons tidak sesuai');
        }
      } else {
        throw Exception('Gagal memuat data shift: ${response.statusCode}');
      }
    } catch (e) {
      print('Error dalam getShiftStores: $e');
      rethrow;
    }
  }

  static Future<void> submitPresence(
      Map<String, dynamic> data, bool isCheckIn, File? imageFile) async {
    try {
      final token = await getToken();
      final url = isCheckIn ? ApiConstants.checkIn : ApiConstants.checkOut;

      print('Submitting presence to: $url');
      print('With data: $data');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(ApiConstants.headers(token));

      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (imageFile != null) {
        final field = isCheckIn ? 'image_in' : 'image_out';
        request.files.add(await http.MultipartFile.fromPath(
          field,
          imageFile.path,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response data: $responseData');

      final decodedData = json.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == 'success') {
          return;
        }
      }

      if (decodedData['errors'] != null) {
        throw Exception(
            decodedData['errors']['image_in']?.first ?? decodedData['message']);
      }

      throw Exception(decodedData['message'] ?? 'Terjadi kesalahan');
    } catch (e) {
      print('Error in submitPresence service: $e');
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getUserPresence() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.userPresence),
        headers: ApiConstants.headers(token),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'today': responseData['data']['today'],
            'previous': responseData['data']['previous'],
          };
        }
        throw Exception(
            responseData['message'] ?? 'Gagal memuat data presensi');
      } else {
        throw Exception('Gagal memuat data presensi: ${response.statusCode}');
      }
    } catch (e) {
      print('Error dalam getUserPresence: $e');
      throw Exception('Gagal memuat data presensi: $e');
    }
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'model': await _getDeviceModel(),
      // ... informasi device lainnya
    };
  }

  static Future<String> _getDeviceModel() async {
    // Implementasikan untuk mendapatkan model device
    return '';
  }

  Future<List<PresenceModel>> getPresences() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/presences'),
        headers: ApiConstants.headers(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        return data.map((json) => PresenceModel.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data presence');
      }
    } catch (e) {
      print('Error in getPresences: $e');
      throw Exception('Gagal mengambil data presence: $e');
    }
  }

  final String? token;

  PresenceService({this.token});

  Future<PresenceTodayModel> getPresenceToday() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/presence/today'),
        headers: ApiConstants.headers(token),
      );

      if (response.statusCode == AppConstants.statusSuccess) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return PresenceTodayModel.fromJson(jsonResponse);
      } else {
        throw Exception('Gagal mengambil status presensi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<PresenceStatusModel> hasCheckedInToday() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/has-checked-in-today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return PresenceStatusModel.fromJson(jsonResponse);
      } else {
        throw Exception('Gagal memeriksa status check-in hari ini');
      }
    } catch (e) {
      print('Error in hasCheckedInToday: $e');
      throw Exception('Gagal memeriksa status check-in hari ini: $e');
    }
  }
}
