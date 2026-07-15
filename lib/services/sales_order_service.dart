import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_order_online_model.dart';
import '../models/store_model.dart';
import '../utils/constants.dart';
import 'dart:io';
import 'image_upload_service.dart';

class SalesOrderService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  /// Daftar produk yang bisa dijual online.
  Future<List<SalesOrderOnlineProduct>> getOnlineProducts() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.onlineProducts),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final list = json['data'] as List;
        return list
            .map((e) => SalesOrderOnlineProduct.fromJson(e))
            .toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat produk.');
    }
    throw Exception('Gagal memuat produk: ${response.statusCode}');
  }

  /// Daftar online shop provider (Shopee, Tokopedia, dll).
  Future<List<OnlineShopProvider>> getOnlineShopProviders() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.onlineShopProviders),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final list = json['data'] as List;
        return list.map((e) => OnlineShopProvider.fromJson(e)).toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat provider.');
    }
    throw Exception('Gagal memuat provider: ${response.statusCode}');
  }

  /// Daftar delivery service (JNE, SiCepat, dll).
  Future<List<DeliveryServiceOption>> getDeliveryServices() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.deliveryServices),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final list = json['data'] as List;
        return list.map((e) => DeliveryServiceOption.fromJson(e)).toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat delivery service.');
    }
    throw Exception('Gagal memuat delivery service: ${response.statusCode}');
  }

  /// Buat sales order online.
  /// [items] sebagai JSON string (karena multipart form tidak support nested array
  /// secara native — dikirim sebagai field string lalu di-decode backend).
  Future<void> createOnlineOrder({
    required Store selectedStore,
    required String deliveryDate,
    required int onlineShopProviderId,
    required int deliveryServiceId,
    required String receiptNo,
    required List<SalesOrderItemRequest> items,
    File? imagePayment,
    Uint8List? imagePaymentBytes,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final uri = Uri.parse(ApiConstants.createSalesOrderOnline);
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token))
      ..fields['store_id'] = selectedStore.id.toString()
      ..fields['delivery_date'] = deliveryDate
      ..fields['online_shop_provider_id'] = onlineShopProviderId.toString()
      ..fields['delivery_service_id'] = deliveryServiceId.toString()
      ..fields['receipt_no'] = receiptNo;

    // Kirim items dalam notasi array Laravel (items[0][product_id], dll) agar
    // validasi backend `items.*.product_id` terpenuhi secara native.
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      request.fields['items[$i][product_id]'] = item.productId.toString();
      request.fields['items[$i][quantity]'] = item.quantity.toString();
      request.fields['items[$i][unit_price]'] = item.unitPrice.toString();
    }

    if (imagePayment != null) {
      final path =
          await ImageUploadService.upload(imagePayment, directory: 'images/SalesOrder');
      if (path == null) throw Exception('Gagal upload bukti pembayaran.');
      request.fields['image_payment'] = path;
    } else if (imagePaymentBytes != null) {
      final path = await ImageUploadService.uploadBytes(
        imagePaymentBytes,
        'payment.jpg',
        directory: 'images/SalesOrder',
      );
      if (path == null) throw Exception('Gagal upload bukti pembayaran.');
      request.fields['image_payment'] = path;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final json = jsonDecode(response.body);

    if (response.statusCode == 201 && json['success'] == true) {
      return;
    }

    // Coba ambil pesan error spesifik dari backend.
    if (json is Map<String, dynamic> && json['message'] != null) {
      throw Exception(json['message']);
    }
    throw Exception('Gagal membuat sales order: ${response.statusCode}');
  }
}
