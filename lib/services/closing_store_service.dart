import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'image_upload_service.dart';

class ClosingStoreService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<List<dynamic>> getClosingStores() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores')
          .replace(queryParameters: {'per_page': '1000'}),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'] as List<dynamic>? ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat daftar closing store.');
    }
  }

  Future<Map<String, dynamic>> getClosingStoresPaged({int page = 1, int perPage = 20}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final uri = Uri.parse('${ApiConstants.baseUrl}/closing-stores')
        .replace(queryParameters: {'page': page.toString(), 'per_page': perPage.toString()});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      final List data = jsonResponse['data'] as List<dynamic>? ?? [];
      final meta = jsonResponse['pagination'] ?? {};
      final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
      return {'data': data.cast<Map<String, dynamic>>(), 'has_more': hasMore};
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal memuat daftar closing store.');
  }

  Future<Map<String, dynamic>> getClosingStore(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat detail closing store.');
    }
  }

  Future<Map<String, dynamic>> getActiveDraft() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/active-draft'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat draf closing store.');
    }
  }

  Future<Map<String, dynamic>> getUnpaidTransactions() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/unpaid-transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat transaksi kasir.');
    }
  }

  Future<void> saveClosingStore(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/save'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode != 200 || jsonResponse['success'] != true) {
      throw Exception(jsonResponse['message'] ?? 'Gagal menyimpan closing store.');
    }
  }

  Future<Map<String, dynamic>> createFuelService(Map<String, dynamic> data, {File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final uri = Uri.parse('${ApiConstants.baseUrl}/closing-stores/fuel-services');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Populate fields
    data.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          request.fields[key] = json.encode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    // Add image if provided
    if (imageFile != null) {
      final path = await ImageUploadService.upload(imageFile, directory: 'images/FuelService');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      request.fields['image'] = path;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal membuat transaksi fuel service.');
    }
  }

  Future<List<dynamic>> getVehicles() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat daftar kendaraan.');
    }
  }

  Future<List<dynamic>> getSuppliers() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/suppliers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat daftar supplier.');
    }
  }

  /// Get all daily salaries (with pagination)
  Future<Map<String, dynamic>> getDailySalaries({
    int page = 1,
    int perPage = 20,
    int? userId,
    String? status,
    int? paymentTypeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (userId != null) params['user_id'] = userId.toString();
    if (status != null) params['status'] = status;
    if (paymentTypeId != null) params['payment_type_id'] = paymentTypeId.toString();
    if (dateFrom != null) params['date_from'] = dateFrom.toIso8601String().substring(0, 10);
    if (dateTo != null) params['date_to'] = dateTo.toIso8601String().substring(0, 10);

    final uri = Uri.parse(ApiConstants.dailySalaries)
        .replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return {
        'data': jsonResponse['data'] as List<dynamic>? ?? [],
        'meta': jsonResponse['meta'] ?? {},
      };
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data daily salary.');
    }
  }

  /// Bulk update status for daily salaries (admin only)
  Future<int> bulkUpdateDailySalaryStatus(List<int> ids, int status) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.post(
      Uri.parse('${ApiConstants.dailySalaries}/bulk-update-status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'ids': ids,
        'status': status,
      }),
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data']['updated_count'] ?? 0;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal update status daily salary.');
    }
  }

  /// Get daily salaries for payment receipt (transfer type, status 3 = siap dibayar)
  Future<List<dynamic>> getDailySalariesForPayment({int? userId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId.toString();

    final uri = Uri.parse(ApiConstants.dailySalaries)
        .replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'] as List<dynamic>? ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data daily salary.');
    }
  }

  /// Get employees for daily salary payment selection
  Future<List<dynamic>> getEmployeesForDailySalary() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.dailySalaries}/employees'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'] as List<dynamic>? ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data karyawan.');
    }
  }

  /// Get fuel services for payment receipt (transfer type, status 1 = unpaid)
  Future<List<dynamic>> getFuelServicesForPayment({int? createdById}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final params = <String, String>{};
    if (createdById != null) params['created_by_id'] = createdById.toString();

    final uri = Uri.parse('${ApiConstants.baseUrl}/closing-stores/fuel-services-for-payment')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'] as List<dynamic>? ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data bensin/servis.');
    }
  }

  /// Get users who have fuel service records for payment
  Future<List<dynamic>> getUsersForFuelServicePayment() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/fuel-services/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'] as List<dynamic>? ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data pengguna.');
    }
  }

  /// Create a payment receipt
  Future<Map<String, dynamic>> createPaymentReceipt(Map<String, dynamic> data, {File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final uri = Uri.parse(ApiConstants.paymentReceipts);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Add form fields
    data.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            request.fields['${key}[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    // Add image if provided
    if (imageFile != null) {
      final path = await ImageUploadService.upload(imageFile, directory: 'images/PaymentReceipt');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      request.fields['image'] = path;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final jsonResponse = json.decode(response.body);

    if (response.statusCode == 201 && jsonResponse['success'] == true) {
      return jsonResponse['data'] ?? {};
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal membuat payment receipt.');
    }
  }

  /// Get payment receipts list
  Future<List<dynamic>> getPaymentReceipts({int page = 1, int perPage = 10}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.paymentReceipts}?page=$page&per_page=$perPage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'] as List<dynamic>? ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data payment receipt.');
    }
  }

  Future<List<dynamic>> getFuelServices({bool allStores = false}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final query = <String, String>{'per_page': '1000'};
    if (allStores) query['all_stores'] = '1';
    final uri = Uri.parse('${ApiConstants.baseUrl}/closing-stores/fuel-services')
        .replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat daftar bensin/servis.');
    }
  }

  Future<Map<String, dynamic>> getFuelServicesPaged({bool allStores = false, int page = 1, int perPage = 20}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');
    final query = <String, String>{'page': page.toString(), 'per_page': perPage.toString()};
    if (allStores) query['all_stores'] = '1';
    final uri = Uri.parse('${ApiConstants.baseUrl}/closing-stores/fuel-services').replace(queryParameters: query);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      final List data = jsonResponse['data'] as List<dynamic>? ?? [];
      final meta = jsonResponse['pagination'] ?? {};
      final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
      return {'data': data.cast<Map<String, dynamic>>(), 'has_more': hasMore};
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal memuat daftar bensin/servis.');
  }
}
