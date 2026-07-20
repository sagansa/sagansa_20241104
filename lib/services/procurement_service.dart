import 'dart:io';
import '../models/procurement_model.dart';
import 'api_client.dart';
import 'image_upload_service.dart';

class ProcurementService {
  final ApiClient _api = ApiClient();

  Future<List<ProcurementProduct>> getProducts() async {
    final data = await _api.get('procurement/products');
    final List<dynamic> productsJson = data is List ? data : [];
    return productsJson.map((e) => ProcurementProduct.fromJson(e)).toList();
  }

  Future<List<RequestPurchase>> getRequests({
    int page = 1,
    int perPage = 1000,
  }) async {
    final data = await _api.get('procurement/requests', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    final List<dynamic> requestsJson = data is List ? data : [];
    return requestsJson.map((e) => RequestPurchase.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getRequestsPaged({int page = 1, int perPage = 20}) async {
    final body = await _api.getRaw('procurement/requests', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load procurement requests');
    }
    final List<dynamic> data = body['data'] ?? [];
    final meta = body['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {
      'data': data.map((e) => RequestPurchase.fromJson(e)).toList(),
      'has_more': hasMore,
    };
  }

  Future<Map<String, dynamic>> getProcurementSummary() async {
    final body = await _api.getRaw('procurement/requests');
    final List<dynamic> requestsJson = body['data'] ?? [];
    final List<RequestPurchase> requests = requestsJson.map((e) => RequestPurchase.fromJson(e)).toList();
    final Map<String, dynamic> meta = body['meta'] ?? {};
    final Map<String, dynamic> invoiceCounts = meta['invoice_counts'] ?? {'draft': 0, 'done': 0, 'unpaid': 0};

    return {
      'requests': requests,
      'invoice_draft': invoiceCounts['draft'] ?? 0,
      'invoice_done': invoiceCounts['done'] ?? 0,
      'invoice_unpaid': invoiceCounts['unpaid'] ?? 0,
    };
  }

  Future<RequestPurchase> getRequestDetail(int id) async {
    final data = await _api.get('procurement/requests/$id');
    return RequestPurchase.fromJson(data);
  }

  Future<bool> createRequest(int storeId, List<Map<String, dynamic>> items) async {
    await _api.post('procurement/requests', body: {
      'store_id': storeId,
      'items': items,
    });
    return true;
  }

  Future<bool> approveItem(int itemId) async {
    await _api.post('procurement/requests/items/$itemId/approve');
    return true;
  }

  Future<bool> rejectItem(int itemId) async {
    await _api.post('procurement/requests/items/$itemId/reject');
    return true;
  }

  Future<bool> cancelItem(int itemId) async {
    await _api.post('procurement/requests/items/$itemId/cancel');
    return true;
  }

  Future<bool> receiveInvoice(int invoiceId) async {
    await _api.post('procurement/invoices/$invoiceId/receive');
    return true;
  }

  Future<List<Map<String, dynamic>>> getDetailRequests({
    required int storeId,
    int? paymentTypeId,
  }) async {
    final params = <String, String>{
      'store_id': storeId.toString(),
    };
    if (paymentTypeId != null) {
      params['payment_type_id'] = paymentTypeId.toString();
    }
    final body = await _api.getRaw('procurement/detail-requests', queryParams: params);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load detail requests');
    }
    return List<Map<String, dynamic>>.from(body['data']);
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

    final data = await _api.post('procurement/invoices', body: body);
    return data?['id'] ?? 0;
  }

  Future<int> createInvoice(int requestId, {
    required int supplierId,
    required List<Map<String, dynamic>> items,
    List<int>? requestIds,
  }) async {
    final body = <String, dynamic>{
      'supplier_id': supplierId,
      'items': items,
    };
    if (requestIds != null && requestIds.isNotEmpty) {
      body['request_ids'] = requestIds;
    }
    final rawBody = await _api.postRaw('procurement/requests/$requestId/create-invoice', body: body);
    return rawBody['invoice_id'] ?? 0;
  }

  Future<InvoicePurchase> updateInvoice(int invoiceId, {
    int? supplierId,
    int? paymentTypeId,
    int? taxes,
    int? discounts,
    String? notes,
    List<Map<String, dynamic>>? items,
  }) async {
    final body = <String, dynamic>{};
    if (supplierId != null) body['supplier_id'] = supplierId;
    if (paymentTypeId != null) body['payment_type_id'] = paymentTypeId;
    if (taxes != null) body['taxes'] = taxes;
    if (discounts != null) body['discounts'] = discounts;
    if (notes != null) body['notes'] = notes;
    if (items != null) body['items'] = items;

    final data = await _api.put('procurement/invoices/$invoiceId', body: body);
    return InvoicePurchase.fromJson(data);
  }

  Future<PaginatedResult<InvoicePurchase>> getInvoices({
    String? orderStatus,
    String? paymentStatus,
    int? storeId,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (orderStatus != null) params['order_status'] = orderStatus;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (storeId != null) params['store_id'] = storeId.toString();

    final body = await _api.getRaw('procurement/invoices', queryParams: params);
    final List<dynamic> invoicesJson = body['data'] ?? [];
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: invoicesJson.map((e) => InvoicePurchase.fromJson(e)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      perPage: meta['per_page'] ?? perPage,
      total: meta['total'] ?? 0,
    );
  }

  Future<PaginatedResult<PaymentReceipt>> getPaymentReceipts({
    int? invoiceId,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (invoiceId != null) params['invoice_id'] = invoiceId.toString();

    final body = await _api.getRaw('procurement/payment-receipts', queryParams: params);
    final List<dynamic> receiptsJson = body['data'] ?? [];
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: receiptsJson.map((e) => PaymentReceipt.fromJson(e)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      perPage: meta['per_page'] ?? perPage,
      total: meta['total'] ?? 0,
    );
  }

  Future<PaymentReceipt> getPaymentReceiptDetail(int id) async {
    final data = await _api.get('procurement/payment-receipts/$id');
    return PaymentReceipt.fromJson(data);
  }

  Future<PaymentReceipt> createPaymentReceipt({
    required List<int> invoiceIds,
    required int transferAmount,
    int? totalAmount,
    String? notes,
    File? image,
  }) async {
    final fields = <String, String>{};
    for (var id in invoiceIds) {
      fields['invoice_ids[]'] = id.toString();
    }
    fields['transfer_amount'] = transferAmount.toString();
    if (totalAmount != null) {
      fields['total_amount'] = totalAmount.toString();
    }
    if (notes != null) {
      fields['notes'] = notes;
    }
    if (image != null) {
      final path = await ImageUploadService.upload(image, directory: 'images/PaymentReceipt');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['image'] = path;
    }

    final data = await _api.multipart(
      method: 'POST',
      path: 'procurement/payment-receipts',
      fields: fields,
    );
    return PaymentReceipt.fromJson(data);
  }

  Future<Map<String, dynamic>> createFuelServicePaymentReceipt({
    required List<int> fuelServiceIds,
    required int transferAmount,
    int? totalAmount,
    String? notes,
    File? image,
  }) async {
    final fields = <String, String>{};
    for (var id in fuelServiceIds) {
      fields['fuel_service_ids[]'] = id.toString();
    }
    fields['transfer_amount'] = transferAmount.toString();
    if (totalAmount != null) {
      fields['total_amount'] = totalAmount.toString();
    }
    if (notes != null) {
      fields['notes'] = notes;
    }
    if (image != null) {
      final path = await ImageUploadService.upload(image, directory: 'images/PaymentReceipt');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      fields['image'] = path;
    }

    final data = await _api.multipart(
      method: 'POST',
      path: 'procurement/fuel-service-payment-receipts',
      fields: fields,
    );
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<InvoicePurchase> getInvoiceDetail(int id) async {
    final data = await _api.get('procurement/invoices/$id');
    return InvoicePurchase.fromJson(data);
  }

  Future<Map<String, dynamic>> getPaymentReceiptQris(int receiptId) async {
    final body = await _api.getRaw('procurement/payment-receipts/$receiptId/qris');
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat QRIS payment.');
    }
    return body['data'] as Map<String, dynamic>;
  }
}
