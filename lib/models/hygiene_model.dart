import '../services/image_service.dart';

class RoomModel {
  final int id;
  final String name;

  RoomModel({required this.id, required this.name});

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class HygieneRoomModel {
  final int id;
  final int roomId;
  final String? roomName;
  final String? image;
  String? get imageUrl => ImageService.buildUrl(image);
  final int? condition;
  final String? notes;

  HygieneRoomModel({
    required this.id,
    required this.roomId,
    this.roomName,
    this.image,
    this.condition,
    this.notes,
  });

  factory HygieneRoomModel.fromJson(Map<String, dynamic> json) {
    return HygieneRoomModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      roomName: json['room']?['name'] ?? json['room_name'],
      image: json['image'],
      condition: json['condition'],
      notes: json['notes'],
    );
  }

  String get conditionLabel {
    switch (condition) {
      case 1:
        return 'Bersih';
      case 2:
        return 'Perlu Perhatian';
      case 3:
        return 'Kotor';
      default:
        return '-';
    }
  }
}

class HygieneModel {
  final int id;
  final int storeId;
  final String? storeName;
  final int status;
  final String? notes;
  final List<HygieneRoomModel> rooms;
  final String createdAt;
  final String? createdByName;
  final String? approvedByName;

  HygieneModel({
    required this.id,
    required this.storeId,
    this.storeName,
    required this.status,
    this.notes,
    required this.rooms,
    required this.createdAt,
    this.createdByName,
    this.approvedByName,
  });

  factory HygieneModel.fromJson(Map<String, dynamic> json) {
    return HygieneModel(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      storeName: json['store']?['nickname'] ?? json['store_name'],
      status: json['status'] ?? 1,
      notes: json['notes'],
      rooms: (json['hygiene_of_rooms'] as List<dynamic>?)
              ?.map((e) => HygieneRoomModel.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
      createdByName: json['created_by']?['name'] ?? json['created_by_name'],
      approvedByName: json['approved_by']?['name'] ?? json['approved_by_name'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 1:
        return 'Menunggu';
      case 2:
        return 'Disetujui';
      case 3:
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }
}
