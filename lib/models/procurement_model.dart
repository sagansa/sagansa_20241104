import '../services/image_service.dart';

class ProcurementProduct {
  final int id;
  final String name;
  final int? unitId;
  final int? paymentTypeId;
  final String unitName;

  ProcurementProduct({
    required this.id,
    required this.name,
    this.unitId,
    this.paymentTypeId,
    required this.unitName,
  });

  factory ProcurementProduct.fromJson(Map<String, dynamic> json) {
    return ProcurementProduct(
      id: json['id'],
      name: json['name'] ?? '',
      unitId: json['unit_id'],
      paymentTypeId: json['payment_type_id'],
      unitName: json['unit']?['unit'] ?? '',
    );
  }
}

class DetailRequestItem {
  final int id;
  final int productId;
  final double quantityPlan;
  final String status;
  final int? paymentTypeId;
  final String productName;
  final String unitName;

  DetailRequestItem({
    required this.id,
    required this.productId,
    required this.quantityPlan,
    required this.status,
    this.paymentTypeId,
    required this.productName,
    required this.unitName,
  });

  String get statusText {
    switch (status) {
      case '1':
        return 'Process';
      case '2':
        return 'Done';
      case '3':
        return 'Rejected';
      case '4':
        return 'Approved';
      case '5':
        return 'Not Valid';
      case '6':
        return 'Not Used';
      default:
        return 'Unknown';
    }
  }

  factory DetailRequestItem.fromJson(Map<String, dynamic> json) {
    return DetailRequestItem(
      id: json['id'],
      productId: json['product_id'],
      quantityPlan: double.tryParse(json['quantity_plan']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '1',
      paymentTypeId: json['payment_type_id'],
      productName: json['product']?['name'] ?? '',
      unitName: json['product']?['unit']?['unit'] ?? '',
    );
  }
}

class DetailInvoiceItem {
  final int id;
  final int invoicePurchaseId;
  final int? detailRequestId;
  final double quantityProduct;
  final double? quantityInvoice;
  final double subtotalInvoice;
  final String? status;
  final String productName;
  final String unitName;

  DetailInvoiceItem({
    required this.id,
    required this.invoicePurchaseId,
    this.detailRequestId,
    required this.quantityProduct,
    this.quantityInvoice,
    required this.subtotalInvoice,
    this.status,
    required this.productName,
    required this.unitName,
  });

  double get unitPrice {
    if (quantityProduct == 0) return 0;
    return subtotalInvoice / quantityProduct;
  }

  String get statusText {
    switch (status) {
      case '3':
        return 'Need Adjustment';
      default:
        return 'Processed';
    }
  }

  factory DetailInvoiceItem.fromJson(Map<String, dynamic> json) {
    final detailRequest = json['detail_request'] as Map<String, dynamic>?;
    String productName = '';
    String unitName = '';

    if (detailRequest != null) {
      final product = detailRequest['product'] as Map<String, dynamic>?;
      if (product != null) {
        productName = product['name'] ?? '';
        final unit = product['unit'] as Map<String, dynamic>?;
        unitName = unit?['unit'] ?? '';
      }
    }

    return DetailInvoiceItem(
      id: json['id'],
      invoicePurchaseId: json['invoice_purchase_id'],
      detailRequestId: json['detail_request_id'],
      quantityProduct: double.tryParse(json['quantity_product']?.toString() ?? '0') ?? 0.0,
      quantityInvoice: json['quantity_invoice'] != null
          ? double.tryParse(json['quantity_invoice'].toString())
          : null,
      subtotalInvoice: double.tryParse(json['subtotal_invoice']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString(),
      productName: productName,
      unitName: unitName,
    );
  }
}

class InvoicePurchase {
  final int id;
  final int? paymentTypeId;
  final int storeId;
  final int? supplierId;
  final String date;
  final int taxes;
  final int discounts;
  final int totalPrice;
  final String? notes;
  final int createdById;
  final String paymentStatus;
  final String orderStatus;
  final String storeName;
  final String? supplierName;
  final String createdByName;
  final List<DetailInvoiceItem> detailInvoices;
  final String? image;
  String? get imageUrl => ImageService.buildUrl(image);

  InvoicePurchase({
    required this.id,
    this.paymentTypeId,
    required this.storeId,
    this.supplierId,
    required this.date,
    this.taxes = 0,
    this.discounts = 0,
    this.totalPrice = 0,
    this.notes,
    required this.createdById,
    this.paymentStatus = '1',
    this.orderStatus = '1',
    required this.storeName,
    this.supplierName,
    this.createdByName = '',
    this.detailInvoices = const [],
    this.image,
  });

  String get paymentStatusText {
    switch (paymentStatus) {
      case '1':
        return 'Belum Dibayar';
      case '2':
        return 'Sudah Dibayar';
      case '3':
        return 'Tidak Valid';
      default:
        return 'Unknown';
    }
  }

  String get orderStatusText {
    switch (orderStatus) {
      case '1':
        return 'Belum Diterima';
      case '2':
        return 'Sudah Diterima';
      case '3':
        return 'Dikembalikan';
      default:
        return 'Unknown';
    }
  }

  String get paymentTypeText {
    return paymentTypeId == 2 ? 'Tunai' : 'Transfer';
  }

  factory InvoicePurchase.fromJson(Map<String, dynamic> json) {
    var list = json['detail_invoices'] as List? ?? [];
    List<DetailInvoiceItem> items = list.map((i) => DetailInvoiceItem.fromJson(i)).toList();

    return InvoicePurchase(
      id: json['id'],
      paymentTypeId: json['payment_type_id'],
      storeId: json['store_id'],
      supplierId: json['supplier_id'],
      date: json['date'] ?? '',
      taxes: int.tryParse(json['taxes']?.toString() ?? '0') ?? 0,
      discounts: int.tryParse(json['discounts']?.toString() ?? '0') ?? 0,
      totalPrice: int.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
      createdById: json['created_by_id'],
      paymentStatus: json['payment_status']?.toString() ?? '1',
      orderStatus: json['order_status']?.toString() ?? '1',
      storeName: json['store']?['nickname'] ?? json['store']?['name'] ?? 'Toko',
      supplierName: json['supplier']?['name'],
      createdByName: json['created_by']?['name'] ?? '',
      detailInvoices: items,
      image: json['image'],
    );
  }
}

class RequestPurchase {
  final int id;
  final int storeId;
  final String storeName;
  final String date;
  final int userId;
  final String userName;
  final List<DetailRequestItem> detailRequests;

  RequestPurchase({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.date,
    required this.userId,
    required this.userName,
    required this.detailRequests,
  });

  String get overallStatusText {
    if (detailRequests.isEmpty) return 'No Items';
    if (detailRequests.any((item) => item.status == '1')) return 'Pending Approval';
    if (detailRequests.every((item) => item.status == '3')) return 'Rejected';
    if (detailRequests.any((item) => item.status == '4')) return 'Partially Approved';
    if (detailRequests.every((item) => item.status == '2')) return 'Done';
    return 'Processed';
  }

  factory RequestPurchase.fromJson(Map<String, dynamic> json) {
    var list = json['detail_requests'] as List? ?? [];
    List<DetailRequestItem> items = list.map((i) => DetailRequestItem.fromJson(i)).toList();

    return RequestPurchase(
      id: json['id'],
      storeId: json['store_id'],
      storeName: json['store']?['nickname'] ?? json['store']?['name'] ?? 'Toko',
      date: json['date'] ?? '',
      userId: json['user_id'],
      userName: json['user']?['name'] ?? '',
      detailRequests: items,
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class PaymentReceipt {
  final int id;
  final String paymentFor;
  final int totalAmount;
  final int transferAmount;
  final int? supplierId;
  final String? notes;
  final String? image;
  String? get imageUrl => ImageService.buildUrl(image);
  final String? imageAdjust;
  String? get imageAdjustUrl => ImageService.buildUrl(imageAdjust);
  final String createdAt;
  final String? supplierName;
  final List<InvoicePurchase> invoicePurchases;

  PaymentReceipt({
    required this.id,
    this.paymentFor = '3',
    this.totalAmount = 0,
    this.transferAmount = 0,
    this.supplierId,
    this.notes,
    this.image,
    this.imageAdjust,
    required this.createdAt,
    this.supplierName,
    this.invoicePurchases = const [],
  });

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    var list = json['invoice_purchases'] as List? ?? [];
    List<InvoicePurchase> invoices = list.map((i) => InvoicePurchase.fromJson(i)).toList();

    return PaymentReceipt(
      id: json['id'],
      paymentFor: json['payment_for']?.toString() ?? '3',
      totalAmount: int.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      transferAmount: int.tryParse(json['transfer_amount']?.toString() ?? '0') ?? 0,
      supplierId: json['supplier_id'],
      notes: json['notes'],
      image: json['image'],
      imageAdjust: json['image_adjust'],
      createdAt: json['created_at'] ?? '',
      supplierName: json['supplier']?['name'],
      invoicePurchases: invoices,
    );
  }
}
