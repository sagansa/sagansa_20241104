import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class SalaryService {
  Future<List<Map<String, dynamic>>> getSalaryHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(ApiConstants.salaries),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to load salary history');
    }
  }

  Future<Map<String, dynamic>> getSalaryDetail(int salaryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${ApiConstants.salaries}/$salaryId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data']);
    } else {
      throw Exception('Failed to load salary details');
    }
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (userId != null) params['user_id'] = userId.toString();
    if (period != null) params['period'] = period;
    if (status != null) params['status'] = status;

    final uri = Uri.parse(ApiConstants.salaries).replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return {
        'data': jsonResponse['data'] as List<dynamic>? ?? [],
        'meta': jsonResponse['meta'] ?? <String, dynamic>{},
      };
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data gaji.');
    }
  }

  /// Get employees who have monthly salary records (admin filter dropdown).
  Future<List<Map<String, dynamic>>> getEmployeesForSalary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${ApiConstants.salaries}/employees'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      final list = jsonResponse['data'] as List<dynamic>? ?? [];
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception(jsonResponse['message'] ?? 'Gagal memuat data karyawan.');
    }
  }

  /// Generate/regenerate monthly payroll (admin).
  Future<Map<String, dynamic>> generatePayroll({
    required int month,
    required int year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('${ApiConstants.salaries}/generate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'month': month, 'year': year}),
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse;
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal generate payroll.');
  }

  /// Approve single slip (admin).
  Future<void> approveSalary(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('${ApiConstants.salaries}/$id/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode != 200 || jsonResponse['success'] != true) {
      throw Exception(jsonResponse['message'] ?? 'Gagal approve slip.');
    }
  }

  /// Bulk approve (admin).
  Future<int> bulkApproveSalaries(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('${ApiConstants.salaries}/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'ids': ids}),
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['approved_count'] ?? 0;
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal bulk approve.');
  }

  /// Bayar gaji (admin).
  Future<Map<String, dynamic>> paySalary({
    required int id,
    required double paidAmount,
    required String paymentDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('${ApiConstants.salaries}/$id/pay'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'paid_amount': paidAmount,
        'payment_date': paymentDate,
      }),
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal membayar gaji.');
  }

  /// Info pembayaran: bank + breakdown + defaults (admin).
  Future<Map<String, dynamic>> getPaymentInfo(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('${ApiConstants.salaries}/$id/payment-info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal memuat info pembayaran.');
  }

  /// Rekap presensi untuk satu periode cut-off gaji (YYYY-MM).
  /// [userId] = karyawan lain (admin); null = diri sendiri.
  Future<Map<String, dynamic>> getMonthlyPresence({
    required String period,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final params = <String, String>{'period': period};
    if (userId != null) params['user_id'] = userId.toString();
    final uri = Uri.parse('${ApiConstants.baseUrl}/presences/monthly')
        .replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return Map<String, dynamic>.from(jsonResponse['data'] as Map);
    }
    throw Exception(jsonResponse['message'] ?? 'Gagal memuat rekap presensi.');
  }
}
