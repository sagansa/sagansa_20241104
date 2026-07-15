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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (userId != null) params['user_id'] = userId.toString();
    if (period != null) params['period'] = period;

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
}
