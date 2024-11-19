class ProductResponse {
  final String status;
  final int cartCount;
  final List<ProductModel> data;

  ProductResponse({
    required this.status,
    required this.cartCount,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      status: json['status'] ?? '',
      cartCount: json['cart_count'] is String
          ? int.parse(json['cart_count'].toString())
          : json['cart_count'] ?? 0,
      data: (json['data'] as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'cart_count': cartCount,
      'data': data.map((product) => product.toJson()).toList(),
    };
  }
}

class ProductModel {
  final int id;
  final String name;
  final String? image;

  ProductModel({
    required this.id,
    required this.name,
    this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}

class CategoryModel {
  final int id;
  final String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
    );
  }
}
