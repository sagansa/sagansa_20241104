import '../models/transfer_stock_model.dart';
import 'api_client.dart';

class TransferStockService {
  final ApiClient _api = ApiClient();

  Future<List<TransferStockProduct>> getProducts() async {
    final data = await _api.get('transfer-stocks/products');
    final List items = data as List;
    return items.map((item) => TransferStockProduct.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> getTransferStocks({int page = 1, int perPage = 20}) async {
    final response = await _api.getRaw('transfer-stocks', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });

    final List data = response['data'];
    final transfers = data.map((item) => TransferStockModel.fromJson(item)).toList();
    final pagination = response['pagination'] as Map<String, dynamic>?;
    return {
      'transfers': transfers,
      'has_more': (pagination?['current_page'] ?? 1) < (pagination?['last_page'] ?? 1),
    };
  }

  Future<TransferStockModel> getTransferStock(int id) async {
    final data = await _api.get('transfer-stocks/$id');
    return TransferStockModel.fromJson(data);
  }

  Future<void> createTransferStock({
    required int fromStoreId,
    required int toStoreId,
    required String date,
    required List<Map<String, dynamic>> items,
    int? sentById,
    int? receivedById,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'from_store_id': fromStoreId,
      'to_store_id': toStoreId,
      'date': date,
      'status': 'pending',
      'items': items,
    };
    if (sentById != null) body['sent_by_id'] = sentById;
    if (receivedById != null) body['received_by_id'] = receivedById;
    if (notes != null) body['notes'] = notes;

    await _api.post('transfer-stocks', body: body);
  }
}
