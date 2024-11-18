class ProductResponse {
  final String status;
  final int cartCount;
  final ProductData data;

  ProductResponse({
    required this.status,
    required this.cartCount,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      status: json['status'] ?? '',
      cartCount: json['cart_count'] ?? 0,
      data: ProductData.fromJson(json['data']),
    );
  }
}

class ProductData {
  final List<ProductModel> products;

  ProductData({required this.products});

  factory ProductData.fromJson(Map<String, dynamic> json) {
    var productsList = json['products'] as List;
    return ProductData(
      products:
          productsList.map((item) => ProductModel.fromJson(item)).toList(),
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final int? categoryId;
  final String? image;
  final String? status;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.categoryId,
    this.image,
    this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      sku: json['sku'],
      barcode: json['barcode'],
      categoryId: json['category_id'],
      image: json['image'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'image': image,
      'status': status,
    };
  }
}
