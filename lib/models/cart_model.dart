class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? variantName;
  final int variantPrice;
  final List<String> modifiers;
  final String? notes;
  final int quantity;
  final int unitPrice;
  final int subtotal;

  CartItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        productId = json['product_id'] ?? 0,
        productName = json['product_name'] ?? '',
        variantName = json['variant_name'],
        variantPrice = json['variant_price'] ?? 0,
        modifiers = List<String>.from(json['modifiers'] ?? []),
        notes = json['notes'],
        quantity = json['quantity'] ?? 1,
        unitPrice = json['unit_price'] ?? 0,
        subtotal = json['subtotal'] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'variant_name': variantName,
      'variant_price': variantPrice,
      'modifiers': modifiers,
      'notes': notes,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class Cart {
  final List<CartItem> items;
  final int totalAmount;

  Cart.fromJson(Map<String, dynamic> json)
      : items = (json['items'] as List?)
                ?.map((item) => CartItem.fromJson(item))
                .toList() ??
            [],
        totalAmount = json['total_amount'] ?? 0;
}
