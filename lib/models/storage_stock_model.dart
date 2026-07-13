class StorageStockProduct {
  final int id;
  final String name;
  final String unitName;

  StorageStockProduct({
    required this.id,
    required this.name,
    required this.unitName,
  });

  factory StorageStockProduct.fromJson(Map<String, dynamic> json) {
    return StorageStockProduct(
      id: json['id'],
      name: json['name'] ?? '',
      unitName: json['unit'] != null ? json['unit']['unit'] : '',
    );
  }
}

class StorageStockModel {
  final int id;
  final int storeId;
  final String date;
  final int status;
  final String storeName;
  final String createdByName;
  final List<ProductStorageStockModel> details;

  StorageStockModel({
    required this.id,
    required this.storeId,
    required this.date,
    required this.status,
    required this.storeName,
    required this.createdByName,
    required this.details,
  });

  factory StorageStockModel.fromJson(Map<String, dynamic> json) {
    var detailsList = json['product_storage_stocks'] as List? ?? [];
    return StorageStockModel(
      id: json['id'],
      storeId: json['store_id'],
      date: json['date'] ?? '',
      status: json['status'] ?? 1,
      storeName: json['store'] != null ? json['store']['nickname'] ?? '' : '',
      createdByName: json['created_by'] != null ? json['created_by']['name'] ?? '' : '',
      details: detailsList.map((i) => ProductStorageStockModel.fromJson(i)).toList(),
    );
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Draft / Pending';
      case 2:
        return 'Valid / Done';
      default:
        return 'Unknown';
    }
  }
}

class ProductStorageStockModel {
  final int id;
  final int productId;
  final double quantity;
  final String productName;
  final String unitName;

  ProductStorageStockModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.unitName,
  });

  factory ProductStorageStockModel.fromJson(Map<String, dynamic> json) {
    return ProductStorageStockModel(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      productName: json['product'] != null ? json['product']['name'] ?? '' : '',
      unitName: json['product'] != null && json['product']['unit'] != null 
          ? json['product']['unit']['unit'] ?? '' 
          : '',
    );
  }
}
