import '../models/store_model.dart';
import '../services/api_client.dart';

class StoreService {
  final ApiClient _api = ApiClient();

  Future<List<StoreModel>> getStores() async {
    final data = await _api.get('stores');
    return (data as List<dynamic>)
        .map((store) => StoreModel.fromJson(store))
        .toList();
  }
}
