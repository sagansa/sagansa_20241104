class ProductResponse {
  final String status;
  final int cartCount;
  final ProductDetailModel data;

  ProductResponse({
    required this.status,
    required this.cartCount,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      status: json['status'],
      cartCount: json['cart_count'] ?? 0,
      data: ProductDetailModel.fromJson(json['data']),
    );
  }
}

class ProductDetailModel {
  final int id;
  final String name;
  final String? image;
  final List<Variant> variants;
  final List<Modifier> modifiers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDetailModel({
    required this.id,
    required this.name,
    this.image,
    required this.variants,
    required this.modifiers,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      variants: (json['variants'] as List?)
              ?.map((v) => Variant.fromJson(v))
              .toList() ??
          [],
      modifiers: (json['modifiers'] as List?)
              ?.map((m) => Modifier.fromJson(m))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class Variant {
  final int id;
  final String name;
  final int price;

  Variant({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'],
      name: json['name'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}

class Modifier {
  final int id;
  final String name;
  final List<ModifierDetail> details;

  Modifier({
    required this.id,
    required this.name,
    required this.details,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'],
      name: json['name'],
      details: (json['details'] as List)
          .map((d) => ModifierDetail.fromJson(d))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}

class ModifierDetail {
  final int id;
  final String name;
  final int price;
  final String? status;

  ModifierDetail({
    required this.id,
    required this.name,
    required this.price,
    this.status,
  });

  factory ModifierDetail.fromJson(Map<String, dynamic> json) {
    return ModifierDetail(
      id: json['id'],
      name: json['name'],
      price: json['price'] is String ? int.parse(json['price']) : json['price'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'status': status,
    };
  }
}
