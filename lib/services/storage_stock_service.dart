import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/storage_stock_model.dart';
import '../utils/constants.dart';

class StorageStockService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<List<StorageStockProduct>> getProducts() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/storage-stocks/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'];
        return data.map((item) => StorageStockProduct.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal memuat produk.');
      }
    } else {
      throw Exception('Gagal memuat produk: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getStorageStocks({int page = 1, int perPage = 20}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final uri = Uri.parse('${ApiConstants.baseUrl}/storage-stocks')
        .replace(queryParameters: {'page': page.toString(), 'per_page': perPage.toString()});

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'];
        final reports = data.map((item) => StorageStockModel.fromJson(item)).toList();
        final pagination = jsonResponse['pagination'] as Map<String, dynamic>?;
        return {
          'reports': reports,
          'has_more': (pagination?['current_page'] ?? 1) < (pagination?['last_page'] ?? 1),
        };
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal memuat riwayat stok sisa.');
      }
    } else {
      throw Exception('Gagal memuat riwayat stok sisa: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getStockMonitoring() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/storage-stocks/monitoring'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal memuat monitoring stok.');
      }
    } else {
      throw Exception('Gagal memuat monitoring stok: ${response.statusCode}');
    }
  }

  Future<StorageStockModel> getStorageStock(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/storage-stocks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return StorageStockModel.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Data tidak ditemukan.');
      }
    } else {
      throw Exception('Gagal memuat detail stok sisa: ${response.statusCode}');
    }
  }

  Future<void> createStorageStock(int storeId, List<Map<String, dynamic>> items) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final body = json.encode({
      'store_id': storeId,
      'items': items,
    });

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/storage-stocks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      if (jsonResponse['success'] == true) {
        return;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal menyimpan laporan.');
      }
    } else if (response.statusCode == 422) {
      throw Exception(jsonResponse['message'] ?? 'Terjadi kesalahan validasi.');
    } else {
      throw Exception('Gagal menyimpan laporan stok sisa: ${response.statusCode}');
    }
  }

  Future<Map<String, int>> checkTodayStatus() async {
    final token = await _getToken();
    if (token == null) return {'total_stores': 0, 'reported_stores': 0, 'user_store_reported': 0};

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/storage-stocks/today-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'total_stores': jsonResponse['total_stores'] ?? 0,
          'reported_stores': jsonResponse['reported_stores'] ?? 0,
          'user_store_reported': jsonResponse['user_store_reported'] == true ? 1 : 0,
        };
      }
      return {'total_stores': 0, 'reported_stores': 0, 'user_store_reported': 0};
    } catch (e) {
      return {'total_stores': 0, 'reported_stores': 0, 'user_store_reported': 0};
    }
  }

  Future<int> countReportedStoresToday() async {
    final status = await checkTodayStatus();
    return status['reported_stores'] ?? 0;
  }
}
