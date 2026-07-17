import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_dashboard_model.dart';
import '../utils/constants.dart';

class SalesDashboardService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _headers(String? token) => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _buildUri(SalesView view, SalesPeriode periode,
      {int? page, int? perPage, ProductSort? sort}) {
    final qp = <String, String>{
      'periode': periode.apiValue,
      'view': view.name,
      if (page != null) 'page': '$page',
      if (perPage != null) 'per_page': '$perPage',
      if (sort != null) 'sort': sort.name,
    };
    return Uri.parse(ApiConstants.salesDashboard).replace(queryParameters: qp);
  }

  Future<SalesSummary> getSummary(SalesPeriode periode) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final res = await http.get(
        _buildUri(SalesView.summary, periode), headers: _headers(token));
    final body = _parse(res);
    return SalesSummary.fromJson((body['data'] as Map<String, dynamic>?) ?? {});
  }

  Future<List<SalesTrendPoint>> getTrend(SalesPeriode periode) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final res =
        await http.get(_buildUri(SalesView.trend, periode), headers: _headers(token));
    final body = _parse(res);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final points = (data['points'] as List<dynamic>?)
            ?.map((e) => SalesTrendPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return points;
  }

  Future<({List<SalesProductItem> items, SalesProductMeta meta})> getProducts(
    SalesPeriode periode, {
    int page = 1,
    int perPage = 50,
    ProductSort sort = ProductSort.qty,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final res = await http.get(
        _buildUri(SalesView.products, periode,
            page: page, perPage: perPage, sort: sort),
        headers: _headers(token));
    final body = _parse(res);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final items = ((data['items'] as List<dynamic>?) ?? const [])
        .map((e) => SalesProductItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = SalesProductMeta.fromJson(
        (data['meta'] as Map<String, dynamic>?) ?? const {});
    return (items: items, meta: meta);
  }

  Future<({List<SalesChannelItem> items, int totalOmzet})> getChannels(
      SalesPeriode periode) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final res = await http.get(_buildUri(SalesView.channels, periode),
        headers: _headers(token));
    final body = _parse(res);
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    final items = ((data['items'] as List<dynamic>?) ?? const [])
        .map((e) => SalesChannelItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total_omzet'] as num? ?? 0).toInt();
    return (items: items, totalOmzet: total);
  }

  Map<String, dynamic> _parse(http.Response res) {
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) return body;
      throw Exception(body['message'] ?? 'Gagal memuat data dashboard.');
    } else if (res.statusCode == 403) {
      throw Exception('Anda tidak punya akses ke fitur ini.');
    } else if (res.statusCode == 401) {
      throw Exception('Sesi berakhir, silakan login kembali.');
    } else if (res.statusCode == 422) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Parameter tidak valid.');
    } else {
      throw Exception('Gagal memuat data dashboard (${res.statusCode}).');
    }
  }
}
