import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_detail_model.dart';
import '../utils/constants.dart';
import '../models/transaction_history_model.dart';

class TransactionService {
  Future<Map<String, dynamic>> createTransaction({
    required int paidAmount,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final requestData = {
        'paid_amount': paidAmount,
        'payment_method': paymentMethod,
        'notes': notes,
      };

      print('Request Data: $requestData');
      print('Token: $token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Gagal membuat transaksi');
      }
    } catch (e) {
      print('Error in createTransaction: $e');
      throw Exception('Error: $e');
    }
  }

  Future<List<TransactionHistoryModel>> getTransactionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print('Request URL: ${ApiConstants.baseUrl}/transaction-history');
      print('Token: $token');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transaction-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final List<dynamic> transactionsJson = responseData['data'];
        return transactionsJson
            .map((json) => TransactionHistoryModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal mengambil riwayat transaksi');
      }
    } catch (e) {
      print('Detailed error in getTransactionHistory: $e');
      throw Exception('Error: $e');
    }
  }

  Future<TransactionHistoryModel> getTransaction(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transaction-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return TransactionHistoryModel.fromJson(responseData['data']);
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal mengambil data transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<TransactionDetail> getTransactionDetail(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transactions/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('URL: ${ApiConstants.baseUrl}/transactions/$transactionId');
      print('Headers: ${response.headers}');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return TransactionDetailResponse.fromJson(responseData).data;
      } else {
        throw Exception(
            responseData['message'] ?? 'Gagal mengambil detail transaksi');
      }
    } catch (e) {
      print('Error in getTransactionDetail: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> refundTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/transactions/$transactionId/refund'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Gagal melakukan refund');
      }
    } catch (e) {
      print('Error in refundTransaction: $e');
      throw Exception('Error: $e');
    }
  }
}
