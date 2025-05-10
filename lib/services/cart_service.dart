import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

import '../models/cart_model.dart';
import '../utils/constants.dart';
import '../providers/cart_provider.dart';

class CartService {
  Future<List<CartItem>> getCartItems(BuildContext context) async {
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
          final cartData = jsonResponse['data']?['items'] as List?;
          print('Cart Data: $cartData');

          if (cartData == null) {
            print('Cart Data is null');
            return [];
          }

          final items =
              cartData.map((item) => CartItem.fromJson(item)).toList();
          print('Parsed Cart Items: ${items.length}');
          return items;
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

  Future<Map<String, dynamic>> updateCart(
      int cartId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Debug print
      print('Updating cart with data: $data');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData['data'];
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal mengupdate keranjang');
      }
    } catch (e) {
      print('Update cart error: $e');
      throw Exception('Gagal mengupdate keranjang: $e');
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

  Future<Map<String, dynamic>> incrementQuantity(int cartId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartId/increment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Gagal menambah quantity');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> decrementQuantity(int cartId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartId/decrement/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else if (response.statusCode == 400) {
        throw Exception(data['message']);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengurangi quantity');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> removeFromCart(int cartItemId, BuildContext context) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/carts/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['cart_count'] != null) {
          Provider.of<CartProvider>(context, listen: false)
              .setCartCount(jsonResponse['cart_count']);
        }
      } else {
        throw Exception('Failed to remove item from cart');
      }
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token tidak ditemukan');
    return token;
  }
}
