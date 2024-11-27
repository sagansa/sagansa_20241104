class PaymentMethodResponse {
  final String status;
  final List<PaymentMethodModel> data;

  PaymentMethodResponse({
    required this.status,
    required this.data,
  });

  factory PaymentMethodResponse.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResponse(
      status: json['status'],
      data: (json['data'] as List)
          .map((item) => PaymentMethodModel.fromJson(item))
          .toList(),
    );
  }
}

class PaymentMethodModel {
  final int id;
  final String name;
  final String type;
  final String? image;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    this.image,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'image': image,
    };
  }
}
