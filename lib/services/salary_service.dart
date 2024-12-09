import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salary_model.dart';
import '../utils/constants.dart';

class SalaryService {
  final String token;

  SalaryService(this.token);

  Future<List<SalaryModel>> getAllSalaries() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/salaries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => SalaryModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load salaries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching salaries: $e');
      rethrow;
    }
  }
}
