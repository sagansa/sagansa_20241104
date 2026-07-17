import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_anomaly_model.dart';
import '../utils/constants.dart';

class InventoryAnomalyService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _headers(String? token) => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<InventoryAnomalyResponse> getComparison({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<int>? storeIds,
    int page = 1,
    int perPage = 50,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Tidak ada token autentikasi.');
    }

    final qp = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (dateFrom != null) 'date_from': _fmtDate(dateFrom),
      if (dateTo != null) 'date_to': _fmtDate(dateTo),
      if (storeIds != null && storeIds.isNotEmpty)
        'store_ids': storeIds.join(','),
    };

    final uri = Uri.parse(ApiConstants.compareInventoryAnomaly)
        .replace(queryParameters: qp);
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return InventoryAnomalyResponse.fromJson(body);
      }
      throw Exception(body['message'] ?? 'Gagal memuat data perbandingan.');
    } else if (response.statusCode == 403) {
      throw Exception('Anda tidak punya akses ke fitur ini.');
    } else if (response.statusCode == 401) {
      throw Exception('Sesi berakhir, silakan login kembali.');
    } else if (response.statusCode == 422) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Parameter tidak valid.');
    } else {
      throw Exception('Gagal memuat data perbandingan (${response.statusCode}).');
    }
  }
}
