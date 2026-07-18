import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_issue_model.dart';
import '../utils/constants.dart';

/// Service untuk list & menutup issue aset.
class AssetIssueService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _authHeaders(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Future<List<AssetIssueModel>> getIssues({
    int? assetId,
    int? status, // 1=open, 2=closed. Default backend = open.
    int? storeId,
    int? severity,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final query = <String, String>{};
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (status != null) query['status'] = status.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (severity != null) query['severity'] = severity.toString();

    final uri =
        Uri.parse(ApiConstants.assetIssues).replace(queryParameters: query);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'] ?? [];
        return data
            .map((e) => AssetIssueModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat daftar issue.');
    }
    throw Exception('Gagal memuat daftar issue: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getIssuesPaged({
    int page = 1,
    int perPage = 20,
    int? assetId,
    int? status,
    int? storeId,
    int? severity,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (status != null) query['status'] = status.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (severity != null) query['severity'] = severity.toString();

    final uri =
        Uri.parse(ApiConstants.assetIssues).replace(queryParameters: query);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'] ?? [];
        final meta = json['pagination'] ?? {};
        final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
        return {
          'data': data
              .map((e) => AssetIssueModel.fromJson(e as Map<String, dynamic>))
              .toList(),
          'has_more': hasMore,
        };
      }
      throw Exception(json['message'] ?? 'Gagal memuat daftar issue.');
    }
    throw Exception('Gagal memuat daftar issue: ${response.statusCode}');
  }

  Future<void> closeIssue(int id, {String? notes}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await http.post(
      Uri.parse('${ApiConstants.assetIssues}/$id/close'),
      headers: {
        ..._authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) return;
    throw Exception(json['message'] ?? 'Gagal menutup issue.');
  }
}
