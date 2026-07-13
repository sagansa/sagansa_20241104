import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_category_model.dart';
import '../models/asset_model.dart';
import '../utils/constants.dart';

/// Service HTTP untuk modul Asset (CRUD aset + kategori + dashboard summary).
/// Mengikuti pola StorageStockService: token via SharedPreferences, response
/// envelope {success, data, message}, lempar Exception berbahasa Indonesia.
class AssetService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _authHeaders(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  // ---- Kategori --------------------------------------------------------

  Future<List<AssetCategoryModel>> getCategories() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.assetCategories),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'] ?? [];
        return data
            .map((e) => AssetCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat kategori aset.');
    }
    throw Exception('Gagal memuat kategori aset: ${response.statusCode}');
  }

  // ---- Produk ber-flag aset -------------------------------------------

  /// Daftar produk yang ditandai sebagai aset (untuk product-picker).
  Future<List<Map<String, dynamic>>> getAssetProducts() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.assetProducts),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception(json['message'] ?? 'Gagal memuat daftar produk aset.');
    }
    throw Exception(
        'Gagal memuat daftar produk aset: ${response.statusCode}');
  }

  // ---- Aset ------------------------------------------------------------

  Future<List<AssetModel>> getAssets({
    int? storeId,
    int? categoryId,
    int? status,
    int? condition,
    int? productId,
    String? due, // 'today' | 'overdue' | 'week'
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final query = <String, String>{};
    if (storeId != null) query['store_id'] = storeId.toString();
    if (categoryId != null) query['asset_category_id'] = categoryId.toString();
    if (status != null) query['status'] = status.toString();
    if (condition != null) query['condition'] = condition.toString();
    if (productId != null) query['product_id'] = productId.toString();
    if (due != null) query['due'] = due;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final uri = Uri.parse(ApiConstants.assets).replace(queryParameters: query);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'] ?? [];
        return data
            .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat daftar aset.');
    }
    throw Exception('Gagal memuat daftar aset: ${response.statusCode}');
  }

  Future<AssetModel> getAsset(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.assets}/$id'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return AssetModel.fromJson(json['data']);
      }
      throw Exception(json['message'] ?? 'Data aset tidak ditemukan.');
    }
    if (response.statusCode == 404) {
      throw Exception('Aset tidak ditemukan.');
    }
    throw Exception('Gagal memuat detail aset: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.assetDashboard),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(json['message'] ?? 'Gagal memuat ringkasan dashboard.');
    }
    throw Exception('Gagal memuat ringkasan dashboard: ${response.statusCode}');
  }

  /// Ambil store_id dari presence hari ini untuk user login. Dipakai sebagai
  /// default filter awal di Flutter (khususnya untuk staff yang hanya bisa
  /// check aset di store presence-nya). Null bila belum check-in.
  Future<int?> getCurrentStoreId() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.assetCurrentStore),
        headers: _authHeaders(token),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return json['data']?['store_id'] as int?;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Buat instance aset dari produk (product-driven). Dipakai oleh halaman
  /// create-asset baru. Nama/kode/kategori otomatis dari produk agar konsisten
  /// antar toko.
  Future<void> createFromProduct({
    required int productId,
    required int storeId,
    required int qty,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.post(
      Uri.parse(ApiConstants.assetFromProduct),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'store_id': storeId,
        'qty': qty,
      }),
    );

    final json = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        json['success'] == true) {
      return;
    }
    throw Exception(json['message'] ?? 'Gagal membuat aset dari produk.');
  }

  /// Catat aset manual (multipart karena ada field photo opsional).
  /// Disarankan hanya untuk aset off-catalog — utamakan createFromProduct.
  Future<void> createAsset({
    required String name,
    String? code,
    required int assetCategoryId,
    required int storeId,
    int? productId,
    int? condition,
    int? status,
    String? purchaseDate,
    String? nextCheckAt,
    String? notes,
    File? photo,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.assets),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    request.fields['name'] = name;
    if (code != null && code.isNotEmpty) request.fields['code'] = code;
    request.fields['asset_category_id'] = assetCategoryId.toString();
    request.fields['store_id'] = storeId.toString();
    if (productId != null) request.fields['product_id'] = productId.toString();
    if (condition != null) request.fields['condition'] = condition.toString();
    if (status != null) request.fields['status'] = status.toString();
    if (purchaseDate != null) request.fields['purchase_date'] = purchaseDate;
    if (nextCheckAt != null) request.fields['next_check_at'] = nextCheckAt;
    if (notes != null) request.fields['notes'] = notes;
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final json = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        json['success'] == true) {
      return;
    }
    throw Exception(json['message'] ?? 'Gagal menyimpan aset.');
  }

  Future<void> updateAsset(
    int id, {
    String? name,
    String? code,
    int? assetCategoryId,
    int? storeId,
    int? productId,
    int? condition,
    int? status,
    String? purchaseDate,
    String? nextCheckAt,
    String? notes,
    File? photo,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.assets}/$id'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    if (name != null) request.fields['name'] = name;
    if (code != null) request.fields['code'] = code;
    if (assetCategoryId != null) {
      request.fields['asset_category_id'] = assetCategoryId.toString();
    }
    if (storeId != null) request.fields['store_id'] = storeId.toString();
    if (productId != null) request.fields['product_id'] = productId.toString();
    if (condition != null) request.fields['condition'] = condition.toString();
    if (status != null) request.fields['status'] = status.toString();
    if (purchaseDate != null) request.fields['purchase_date'] = purchaseDate;
    if (nextCheckAt != null) request.fields['next_check_at'] = nextCheckAt;
    if (notes != null) request.fields['notes'] = notes;
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json['success'] == true) {
      return;
    }
    throw Exception(json['message'] ?? 'Gagal memperbarui aset.');
  }

  Future<void> deleteAsset(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.delete(
      Uri.parse('${ApiConstants.assets}/$id'),
      headers: _authHeaders(token),
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) return;
    throw Exception(json['message'] ?? 'Gagal menghapus aset.');
  }
}
