import '../models/utility_usage_model.dart';
import 'api_client.dart';

class UtilityUsageService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UtilityUsageModel>> getUtilityUsages({
    int? storeId,
    int? category,
    int? utilityId,
    int? status,
  }) async {
    final queryParams = <String, String>{'per_page': '1000'};
    if (storeId != null) queryParams['store_id'] = storeId.toString();
    if (category != null) queryParams['category'] = category.toString();
    if (utilityId != null) queryParams['utility_id'] = utilityId.toString();
    if (status != null) queryParams['status'] = status.toString();

    final data = await _apiClient.get('utility-usages',
        queryParams: queryParams.isEmpty ? null : queryParams);
    return (data as List).map((e) => UtilityUsageModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getUtilityUsagesPaged({
    int page = 1, int perPage = 20,
    int? storeId, int? category, int? utilityId, int? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (storeId != null) queryParams['store_id'] = storeId.toString();
    if (category != null) queryParams['category'] = category.toString();
    if (utilityId != null) queryParams['utility_id'] = utilityId.toString();
    if (status != null) queryParams['status'] = status.toString();
    final json = await _apiClient.getRaw('utility-usages',
        queryParams: queryParams.isEmpty ? null : queryParams);
    if (json['success'] == true) {
      final List data = json['data'] ?? [];
      final meta = json['meta'] ?? {};
      final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
      return {
        'data': data.map((e) => UtilityUsageModel.fromJson(e as Map<String, dynamic>)).toList(),
        'has_more': hasMore,
      };
    }
    throw Exception(json['message'] ?? 'Gagal memuat penggunaan utilitas.');
  }

  Future<UtilityUsageModel> getUtilityUsage(int id) async {
    final data = await _apiClient.get('utility-usages/$id');
    return UtilityUsageModel.fromJson(data);
  }

  Future<UtilityUsageModel> createUtilityUsage(Map<String, dynamic> data) async {
    final responseData = await _apiClient.post('utility-usages', body: data);
    return UtilityUsageModel.fromJson(responseData);
  }

  Future<UtilityUsageModel> updateUtilityUsage(
      int id, Map<String, dynamic> data) async {
    final responseData =
        await _apiClient.post('utility-usages/$id', body: data);
    return UtilityUsageModel.fromJson(responseData);
  }

  Future<void> deleteUtilityUsage(int id) async {
    await _apiClient.delete('utility-usages/$id');
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
