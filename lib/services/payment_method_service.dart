import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_method_model.dart';
import '../utils/constants.dart';

class PaymentMethodService {
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Payment Methods Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final PaymentMethodResponse paymentMethodResponse =
              PaymentMethodResponse.fromJson(responseData);
          return paymentMethodResponse.data;
        } else {
          throw Exception(
              responseData['message'] ?? 'Gagal memuat metode pembayaran');
        }
      } else {
        throw Exception(
            'Gagal memuat metode pembayaran: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting payment methods: $e');
      throw Exception('Gagal memuat metode pembayaran: $e');
    }
  }
}
