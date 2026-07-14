import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ClosingStoreService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<List<dynamic>> getClosingStores() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores'),
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
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
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

  Future<List<dynamic>> getFuelServices() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/closing-stores/fuel-services'),
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
}
