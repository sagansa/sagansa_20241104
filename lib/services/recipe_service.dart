import '../models/production_model.dart';
import 'api_client.dart';

/// Service baca master resep produksi. Mobile hanya bisa membaca —
/// penulisan/edit resep via apps/admin (Filament).
class RecipeService {
  final ApiClient _api = ApiClient();

  /// List resep aktif (default). Set `includeInactive=true` untuk semua.
  Future<({List<Recipe> items, int? nextPage})> list({
    int page = 1,
    int perPage = 50,
    bool includeInactive = false,
  }) async {
    final queryParams = {
      'page': '$page',
      'per_page': '$perPage',
      if (includeInactive) 'include_inactive': '1',
    };
    final body = await _api.getRaw('recipes', queryParams: queryParams);
    final data = (body['data'] as List? ?? const [])
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = body['pagination'] as Map<String, dynamic>?;
    final next = pagination != null &&
            (pagination['current_page'] as num?)!.toInt() <
                (pagination['last_page'] as num?)!.toInt()
        ? page + 1
        : null;
    return (items: data, nextPage: next);
  }

  /// Detail resep by id.
  Future<Recipe> show(int id) async {
    final data = await _api.get('recipes/$id');
    return Recipe.fromJson(data as Map<String, dynamic>);
  }

  /// Resep aktif untuk produk output tertentu. Return null jika 404.
  Future<Recipe?> byProduct(int productId) async {
    try {
      final data = await _api.get('recipes/by-product/$productId');
      return Recipe.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('404')) return null;
      rethrow;
    }
  }
}
