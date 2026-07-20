import 'dart:io';
import '../models/asset_category_model.dart';
import '../models/asset_model.dart';
import 'api_client.dart';
import 'image_upload_service.dart';

/// Service HTTP untuk modul Asset (CRUD aset + kategori + dashboard summary).
/// Menggunakan ApiClient singleton untuk otorisasi & parsing response envelope.
class AssetService {
  final ApiClient _api = ApiClient();

  // ---- Kategori --------------------------------------------------------

  Future<List<AssetCategoryModel>> getCategories() async {
    final data = await _api.get('asset-categories') as List;
    return data
        .map((e) => AssetCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Produk ber-flag aset -------------------------------------------

  /// Daftar produk yang ditandai sebagai aset (untuk product-picker).
  Future<List<Map<String, dynamic>>> getAssetProducts() async {
    final data = await _api.get('asset-products') as List;
    return data.cast<Map<String, dynamic>>();
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
    final query = <String, String>{'per_page': '1000'};
    if (storeId != null) query['store_id'] = storeId.toString();
    if (categoryId != null) query['asset_category_id'] = categoryId.toString();
    if (status != null) query['status'] = status.toString();
    if (condition != null) query['condition'] = condition.toString();
    if (productId != null) query['product_id'] = productId.toString();
    if (due != null) query['due'] = due;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final data = await _api.get('assets', queryParams: query) as List;
    return data
        .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getAssetsPaged({
    int page = 1,
    int perPage = 20,
    int? storeId,
    int? categoryId,
    int? status,
    int? condition,
    int? productId,
    String? due,
    String? search,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (storeId != null) query['store_id'] = storeId.toString();
    if (categoryId != null) query['asset_category_id'] = categoryId.toString();
    if (status != null) query['status'] = status.toString();
    if (condition != null) query['condition'] = condition.toString();
    if (productId != null) query['product_id'] = productId.toString();
    if (due != null) query['due'] = due;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final json = await _api.getRaw('assets', queryParams: query);
    final List data = json['data'] ?? [];
    final meta = json['pagination'] ?? {};
    final hasMore =
        (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {
      'data': data
          .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'has_more': hasMore,
    };
  }

  Future<AssetModel> getAsset(int id) async {
    final data = await _api.get('assets/$id');
    return AssetModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final data = await _api.get('assets/dashboard');
    return data as Map<String, dynamic>;
  }

  /// Ambil store_id dari presence hari ini untuk user login. Dipakai sebagai
  /// default filter awal di Flutter (khususnya untuk staff yang hanya bisa
  /// check aset di store presence-nya). Null bila belum check-in.
  Future<int?> getCurrentStoreId() async {
    try {
      final data = await _api.get('assets/current-store');
      return (data as Map<String, dynamic>?)?['store_id'] as int?;
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
    await _api.post('assets/from-product', body: {
      'product_id': productId,
      'store_id': storeId,
      'qty': qty,
    });
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
    final fields = <String, String>{
      'name': name,
      'asset_category_id': assetCategoryId.toString(),
      'store_id': storeId.toString(),
    };
    if (code != null && code.isNotEmpty) fields['code'] = code;
    if (productId != null) fields['product_id'] = productId.toString();
    if (condition != null) fields['condition'] = condition.toString();
    if (status != null) fields['status'] = status.toString();
    if (purchaseDate != null) fields['purchase_date'] = purchaseDate;
    if (nextCheckAt != null) fields['next_check_at'] = nextCheckAt;
    if (notes != null) fields['notes'] = notes;
    if (photo != null) {
      final path = await ImageUploadService.upload(photo, directory: 'images/Asset');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['photo'] = path;
    }

    await _api.multipart(method: 'POST', path: 'assets', fields: fields);
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
    final fields = <String, String>{};
    if (name != null) fields['name'] = name;
    if (code != null) fields['code'] = code;
    if (assetCategoryId != null) {
      fields['asset_category_id'] = assetCategoryId.toString();
    }
    if (storeId != null) fields['store_id'] = storeId.toString();
    if (productId != null) fields['product_id'] = productId.toString();
    if (condition != null) fields['condition'] = condition.toString();
    if (status != null) fields['status'] = status.toString();
    if (purchaseDate != null) fields['purchase_date'] = purchaseDate;
    if (nextCheckAt != null) fields['next_check_at'] = nextCheckAt;
    if (notes != null) fields['notes'] = notes;
    if (photo != null) {
      final path = await ImageUploadService.upload(photo, directory: 'images/Asset');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['photo'] = path;
    }

    await _api.multipart(method: 'POST', path: 'assets/$id', fields: fields);
  }

  Future<void> deleteAsset(int id) async {
    await _api.delete('assets/$id');
  }
}
