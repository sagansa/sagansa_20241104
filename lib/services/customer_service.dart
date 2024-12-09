import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../utils/constants.dart';

class CustomerService {
  Future<CustomerModel> createCustomer({
    required String name,
    String? noTelp,
    String? email,
    String? address,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/customers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          if (noTelp != null) 'no_telp': noTelp,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return CustomerModel.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Gagal membuat customer');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<CustomerModel>> getCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/customers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final List<dynamic> customersJson = responseData['data'];
        return customersJson
            .map((json) => CustomerModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal mengambil data customer');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
