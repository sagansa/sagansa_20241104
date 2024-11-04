class Store {
  final int id;
  final String nickname;
  final double latitude;
  final double longitude;
  final double radius; // radius dalam meter untuk area yang diizinkan

  Store({
    required this.id,
    required this.nickname,
    required this.latitude,
    required this.longitude,
    this.radius = 100, // default radius 100 meter
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      nickname: json['nickname'] ?? '',
      latitude: double.parse(json['latitude']?.toString() ?? '0.0'),
      longitude: double.parse(json['longitude']?.toString() ?? '0.0'),
      radius: double.parse(json['radius']?.toString() ?? '100.0'),
    );
  }
}
