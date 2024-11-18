import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_detail_model.dart' as detail;

class ProductService {
  final String? token;

  ProductService({this.token});

  Future<ProductResponse> getProducts() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ProductResponse.fromJson(jsonResponse);
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/products/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> categoriesJson = jsonResponse['data'];
          return categoriesJson
              .map((json) => CategoryModel.fromJson(json))
              .toList();
        } else {
          throw Exception('Status bukan success: ${jsonResponse['status']}');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token tidak ditemukan');
    return token;
  }

  Future<detail.ProductResponse> getProductDetail(int productId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          return detail.ProductResponse.fromJson(jsonResponse);
        } else {
          throw Exception('Data tidak valid: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> addToCart(Map<String, dynamic> cartData) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/carts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(cartData),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menambahkan ke keranjang: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
