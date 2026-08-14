class StoreConsumptionProduct {
  final int id;
  final String name;
  final String unitName;

  StoreConsumptionProduct({
    required this.id,
    required this.name,
    required this.unitName,
  });

  factory StoreConsumptionProduct.fromJson(Map<String, dynamic> json) {
    return StoreConsumptionProduct(
      id: json['id'],
      name: json['name'] ?? '',
      unitName: json['unit'] != null ? json['unit']['unit'] : '',
    );
  }
}

class StoreConsumptionModel {
  final int id;
  final int storeId;
  final String date;
  final int status;
  final String storeName;
  final String createdByName;
  final List<ProductStoreConsumptionModel> details;

  StoreConsumptionModel({
    required this.id,
    required this.storeId,
    required this.date,
    required this.status,
    required this.storeName,
    required this.createdByName,
    required this.details,
  });

  factory StoreConsumptionModel.fromJson(Map<String, dynamic> json) {
    final detailsList = json['detail_stock_cards'] as List? ?? [];
    return StoreConsumptionModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      storeId: json['store_id'] is int
          ? json['store_id']
          : int.tryParse(json['store_id']?.toString() ?? '0') ?? 0,
      date: json['date'] ?? '',
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '1') ?? 1,
      storeName: json['store'] != null
          ? (json['store']['nickname'] ?? '')
          : '',
      createdByName: (json['user'] != null ? json['user']['name'] : null) ??
          '',
      details: detailsList
          .map((i) => ProductStoreConsumptionModel.fromJson(i))
          .toList(),
    );
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Belum Diperiksa';
      case 2:
        return 'Valid';
      case 3:
        return 'Diperbaiki';
      case 4:
        return 'Periksa Ulang';
      default:
        return 'Unknown';
    }
  }
}

class ProductStoreConsumptionModel {
  final int id;
  final int productId;
  final double quantity;
  final String productName;
  final String unitName;

  ProductStoreConsumptionModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.unitName,
  });

  factory ProductStoreConsumptionModel.fromJson(Map<String, dynamic> json) {
    return ProductStoreConsumptionModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      productName:
          json['product'] != null ? json['product']['name'] ?? '' : '',
      unitName: json['product'] != null && json['product']['unit'] != null
          ? json['product']['unit']['unit'] ?? ''
          : '',
    );
  }
}