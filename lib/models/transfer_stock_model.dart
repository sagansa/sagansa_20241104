class TransferStockProduct {
  final int id;
  final String name;
  final String unitName;

  TransferStockProduct({
    required this.id,
    required this.name,
    required this.unitName,
  });

  factory TransferStockProduct.fromJson(Map<String, dynamic> json) {
    return TransferStockProduct(
      id: json['id'],
      name: json['name'] ?? '',
      unitName: json['unit'] != null ? json['unit']['unit'] : '',
    );
  }
}

class TransferStockModel {
  final int id;
  final String date;
  final int status;
  final String fromStoreName;
  final String toStoreName;
  final String sentByName;
  final String? receivedByName;
  final String? imageUrl;
  final String? notes;
  final List<ProductTransferStockModel> details;

  TransferStockModel({
    required this.id,
    required this.date,
    required this.status,
    required this.fromStoreName,
    required this.toStoreName,
    required this.sentByName,
    this.receivedByName,
    this.imageUrl,
    this.notes,
    required this.details,
  });

  factory TransferStockModel.fromJson(Map<String, dynamic> json) {
    final detailsList = json['product_transfer_stocks'] as List? ?? [];
    return TransferStockModel(
      id: json['id'],
      date: json['date'] ?? '',
      status: json['status'] ?? 1,
      fromStoreName: json['store_from'] != null
          ? json['store_from']['nickname'] ?? ''
          : '',
      toStoreName: json['store_to'] != null
          ? json['store_to']['nickname'] ?? ''
          : '',
      sentByName:
          json['sent_by'] != null ? json['sent_by']['name'] ?? '' : '',
      receivedByName:
          json['received_by'] != null ? json['received_by']['name'] ?? '' : null,
      imageUrl: json['image_url'],
      notes: json['notes'],
      details:
          detailsList.map((i) => ProductTransferStockModel.fromJson(i)).toList(),
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

class ProductTransferStockModel {
  final int id;
  final int productId;
  final double quantity;
  final String productName;
  final String unitName;

  ProductTransferStockModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.unitName,
  });

  factory ProductTransferStockModel.fromJson(Map<String, dynamic> json) {
    return ProductTransferStockModel(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      productName:
          json['product'] != null ? json['product']['name'] ?? '' : '',
      unitName: json['product'] != null && json['product']['unit'] != null
          ? json['product']['unit']['unit'] ?? ''
          : '',
    );
  }
}
