class PrinterBluetooth {
  final String name;
  final String address;

  PrinterBluetooth({required this.name, required this.address});

  factory PrinterBluetooth.fromMap(Map<String, dynamic> map) {
    return PrinterBluetooth(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
    );
  }
}
