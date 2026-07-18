import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../models/store_model.dart';
import '../models/shift_store_model.dart';
import 'dart:io';
import '../utils/constants.dart';
import 'image_upload_service.dart';
import 'dart:developer' as developer;

class PresenceService {
  static const String tokenKey = 'token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    debugPrint('Token yang diambil: $token');
    return token;
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Store>> getStores() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.stores),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['data'] != null) {
          final List<dynamic> storesData = data['data'];
          return storesData.map((store) => Store.fromJson(store)).toList();
        } else {
          throw Exception('Data stores tidak ditemukan');
        }
      } else {
        throw Exception('Gagal memuat data stores: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error dalam getStores: $e');
      throw Exception('Gagal memuat data stores: $e');
    }
  }

  static Future<List<ShiftStore>> getShiftStores() async {
    debugPrint('Memulai getShiftStores()');
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

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if ((responseData['success'] == true ||
                responseData['status'] == 'success') &&
            responseData['data'] is List) {
          final List<dynamic> shiftStoresData = responseData['data'];
          return shiftStoresData
              .map((json) => ShiftStore.fromJson(json))
              .toList();
        } else {
          throw Exception('Format respons tidak sesuai');
        }
      } else {
        throw Exception('Gagal memuat data shift: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error dalam getShiftStores: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadImage(
    File imageFile,
    bool isCheckIn,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final endpoint = isCheckIn ? '/check-in' : '/check-out';
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      var request = http.MultipartRequest('POST', uri)
        ..headers.addAll(ApiConstants.headers(token))
        ..fields
            .addAll(data.map((key, value) => MapEntry(key, value.toString())));

      final fieldName = isCheckIn ? 'image_in' : 'image_out';
      String? path;
      if (kIsWeb) {
        final bytes = await XFile(imageFile.path).readAsBytes();
        // Pertahankan ekstensi file aktual (mis. .webp di Android, .jpg di iOS)
        // agar content-type dan validasi backend tetap konsisten.
        final ext = p.extension(imageFile.path).toLowerCase();
        final filename = isCheckIn ? 'image_in$ext' : 'image_out$ext';
        path = await ImageUploadService.uploadBytes(
          bytes,
          filename,
          directory: 'images/Presence',
        );
      } else {
        path = await ImageUploadService.upload(
          imageFile,
          directory: 'images/Presence',
        );
      }
      if (path == null) throw Exception('Gagal upload gambar presensi.');
      request.fields[fieldName] = path;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return json.decode(response.body); // Langsung return decoded response
    } catch (e) {
      developer.log('Error uploading presence image: $e', name: 'PresenceService');
      throw Exception('Gagal mengirim data presensi');
    }
  }

  static Future<void> submitPresence(
    Map<String, dynamic> data,
    bool isCheckIn,
  ) async {
    try {
      final token = await getToken();
      final endpoint = isCheckIn ? '/check-in' : '/check-out';
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http.post(
        uri,
        headers: ApiConstants.headers(token),
        body: data,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        throw Exception('Gagal melakukan presensi: ${responseData['message']}');
      }
    } catch (e) {
      throw Exception('Error saat submit presensi: $e');
    }
  }

  /// Get all employees' presence data for today (admin only).
  /// Returns record (presences, summary) where summary contains
  /// late_count, on_time_count, total_count from backend.
  static Future<({List<dynamic> presences, Map<String, dynamic>? summary})>
      getAllTodayPresences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      final response = await http.get(
        Uri.parse(ApiConstants.todayPresenceEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success' || body['success'] == true) {
          return (
            presences: body['data'] as List<dynamic>? ?? [],
            summary: body['summary'] as Map<String, dynamic>?,
          );
        }
        throw Exception(body['message'] ?? 'Gagal memuat presensi.');
      } else {
        throw Exception('Gagal memuat presensi: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getAllTodayPresences',
          error: e, name: 'PresenceService');
      return (presences: [], summary: null);
    }
  }

  static Future<Map<String, dynamic>> getUserPresence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      final response = await http.get(
        Uri.parse(ApiConstants.userPresence),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      developer.log('User Presence API Raw Response: ${response.body}',
          name: 'PresenceService');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load presence data (status: ${response.statusCode}, body: ${response.body})');
      }
    } catch (e) {
      developer.log('Error in getUserPresence',
          error: e, name: 'PresenceService');
      throw Exception('Failed to load presence data: $e');
    }
  }

  /// Returns true when the current user has an active clock-in for today.
  static Future<bool> isClockedIn() async {
    try {
      final data = await getUserPresence();
      final presenceData = data['data'] as Map<String, dynamic>?;
      return presenceData?['today'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getSalesOrders({
    int page = 1,
    int perPage = 10,
    int? deliveryStatus,
    bool? hasPaymentProof,
    bool? paymentProofPrinted,
    String? orderFor,
  }) async {
    try {
      final token = await getToken();
      final queryParameters = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (deliveryStatus != null)
          'delivery_status': deliveryStatus.toString(),
        if (hasPaymentProof != null)
          'has_payment_proof': hasPaymentProof ? '1' : '0',
        if (paymentProofPrinted != null)
          'payment_proof_printed': paymentProofPrinted ? '1' : '0',
        if (orderFor != null)
          'for': orderFor,
      };
      final uri = Uri.parse(ApiConstants.searchSalesOrder)
          .replace(queryParameters: queryParameters);
      final response = await http.get(
        uri,
        headers: ApiConstants.headers(token),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal memuat daftar order.');
      }
    } catch (e) {
      throw Exception('Error saat memuat daftar order: $e');
    }
  }

  static Future<Map<String, dynamic>> markPaymentProofsPrinted({
    required List<int> orderIds,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiConstants.markPaymentProofsPrinted),
        headers: ApiConstants.headers(token),
        body: json.encode({'order_ids': orderIds}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ??
            'Gagal memperbarui status print bukti pembayaran.');
      }
    } catch (e) {
      throw Exception('Error saat memperbarui status print: $e');
    }
  }

  static Future<Map<String, dynamic>> searchSalesOrder(String receiptNo, {String? orderFor}) async {
    try {
      final token = await getToken();
      final forQuery = orderFor != null ? '&for=$orderFor' : '';
      final uri =
          Uri.parse('${ApiConstants.searchSalesOrder}?receipt_no=$receiptNo$forQuery');
      final response = await http.get(
        uri,
        headers: ApiConstants.headers(token),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Gagal mencari data resi.');
      }
    } catch (e) {
      throw Exception('Error saat mencari resi: $e');
    }
  }

  static Future<Map<String, dynamic>> markReadyToShip({
    required int orderId,
    String? orderFor,
  }) async {
    try {
      final token = await getToken();
      final body = <String, dynamic>{'id': orderId};
      if (orderFor != null) body['for'] = orderFor;
      final response = await http.post(
        Uri.parse(ApiConstants.readyToShip),
        headers: ApiConstants.headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ??
            'Gagal mengubah status menjadi siap dikirim.');
      }
    } catch (e) {
      throw Exception('Error saat mengubah status pengiriman: $e');
    }
  }

  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required String receiptNo,
    File? imageFile,
    String? receivedBy,
    int? deliveryStatus,
    String? notes,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(ApiConstants.updateDeliveryStatus);

    try {
      var request = http.MultipartRequest('POST', uri)
        ..headers.addAll(ApiConstants.headers(token))
        ..fields.addAll({
          'receipt_no': receiptNo,
          if (receivedBy != null && receivedBy.isNotEmpty)
            'received_by': receivedBy,
          if (deliveryStatus != null)
            'delivery_status': deliveryStatus.toString(),
          if (notes != null && notes.isNotEmpty)
            'notes': notes,
        });

      if (imageFile != null) {
        final path = await ImageUploadService.upload(
          imageFile,
          directory: 'images/Delivery',
        );
        if (path == null) throw Exception('Gagal upload bukti pengiriman.');
        request.fields['image_delivery'] = path;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);

      if (response.statusCode == 200) {
        return decodedData;
      } else {
        throw Exception(
            decodedData['message'] ?? 'Gagal memperbarui status pengiriman.');
      }
    } catch (e) {
      throw Exception('Error saat memperbarui pengiriman: $e');
    }
  }

  /// Update payment status for a direct sales order (admin only).
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required int orderId,
    required String paymentStatus,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(ApiConstants.updatePaymentStatus);

    try {
      final response = await http.post(
        uri,
        headers: ApiConstants.headers(token),
        body: json.encode({
          'order_id': orderId,
          'payment_status': paymentStatus,
        }),
      );

      final decodedData = json.decode(response.body);

      if (response.statusCode == 200) {
        return decodedData;
      } else {
        throw Exception(
            decodedData['message'] ?? 'Gagal memperbarui status pembayaran.');
      }
    } catch (e) {
      throw Exception('Error saat memperbarui status pembayaran: $e');
    }
  }

  /// Update order items for a direct sales order (admin only).
  static Future<Map<String, dynamic>> updateOrderItems({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(ApiConstants.updateOrderItems);

    try {
      final response = await http.post(
        uri,
        headers: ApiConstants.headers(token),
        body: json.encode({
          'order_id': orderId,
          'items': items,
        }),
      );

      final decodedData = json.decode(response.body);

      if (response.statusCode == 200) {
        return decodedData;
      } else {
        throw Exception(
            decodedData['message'] ?? 'Gagal memperbarui item order.');
      }
    } catch (e) {
      throw Exception('Error saat memperbarui item order: $e');
    }
  }

  /// Check if there are pending utility reports for a store.
  static Future<bool> checkPendingUtilityReports(int storeId) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/utility-reports/pending?store_id=$storeId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['has_pending'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }


}
