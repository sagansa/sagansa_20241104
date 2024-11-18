import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_model.dart';
import '../utils/constants.dart';

class CartService {
  Future<Cart> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/carts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Cart Response Status: ${response.statusCode}');
      print('Cart Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          return Cart.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Gagal memuat keranjang');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in getCartItems: $e');
      throw Exception('Gagal mengambil data keranjang: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.delete(
        Uri.parse(ApiConstants.carts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus keranjang');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> updateCart(int cartId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartId'),
        headers: {
          'Content-Type': 'application/json',
          // tambahkan header authorization jika diperlukan
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw 'Gagal mengupdate keranjang';
      }
    } catch (e) {
      throw 'Error: ${e.toString()}';
    }
  }

  Future<void> deleteCartItem(int cartItemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartItemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200 || responseData['status'] != 'success') {
        throw Exception(
            responseData['message'] ?? 'Gagal menghapus item dari keranjang');
      }
    } catch (e) {
      print('Delete error detail: $e');
      throw Exception('Gagal menghapus item: $e');
    }
  }
}
