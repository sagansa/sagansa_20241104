import '../models/inventory_anomaly_model.dart';
import 'api_client.dart';

class InventoryAnomalyService {
  final ApiClient _api = ApiClient();

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<InventoryAnomalyResponse> getComparison({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<int>? storeIds,
    int page = 1,
    int perPage = 50,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (dateFrom != null) 'date_from': _fmtDate(dateFrom),
      if (dateTo != null) 'date_to': _fmtDate(dateTo),
      if (storeIds != null && storeIds.isNotEmpty)
        'store_ids': storeIds.join(','),
    };

    final body = await _api.getRaw(
      'inventory-anomalies/compare',
      queryParams: qp,
    );

    if (body['success'] == true) {
      return InventoryAnomalyResponse.fromJson(body);
    }
    throw Exception(body['message'] ?? 'Gagal memuat data perbandingan.');
  }
}
