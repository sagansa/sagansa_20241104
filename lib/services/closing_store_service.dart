import 'dart:convert';
import 'dart:io';
import 'api_client.dart';
import 'image_upload_service.dart';

class ClosingStoreService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> getClosingStores() async {
    final data = await _api.get('closing-stores', queryParams: {'per_page': '1000'});
    return data as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> getClosingStoresPaged({int page = 1, int perPage = 20}) async {
    final response = await _api.getRaw('closing-stores', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    final List data = response['data'] as List<dynamic>? ?? [];
    final meta = response['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {'data': data.cast<Map<String, dynamic>>(), 'has_more': hasMore};
  }

  Future<Map<String, dynamic>> getClosingStore(int id) async {
    return await _api.get('closing-stores/$id');
  }

  Future<Map<String, dynamic>> getActiveDraft() async {
    return await _api.get('closing-stores/active-draft');
  }

  Future<Map<String, dynamic>> getUnpaidTransactions() async {
    return await _api.get('closing-stores/unpaid-transactions');
  }

  Future<void> saveClosingStore(Map<String, dynamic> data) async {
    await _api.post('closing-stores/save', body: data);
  }

  Future<Map<String, dynamic>> createFuelService(Map<String, dynamic> data, {File? imageFile}) async {
    final fields = <String, String>{};
    data.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          fields[key] = json.encode(value);
        } else {
          fields[key] = value.toString();
        }
      }
    });

    if (imageFile != null) {
      final path = await ImageUploadService.upload(imageFile, directory: 'images/FuelService');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['image'] = path;
    }

    final result = await _api.multipart(
      method: 'POST',
      path: 'closing-stores/fuel-services',
      fields: fields,
    );
    return result as Map<String, dynamic>;
  }

  Future<List<dynamic>> getVehicles() async {
    final data = await _api.get('closing-stores/vehicles');
    return data as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getSuppliers() async {
    final data = await _api.get('closing-stores/suppliers');
    return data as List<dynamic>? ?? [];
  }

  /// Get all daily salaries (with pagination)
  Future<Map<String, dynamic>> getDailySalaries({
    int page = 1,
    int perPage = 20,
    int? userId,
    String? status,
    int? paymentTypeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (userId != null) params['user_id'] = userId.toString();
    if (status != null) params['status'] = status;
    if (paymentTypeId != null) params['payment_type_id'] = paymentTypeId.toString();
    if (dateFrom != null) params['date_from'] = dateFrom.toIso8601String().substring(0, 10);
    if (dateTo != null) params['date_to'] = dateTo.toIso8601String().substring(0, 10);

    final response = await _api.getRaw('daily-salaries', queryParams: params);
    return {
      'data': response['data'] as List<dynamic>? ?? [],
      'meta': response['meta'] ?? {},
    };
  }

  /// Bulk update status for daily salaries (admin only)
  Future<int> bulkUpdateDailySalaryStatus(List<int> ids, int status) async {
    final result = await _api.post('daily-salaries/bulk-update-status', body: {
      'ids': ids,
      'status': status,
    });
    return (result as Map<String, dynamic>)['updated_count'] ?? 0;
  }

  /// Get daily salaries for payment receipt (transfer type, status 3 = siap dibayar)
  Future<List<dynamic>> getDailySalariesForPayment({int? userId}) async {
    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId.toString();
    final data = await _api.get('daily-salaries', queryParams: params.isNotEmpty ? params : null);
    return data as List<dynamic>? ?? [];
  }

  /// Get employees for daily salary payment selection
  Future<List<dynamic>> getEmployeesForDailySalary() async {
    final data = await _api.get('daily-salaries/employees');
    return data as List<dynamic>? ?? [];
  }

  /// Get fuel services for payment receipt (transfer type, status 1 = unpaid)
  Future<List<dynamic>> getFuelServicesForPayment({int? createdById}) async {
    final params = <String, String>{};
    if (createdById != null) params['created_by_id'] = createdById.toString();
    final data = await _api.get('closing-stores/fuel-services-for-payment', queryParams: params.isNotEmpty ? params : null);
    return data as List<dynamic>? ?? [];
  }

  /// Get users who have fuel service records for payment
  Future<List<dynamic>> getUsersForFuelServicePayment() async {
    final data = await _api.get('closing-stores/fuel-services/users');
    return data as List<dynamic>? ?? [];
  }

  /// Create a payment receipt
  Future<Map<String, dynamic>> createPaymentReceipt(Map<String, dynamic> data, {File? imageFile}) async {
    final fields = <String, String>{};
    data.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            fields['$key[$i]'] = value[i].toString();
          }
        } else {
          fields[key] = value.toString();
        }
      }
    });

    if (imageFile != null) {
      final path = await ImageUploadService.upload(imageFile, directory: 'images/PaymentReceipt');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['image'] = path;
    }

    final result = await _api.multipart(
      method: 'POST',
      path: 'procurement/payment-receipts',
      fields: fields,
    );
    return (result as Map<String, dynamic>?) ?? {};
  }

  /// Get payment receipts list
  Future<List<dynamic>> getPaymentReceipts({int page = 1, int perPage = 10}) async {
    final data = await _api.get('procurement/payment-receipts', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    return data as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getFuelServices({bool allStores = false}) async {
    final query = <String, String>{'per_page': '1000'};
    if (allStores) query['all_stores'] = '1';
    final data = await _api.get('closing-stores/fuel-services', queryParams: query);
    return data as List<dynamic>? ?? [];
  }

  /// Filter params untuk getFuelServicesPaged.
  ///
  /// Konvensi:
  /// - createdById: null (semua user, admin only) atau id user spesifik
  /// - status: null (semua), '1' (Pending), '2' (Lunas)
  /// - fuelService: null (semua), '1' (Fuel), '2' (Service)
  Future<Map<String, dynamic>> getFuelServicesPaged({
    bool allStores = false,
    int page = 1,
    int perPage = 20,
    int? createdById,
    String? status,
    String? fuelService,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (allStores) query['all_stores'] = '1';
    if (createdById != null) query['created_by_id'] = createdById.toString();
    if (status != null) query['status'] = status;
    if (fuelService != null) query['fuel_service'] = fuelService;

    final response = await _api.getRaw('closing-stores/fuel-services', queryParams: query);
    final List data = response['data'] as List<dynamic>? ?? [];
    final meta = response['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {'data': data.cast<Map<String, dynamic>>(), 'has_more': hasMore};
  }
}
