import 'dart:io';
import 'package:flutter/material.dart';
import '../models/asset_category_model.dart';
import '../models/asset_check_model.dart';
import '../models/asset_issue_model.dart';
import '../models/asset_model.dart';
import '../services/asset_check_service.dart';
import '../services/asset_issue_service.dart';
import '../services/asset_service.dart';

/// Controller untuk modul Asset. Mengikuti bentuk PresenceController: kelas
/// biasa yang dibangun dengan BuildContext, memanggil service, dan melempar
/// exception berbahasa Indonesia ke caller (UI menangkap & menampilkan SnackBar).
class AssetController {
  AssetController(this.context);

  final BuildContext context;
  final AssetService _assetService = AssetService();
  final AssetCheckService _checkService = AssetCheckService();
  final AssetIssueService _issueService = AssetIssueService();

  Future<List<AssetCategoryModel>> loadCategories() async {
    try {
      return await _assetService.getCategories();
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat kategori aset.');
    }
  }

  /// Daftar produk yang ditandai sebagai aset (untuk product-picker).
  Future<List<Map<String, dynamic>>> loadAssetProducts() async {
    try {
      return await _assetService.getAssetProducts();
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat daftar produk aset.');
    }
  }

  /// Buat aset dari produk. Nama/kode/kategori otomatis dari produk agar
  /// konsisten antar toko.
  Future<void> createFromProduct({
    required int productId,
    required int storeId,
    required int qty,
  }) async {
    try {
      await _assetService.createFromProduct(
        productId: productId,
        storeId: storeId,
        qty: qty,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal membuat aset dari produk.');
    }
  }

  Future<List<AssetModel>> loadAssets({
    int? storeId,
    int? categoryId,
    int? status,
    int? condition,
    int? productId,
    String? due,
    String? search,
  }) async {
    try {
      return await _assetService.getAssets(
        storeId: storeId,
        categoryId: categoryId,
        status: status,
        condition: condition,
        productId: productId,
        due: due,
        search: search,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat daftar aset.');
    }
  }

  Future<Map<String, dynamic>> loadAssetsPaged({
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
    try {
      return await _assetService.getAssetsPaged(
        page: page,
        perPage: perPage,
        storeId: storeId,
        categoryId: categoryId,
        status: status,
        condition: condition,
        productId: productId,
        due: due,
        search: search,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat daftar aset.');
    }
  }

  Future<AssetModel> loadAssetDetail(int id) async {
    try {
      return await _assetService.getAsset(id);
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat detail aset.');
    }
  }

  Future<Map<String, dynamic>> loadDashboardSummary() async {
    try {
      return await _assetService.getDashboardSummary();
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat ringkasan dashboard.');
    }
  }

  /// Store_id dari presence hari ini. Null bila belum check-in. Dipakai
  /// sebagai default filter awal (terutama untuk staff).
  Future<int?> loadCurrentStoreId() async {
    try {
      return await _assetService.getCurrentStoreId();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAsset({
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
    try {
      await _assetService.createAsset(
        name: name,
        code: code,
        assetCategoryId: assetCategoryId,
        storeId: storeId,
        productId: productId,
        condition: condition,
        status: status,
        purchaseDate: purchaseDate,
        nextCheckAt: nextCheckAt,
        notes: notes,
        photo: photo,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal menyimpan aset.');
    }
  }

  Future<List<AssetCheckModel>> loadChecks({
    int? assetId,
    int? storeId,
    String? from,
    String? to,
    int? severity,
  }) async {
    try {
      return await _checkService.getChecks(
        assetId: assetId,
        storeId: storeId,
        from: from,
        to: to,
        severity: severity,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat riwayat pemeriksaan.');
    }
  }

  Future<Map<String, dynamic>> submitCheck({
    required int assetId,
    required String checkDate,
    required int conditionBefore,
    required int conditionAfter,
    required int severity,
    required double latitude,
    required double longitude,
    String? notes,
    List<File> photos = const [],
    List<Map<String, dynamic>> checklist = const [],
  }) async {
    try {
      return await _checkService.submitCheck(
        assetId: assetId,
        checkDate: checkDate,
        conditionBefore: conditionBefore,
        conditionAfter: conditionAfter,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        photos: photos,
        checklist: checklist,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal menyimpan pemeriksaan.');
    }
  }

  Future<bool> hasCheckedToday(int assetId) async {
    try {
      return await _checkService.hasCheckedToday(assetId);
    } catch (_) {
      return false;
    }
  }

  Future<List<AssetIssueModel>> loadIssues({
    int? assetId,
    int? status,
    int? storeId,
    int? severity,
  }) async {
    try {
      return await _issueService.getIssues(
        assetId: assetId,
        status: status,
        storeId: storeId,
        severity: severity,
      );
    } catch (e) {
      _rethrow(e, fallback: 'Gagal memuat daftar issue.');
    }
  }

  Future<void> closeIssue(int id, {String? notes}) async {
    try {
      await _issueService.closeIssue(id, notes: notes);
    } catch (e) {
      _rethrow(e, fallback: 'Gagal menutup issue.');
    }
  }

  /// Hapus aset (admin saja). Backend akan menolak bila bukan admin.
  Future<void> deleteAsset(int id) async {
    try {
      await _assetService.deleteAsset(id);
    } catch (e) {
      _rethrow(e, fallback: 'Gagal menghapus aset.');
    }
  }

  /// Selalu melempar exception (return type Never agar analyzer tahu path
  /// catch tidak "jatuh" tanpa return value).
  Never _rethrow(Object e, {required String fallback}) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    throw Exception(msg.isEmpty ? fallback : msg);
  }
}
