import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/procurement_model.dart';
import '../utils/constants.dart';
import 'image_upload_service.dart';

class ProcurementService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<ProcurementProduct>> getProducts() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> productsJson = data['data'] ?? [];
      return productsJson.map((json) => ProcurementProduct.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<RequestPurchase>> getRequests({
    int page = 1,
    int perPage = 1000,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/procurement/requests')
        .replace(queryParameters: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> requestsJson = data['data'] ?? [];
      return requestsJson.map((json) => RequestPurchase.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load procurement requests');
    }
  }

  Future<Map<String, dynamic>> getRequestsPaged({int page = 1, int perPage = 20}) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/procurement/requests')
        .replace(queryParameters: {'page': page.toString(), 'per_page': perPage.toString()});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      if (body['success'] == true) {
        final List<dynamic> data = body['data'] ?? [];
        final meta = body['pagination'] ?? {};
        final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
        return {
          'data': data.map((e) => RequestPurchase.fromJson(e)).toList(),
          'has_more': hasMore,
        };
      }
      throw Exception(body['message'] ?? 'Failed to load procurement requests');
    }
    throw Exception('Failed to load procurement requests');
  }

  Future<Map<String, dynamic>> getProcurementSummary() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> requestsJson = body['data'] ?? [];
      final List<RequestPurchase> requests = requestsJson.map((json) => RequestPurchase.fromJson(json)).toList();
      final Map<String, dynamic> meta = body['meta'] ?? {};
      final Map<String, dynamic> invoiceCounts = meta['invoice_counts'] ?? {'draft': 0, 'done': 0, 'unpaid': 0};
      
      return {
        'requests': requests,
        'invoice_draft': invoiceCounts['draft'] ?? 0,
        'invoice_done': invoiceCounts['done'] ?? 0,
        'invoice_unpaid': invoiceCounts['unpaid'] ?? 0,
      };
    } else {
      throw Exception('Failed to load procurement summary');
    }
  }

  Future<RequestPurchase> getRequestDetail(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return RequestPurchase.fromJson(data['data']);
    } else {
      throw Exception('Failed to load request detail');
    }
  }

  Future<bool> createRequest(int storeId, List<Map<String, dynamic>> items) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'store_id': storeId,
        'items': items,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to submit request');
    }
  }

  Future<bool> approveItem(int itemId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests/items/$itemId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to approve item');
    }
  }

  Future<bool> rejectItem(int itemId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests/items/$itemId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to reject item');
    }
  }

  Future<bool> cancelItem(int itemId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests/items/$itemId/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to cancel item');
    }
  }

  Future<bool> receiveInvoice(int invoiceId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/invoices/$invoiceId/receive'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menandai invoice sudah diterima.');
    }
  }

  Future<List<Map<String, dynamic>>> getDetailRequests({
    required int storeId,
    int? paymentTypeId,
  }) async {
    final token = await _getToken();
    final params = <String, String>{
      'store_id': storeId.toString(),
    };
    if (paymentTypeId != null) {
      params['payment_type_id'] = paymentTypeId.toString();
    }
    final uri = Uri.parse('${ApiConstants.baseUrl}/procurement/detail-requests')
        .replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load detail requests');
    }
  }

  Future<int> createInvoiceStandalone({
    required int supplierId,
    required int storeId,
    required int paymentTypeId,
    required String date,
    required List<Map<String, dynamic>> items,
    int? taxes,
    int? discounts,
    String? notes,
  }) async {
    final token = await _getToken();
    final body = <String, dynamic>{
      'supplier_id': supplierId,
      'store_id': storeId,
      'payment_type_id': paymentTypeId,
      'date': date,
      'items': items,
    };
    if (taxes != null) body['taxes'] = taxes;
    if (discounts != null) body['discounts'] = discounts;
    if (notes != null) body['notes'] = notes;

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/invoices'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['data']['id'] ?? 0;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create invoice');
    }
  }

  Future<int> createInvoice(int requestId, {
    required int supplierId,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests/$requestId/create-invoice'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'supplier_id': supplierId,
        'items': items,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['invoice_id'] ?? 0;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create invoice');
    }
  }

  Future<InvoicePurchase> updateInvoice(int invoiceId, {
    int? supplierId,
    int? paymentTypeId,
    int? taxes,
    int? discounts,
    String? notes,
    List<Map<String, dynamic>>? items,
  }) async {
    final token = await _getToken();
    final body = <String, dynamic>{};
    if (supplierId != null) body['supplier_id'] = supplierId;
    if (paymentTypeId != null) body['payment_type_id'] = paymentTypeId;
    if (taxes != null) body['taxes'] = taxes;
    if (discounts != null) body['discounts'] = discounts;
    if (notes != null) body['notes'] = notes;
    if (items != null) body['items'] = items;

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/procurement/invoices/$invoiceId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return InvoicePurchase.fromJson(data['data']);
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update invoice');
    }
  }

  Future<PaginatedResult<InvoicePurchase>> getInvoices({
    String? orderStatus,
    String? paymentStatus,
    int? storeId,
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getToken();
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (orderStatus != null) params['order_status'] = orderStatus;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (storeId != null) params['store_id'] = storeId.toString();

    final uri = Uri.parse('${ApiConstants.baseUrl}/procurement/invoices').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> invoicesJson = body['data'] ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      return PaginatedResult(
        items: invoicesJson.map((json) => InvoicePurchase.fromJson(json)).toList(),
        currentPage: meta['current_page'] ?? 1,
        lastPage: meta['last_page'] ?? 1,
        perPage: meta['per_page'] ?? perPage,
        total: meta['total'] ?? 0,
      );
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  Future<PaginatedResult<PaymentReceipt>> getPaymentReceipts({
    int? invoiceId,
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getToken();
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (invoiceId != null) params['invoice_id'] = invoiceId.toString();

    final uri = Uri.parse('${ApiConstants.baseUrl}/procurement/payment-receipts').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> receiptsJson = body['data'] ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      return PaginatedResult(
        items: receiptsJson.map((json) => PaymentReceipt.fromJson(json)).toList(),
        currentPage: meta['current_page'] ?? 1,
        lastPage: meta['last_page'] ?? 1,
        perPage: meta['per_page'] ?? perPage,
        total: meta['total'] ?? 0,
      );
    } else {
      throw Exception('Failed to load payment receipts');
    }
  }

  Future<PaymentReceipt> getPaymentReceiptDetail(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/payment-receipts/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return PaymentReceipt.fromJson(data['data']);
    } else {
      throw Exception('Failed to load payment receipt detail');
    }
  }

  Future<PaymentReceipt> createPaymentReceipt({
    required List<int> invoiceIds,
    required int transferAmount,
    int? totalAmount,
    String? notes,
    File? image,
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/procurement/payment-receipts'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    for (var id in invoiceIds) {
      request.fields['invoice_ids[]'] = id.toString();
    }
    request.fields['transfer_amount'] = transferAmount.toString();
    if (totalAmount != null) {
      request.fields['total_amount'] = totalAmount.toString();
    }
    if (notes != null) {
      request.fields['notes'] = notes;
    }
    if (image != null) {
      final path = await ImageUploadService.upload(image, directory: 'images/PaymentReceipt');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      request.fields['image'] = path;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return PaymentReceipt.fromJson(data['data']);
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create payment receipt');
    }
  }

  Future<InvoicePurchase> getInvoiceDetail(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/invoices/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return InvoicePurchase.fromJson(data['data']);
    } else {
      throw Exception('Failed to load invoice detail');
    }
  }

  /// Get QRIS payload for a payment receipt (client-side QR rendering).
  Future<Map<String, dynamic>> getPaymentReceiptQris(int receiptId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/payment-receipts/$receiptId/qris'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final Map<String, dynamic> body = json.decode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Gagal memuat QRIS payment.');
  }
}
