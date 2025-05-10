class CustomerModel {
  final int id;
  final String name;
  final String? noTelp;
  final String? email;
  final String? address;

  CustomerModel({
    required this.id,
    required this.name,
    this.noTelp,
    this.email,
    this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      noTelp: json['no_telp'],
      email: json['email'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (noTelp != null) 'no_telp': noTelp,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
    };
  }
}
