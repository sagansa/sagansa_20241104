import '../models/utility_bill_model.dart';
import 'api_client.dart';

class UtilityBillService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getUtilityBillsPaged({
    int page = 1,
    int perPage = 20,
    int? storeId,
    int? utilityId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (storeId != null) queryParams['store_id'] = storeId.toString();
    if (utilityId != null) queryParams['utility_id'] = utilityId.toString();

    final json = await _apiClient.getRaw('utility-bills',
        queryParams: queryParams.isEmpty ? null : queryParams);
    if (json['success'] == true) {
      final List data = json['data'] ?? [];
      final meta = json['meta'] ?? {};
      final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
      return {
        'data': data
            .map((e) => UtilityBillModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        'has_more': hasMore,
      };
    }
    throw Exception(json['message'] ?? 'Gagal memuat tagihan utility.');
  }

  Future<UtilityBillModel> getUtilityBill(int id) async {
    final data = await _apiClient.get('utility-bills/$id');
    return UtilityBillModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UtilityBillModel> createUtilityBill(Map<String, dynamic> data) async {
    final responseData = await _apiClient.post('utility-bills', body: data);
    return UtilityBillModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<UtilityBillModel> updateUtilityBill(
      int id, Map<String, dynamic> data) async {
    final responseData = await _apiClient.put('utility-bills/$id', body: data);
    return UtilityBillModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<void> deleteUtilityBill(int id) async {
    await _apiClient.delete('utility-bills/$id');
  }

  Future<List<Map<String, dynamic>>> getUtilities({int? storeId}) async {
    final queryParams = <String, String>{};
    if (storeId != null) queryParams['store_id'] = storeId.toString();

    final data = await _apiClient.get('utilities',
        queryParams: queryParams.isEmpty ? null : queryParams);
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getStores() async {
    final data = await _apiClient.get('stores');
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}
