import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transfer_stock_model.dart';
import '../utils/constants.dart';

class TransferStockService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<List<TransferStockProduct>> getProducts() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/transfer-stocks/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'];
        return data.map((item) => TransferStockProduct.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal memuat produk.');
      }
    } else {
      throw Exception('Gagal memuat produk: ${response.statusCode}');
    }
  }

  Future<List<TransferStockModel>> getTransferStocks() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/transfer-stocks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'];
        return data.map((item) => TransferStockModel.fromJson(item)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal memuat riwayat transfer.');
      }
    } else {
      throw Exception('Gagal memuat riwayat transfer: ${response.statusCode}');
    }
  }

  Future<TransferStockModel> getTransferStock(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/transfer-stocks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return TransferStockModel.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Data tidak ditemukan.');
      }
    } else {
      throw Exception('Gagal memuat detail transfer: ${response.statusCode}');
    }
  }

  Future<void> createTransferStock({
    required int fromStoreId,
    required int toStoreId,
    required String date,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final body = json.encode({
      'from_store_id': fromStoreId,
      'to_store_id': toStoreId,
      'date': date,
      'items': items,
    });

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/transfer-stocks'),
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
        throw Exception(jsonResponse['message'] ?? 'Gagal menyimpan transfer.');
      }
    } else if (response.statusCode == 422) {
      throw Exception(jsonResponse['message'] ?? 'Terjadi kesalahan validasi.');
    } else {
      throw Exception('Gagal menyimpan transfer: ${response.statusCode}');
    }
  }
}
