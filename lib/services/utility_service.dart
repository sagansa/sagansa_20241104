import '../models/utility_model.dart';
import 'api_client.dart';

class UtilityService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UtilityModel>> getUtilities({
    int? storeId,
    int? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (storeId != null) queryParams['store_id'] = storeId.toString();
    if (category != null) queryParams['category'] = category.toString();
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final data = await _apiClient.get('utilities',
        queryParams: queryParams.isEmpty ? null : queryParams);
    return (data as List)
        .map((e) => UtilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStores() async {
    final data = await _apiClient.get('stores');
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}
