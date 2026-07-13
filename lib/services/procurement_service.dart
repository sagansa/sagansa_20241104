import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/procurement_model.dart';
import '../utils/constants.dart';

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

  Future<List<RequestPurchase>> getRequests() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/procurement/requests'),
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
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path,
            contentType: MediaType('image', 'jpeg')),
      );
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
