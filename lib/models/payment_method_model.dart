class PaymentMethodResponse {
  final String status;
  final List<PaymentMethod> data;

  PaymentMethodResponse({
    required this.status,
    required this.data,
  });

  factory PaymentMethodResponse.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResponse(
      status: json['status'],
      data: (json['data'] as List)
          .map((item) => PaymentMethod.fromJson(item))
          .toList(),
    );
  }
}

class PaymentMethod {
  final int id;
  final String name;
  final String type;
  final String? image;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.image,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
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
