import '../models/store_consumption_model.dart';
import 'api_client.dart';

class StoreConsumptionService {
  final ApiClient _api = ApiClient();

  Future<List<StoreConsumptionProduct>> getProducts() async {
    final data = await _api.get('store-consumptions/products');
    final List list = data as List;
    return list
        .map((item) => StoreConsumptionProduct.fromJson(item))
        .toList();
  }

  Future<Map<String, dynamic>> getStoreConsumptions({
    int page = 1,
    int perPage = 20,
    int? storeId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (storeId != null) queryParams['store_id'] = storeId.toString();

    final response = await _api.getRaw(
      'store-consumptions',
      queryParams: queryParams,
    );
    final List data = response['data'] ?? [];
    final reports =
        data.map((item) => StoreConsumptionModel.fromJson(item)).toList();
    final pagination = response['pagination'] as Map<String, dynamic>?;
    return {
      'reports': reports,
      'has_more':
          (pagination?['current_page'] ?? 1) < (pagination?['last_page'] ?? 1),
    };
  }

  Future<StoreConsumptionModel> getStoreConsumption(int id) async {
    final data = await _api
        .get('store-consumptions/$id') as Map<String, dynamic>;
    return StoreConsumptionModel.fromJson(data);
  }

  Future<void> createStoreConsumption(
      int storeId, String date, List<Map<String, dynamic>> items) async {
    await _api.post('store-consumptions', body: {
      'store_id': storeId,
      'date': date,
      'items': items,
    });
  }

  Future<void> updateStoreConsumption(
      int id, int storeId, String date, List<Map<String, dynamic>> items) async {
    await _api.put('store-consumptions/$id', body: {
      'store_id': storeId,
      'date': date,
      'items': items,
    });
  }

  Future<void> updateStatus(int id, int status) async {
    await _api.patch('store-consumptions/$id/status', body: {
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getStores() async {
    final data = await _api.get('stores');
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}