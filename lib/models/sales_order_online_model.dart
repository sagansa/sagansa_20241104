/// Model pendukung form "Tambah Sales Order Online" (admin).
class SalesOrderOnlineProduct {
  final int id;
  final String name;
  final String unit;

  SalesOrderOnlineProduct({
    required this.id,
    required this.name,
    required this.unit,
  });

  factory SalesOrderOnlineProduct.fromJson(Map<String, dynamic> json) {
    return SalesOrderOnlineProduct(
      id: json['id'],
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
    );
  }
}

class OnlineShopProvider {
  final int id;
  final String name;

  OnlineShopProvider({required this.id, required this.name});

  factory OnlineShopProvider.fromJson(Map<String, dynamic> json) {
    return OnlineShopProvider(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

class DeliveryServiceOption {
  final int id;
  final String name;

  DeliveryServiceOption({required this.id, required this.name});

  factory DeliveryServiceOption.fromJson(Map<String, dynamic> json) {
    return DeliveryServiceOption(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

/// Item baris repeater di form (produk + quantity + unit price).
class SalesOrderItemRequest {
  final int productId;
  final int quantity;
  final int unitPrice;

  SalesOrderItemRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  int get subtotal => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}
