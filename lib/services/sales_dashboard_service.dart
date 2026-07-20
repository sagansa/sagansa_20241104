import '../models/sales_dashboard_model.dart';
import 'api_client.dart';

class SalesDashboardService {
  final ApiClient _api = ApiClient();

  static const _endpoint = 'sales-dashboard';

  Map<String, String> _qp(SalesView view, SalesPeriode periode,
      {int? page, int? perPage, ProductSort? sort, int? compareYear, String? metric}) {
    return {
      'periode': periode.apiValue,
      'view': view.name,
      if (page != null) 'page': '$page',
      if (perPage != null) 'per_page': '$perPage',
      if (sort != null) 'sort': sort.name,
      if (compareYear != null) 'compare_year': '$compareYear',
      if (metric != null) 'metric': metric,
    };
  }

  Future<SalesSummary> getSummary(SalesPeriode periode) async {
    final data = await _api.get(_endpoint,
        queryParams: _qp(SalesView.summary, periode));
    return SalesSummary.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<List<SalesTrendPoint>> getTrend(SalesPeriode periode,
      {int? compareYear, String metric = 'omzet'}) async {
    final data = await _api.get(_endpoint,
        queryParams: _qp(SalesView.trend, periode,
            compareYear: compareYear, metric: metric));
    final map = (data as Map<String, dynamic>?) ?? {};
    return (map['points'] as List<dynamic>?)
            ?.map((e) => SalesTrendPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<({List<SalesProductItem> items, SalesProductMeta meta})> getProducts(
    SalesPeriode periode, {
    int page = 1,
    int perPage = 50,
    ProductSort sort = ProductSort.qty,
  }) async {
    final data = await _api.get(_endpoint,
        queryParams: _qp(SalesView.products, periode,
            page: page, perPage: perPage, sort: sort));
    final map = (data as Map<String, dynamic>?) ?? {};
    final items = ((map['items'] as List<dynamic>?) ?? const [])
        .map((e) => SalesProductItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = SalesProductMeta.fromJson(
        (map['meta'] as Map<String, dynamic>?) ?? const {});
    return (items: items, meta: meta);
  }

  Future<({List<SalesChannelItem> items, int totalOmzet})> getChannels(
      SalesPeriode periode) async {
    final data = await _api.get(_endpoint,
        queryParams: _qp(SalesView.channels, periode));
    final map = (data as Map<String, dynamic>?) ?? {};
    final items = ((map['items'] as List<dynamic>?) ?? const [])
        .map((e) => SalesChannelItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (map['total_omzet'] as num? ?? 0).toInt();
    return (items: items, totalOmzet: total);
  }
}
