import '../models/utility_model.dart';
import 'api_client.dart';

class UtilityService {
  final ApiClient _apiClient = ApiClient();

  /// [includeInactive] untuk list manajemen admin (semua status);
  /// default hanya aktif (dipakai dropdown pemakaian/tagihan).
  Future<List<UtilityModel>> getUtilities({
    int? storeId,
    int? category,
    String? search,
    bool includeInactive = false,
  }) async {
    final queryParams = <String, String>{};
    if (storeId != null) queryParams['store_id'] = storeId.toString();
    if (category != null) queryParams['category'] = category.toString();
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (includeInactive) queryParams['all'] = '1';

    final data = await _apiClient.get('utilities',
        queryParams: queryParams.isEmpty ? null : queryParams);
    return (data as List)
        .map((e) => UtilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lookup untuk form utility: toko, satuan, provider.
  Future<Map<String, List<Map<String, dynamic>>>> getLookups() async {
    final data = await _apiClient.get('utilities/lookups');
    final map = data as Map<String, dynamic>;
    List<Map<String, dynamic>> list(String key) =>
        ((map[key] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
    return {
      'stores': list('stores'),
      'units': list('units'),
      'utility_providers': list('utility_providers'),
    };
  }

  Future<UtilityModel> createUtility(Map<String, dynamic> payload) async {
    final data =
        await _apiClient.post('utilities', body: payload);
    return UtilityModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UtilityModel> updateUtility(
      int id, Map<String, dynamic> payload) async {
    final data = await _apiClient.put('utilities/$id', body: payload);
    return UtilityModel.fromJson(data as Map<String, dynamic>);
  }

  /// [status] 1 = aktif, 2 = nonaktif (admin/super_admin).
  Future<void> updateUtilityStatus(int id, int status) async {
    await _apiClient.patch('utilities/$id/status', body: {'status': status});
  }

  Future<List<Map<String, dynamic>>> getStores() async {
    final data = await _apiClient.get('stores');
    return (data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}
