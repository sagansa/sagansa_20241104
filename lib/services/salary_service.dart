import 'api_client.dart';

class SalaryService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getSalaryHistory() async {
    final data = await _api.get('salaries');
    return (data as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getSalaryDetail(int salaryId) async {
    final data = await _api.get('salaries/$salaryId');
    return Map<String, dynamic>.from(data);
  }

  /// Get monthly salary list with pagination + filters (admin view).
  /// Returns { data: [...], meta: {...} }.
  Future<Map<String, dynamic>> getSalaryHistoryAdmin({
    int page = 1,
    int perPage = 20,
    int? userId,
    String? period,
    String? status,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (userId != null) params['user_id'] = userId.toString();
    if (period != null) params['period'] = period;
    if (status != null) params['status'] = status;

    final jsonResponse = await _api.getRaw('salaries', queryParams: params);
    return {
      'data': jsonResponse['data'] as List<dynamic>? ?? [],
      'meta': jsonResponse['meta'] ?? <String, dynamic>{},
    };
  }

  /// Get employees who have monthly salary records (admin filter dropdown).
  Future<List<Map<String, dynamic>>> getEmployeesForSalary() async {
    final data = await _api.get('salaries/employees');
    return (data as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Generate/regenerate monthly payroll (admin).
  Future<Map<String, dynamic>> generatePayroll({
    required int month,
    required int year,
  }) async {
    final jsonResponse = await _api.postRaw(
      'salaries/generate',
      body: {'month': month, 'year': year},
    );
    return jsonResponse;
  }

  /// Approve single slip (admin).
  Future<void> approveSalary(int id) async {
    await _api.post('salaries/$id/approve');
  }

  /// Bulk approve (admin).
  Future<int> bulkApproveSalaries(List<int> ids) async {
    final jsonResponse = await _api.postRaw(
      'salaries/approve',
      body: {'ids': ids},
    );
    return (jsonResponse['approved_count'] as int?) ?? 0;
  }

  /// Bayar gaji (admin).
  Future<Map<String, dynamic>> paySalary({
    required int id,
    required double paidAmount,
    required String paymentDate,
  }) async {
    final data = await _api.post(
      'salaries/$id/pay',
      body: {
        'paid_amount': paidAmount,
        'payment_date': paymentDate,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  /// Info pembayaran: bank + breakdown + defaults (admin).
  Future<Map<String, dynamic>> getPaymentInfo(int id) async {
    final data = await _api.get('salaries/$id/payment-info');
    return Map<String, dynamic>.from(data);
  }

  /// Rekap presensi untuk satu periode cut-off gaji (YYYY-MM).
  /// [userId] = karyawan lain (admin); null = diri sendiri.
  Future<Map<String, dynamic>> getMonthlyPresence({
    required String period,
    int? userId,
  }) async {
    final params = <String, String>{'period': period};
    if (userId != null) params['user_id'] = userId.toString();

    final data = await _api.get('presences/monthly', queryParams: params);
    return Map<String, dynamic>.from(data as Map);
  }
}
