import '../services/image_service.dart';

/// Satu baris item produk dalam SalesOrderEmployee.
class SalesOrderEmployeeItem {
  final int id;
  final int productId;
  final String productName;
  final String? productUnit;
  final int quantity;
  final int unitPrice;
  final int subtotalPrice;

  SalesOrderEmployeeItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productUnit,
    required this.quantity,
    required this.unitPrice,
    required this.subtotalPrice,
  });

  factory SalesOrderEmployeeItem.fromJson(Map<String, dynamic> j) {
    final product = j['product'] as Map<String, dynamic>? ?? {};
    return SalesOrderEmployeeItem(
      id: (j['id'] ?? 0) as int,
      productId: (j['product_id'] ?? 0) as int,
      productName: product['name'] as String? ?? '',
      productUnit: product['unit']?['unit'] as String?,
      quantity: (j['quantity'] ?? 0) as int,
      unitPrice: (j['unit_price'] ?? 0) as int,
      subtotalPrice: (j['subtotal_price'] ?? 0) as int,
    );
  }
}

/// Sales order kategori employee (for=2).
class SalesOrderEmployeeModel {
  final int id;
  final int storeId;
  final String? storeName;
  final DateTime? deliveryDate;
  final int? deliveryAddressId;
  final String? deliveryAddressName;
  final int? transferToAccountId;
  final String? transferToAccountName;
  final String? imagePayment;
  String? get imagePaymentUrl => ImageService.buildUrl(imagePayment);
  final int paymentStatus; // 1..4
  final int deliveryStatus;
  final int orderedById;
  final String? orderedByName;
  final String? notes;
  final int totalPrice;
  final List<SalesOrderEmployeeItem> items;
  final String? createdAt;

  SalesOrderEmployeeModel({
    required this.id,
    required this.storeId,
    this.storeName,
    this.deliveryDate,
    this.deliveryAddressId,
    this.deliveryAddressName,
    this.transferToAccountId,
    this.transferToAccountName,
    this.imagePayment,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.orderedById,
    this.orderedByName,
    this.notes,
    required this.totalPrice,
    required this.items,
    this.createdAt,
  });

  factory SalesOrderEmployeeModel.fromJson(Map<String, dynamic> j) {
    final store = j['store'] as Map<String, dynamic>?;
    final orderedBy = j['ordered_by'] as Map<String, dynamic>?;
    final transferToAccount = j['transfer_to_account'] as Map<String, dynamic>?;
    final deliveryAddress = j['delivery_address'] as Map<String, dynamic>?;

    final rawDate = j['delivery_date']?.toString();
    DateTime? date;
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        date = DateTime.parse(rawDate.contains('T') ? rawDate : '${rawDate}T00:00:00');
      } catch (_) {
        date = null;
      }
    }

    final rawItems = (j['detail_sales_orders'] as List<dynamic>?)
            ?.map((e) => SalesOrderEmployeeItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SalesOrderEmployeeModel(
      id: (j['id'] ?? 0) as int,
      storeId: (j['store_id'] ?? 0) as int,
      storeName: store?['nickname'] as String?,
      deliveryDate: date,
      deliveryAddressId: j['delivery_address_id'] as int?,
      deliveryAddressName: deliveryAddress?['delivery_address_name'] as String?,
      transferToAccountId: j['transfer_to_account_id'] as int?,
      transferToAccountName: transferToAccount?['transfer_name'] as String?,
      imagePayment: j['image_payment'] as String?,
      paymentStatus: (j['payment_status'] ?? 1) as int,
      deliveryStatus: (j['delivery_status'] ?? 1) as int,
      orderedById: (j['ordered_by_id'] ?? 0) as int,
      orderedByName: orderedBy?['name'] as String?,
      notes: j['notes'] as String?,
      totalPrice: (j['total_price'] ?? 0) as int,
      items: rawItems,
      createdAt: j['created_at']?.toString(),
    );
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 1:
        return 'Belum Diperiksa';
      case 2:
        return 'Valid';
      case 3:
        return 'Tidak Valid';
      case 4:
        return 'Periksa Ulang';
      default:
        return '-';
    }
  }

  /// Indikator apakah order masih boleh diubah/dihapus oleh sales pemilik.
  bool get isLocked => paymentStatus == 2;
}
