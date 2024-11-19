import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/category_model.dart' as category;
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_detail_model.dart' as detail;
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductService {
  final String? token;

  ProductService({this.token});

  Future<ProductResponse> getProducts() async {
    try {
      final token = await _getToken();

      final url = Uri.parse('${ApiConstants.baseUrl}/products');

      print('Fetching products with URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        print('Status: ${data['status']}');
        print('Cart count: ${data['cart_count']}');
        print('Data type: ${data['data'].runtimeType}');

        return ProductResponse.fromJson(data);
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e, stackTrace) {
      print('Error in getProducts: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error loading products: $e');
    }
  }

  Future<List<category.CategoryModel>> getCategories() async {
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
              .map((json) => category.CategoryModel.fromJson(json))
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

  Future<void> addToCart(
      Map<String, dynamic> cartData, BuildContext context) async {
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

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['cart_count'] != null) {
          Provider.of<CartProvider>(context, listen: false)
              .setCartCount(jsonResponse['cart_count']);
        }
      } else {
        throw Exception('Gagal menambahkan ke keranjang: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateCart(int cartItemId, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartItemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui keranjang: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
