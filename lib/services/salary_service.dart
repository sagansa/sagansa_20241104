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
}
