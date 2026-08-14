import '../services/image_service.dart';

class ReadinessModel {
  final int id;
  final int? storeId;
  final String? storeName;
  final String? createdByName;
  final String createdAt;
  final String? imageSelfie;
  final String? leftHand;
  final String? rightHand;
  final int? status;

  ReadinessModel({
    required this.id,
    this.storeId,
    this.storeName,
    this.createdByName,
    required this.createdAt,
    this.imageSelfie,
    this.leftHand,
    this.rightHand,
    this.status,
  });

  String? get selfieUrl => ImageService.buildUrl(imageSelfie);
  String? get leftHandUrl => ImageService.buildUrl(leftHand);
  String? get rightHandUrl => ImageService.buildUrl(rightHand);

  String get statusLabel => switch (status) {
        1 => 'Belum Diperiksa',
        2 => 'Sudah Diperiksa',
        _ => 'Tidak Diketahui',
      };

  ReadinessModel copyWith({int? status}) => ReadinessModel(
        id: id,
        storeId: storeId,
        storeName: storeName,
        createdByName: createdByName,
        createdAt: createdAt,
        imageSelfie: imageSelfie,
        leftHand: leftHand,
        rightHand: rightHand,
        status: status ?? this.status,
      );

  factory ReadinessModel.fromJson(Map<String, dynamic> json) {
    return ReadinessModel(
      id: json['id'] ?? 0,
      storeId: json['store_id'],
      storeName: json['store']?['nickname'] ?? json['store_name'],
      createdByName: json['created_by']?['name'] ?? json['created_by_name'],
      createdAt: json['created_at'] ?? json['date'] ?? '',
      imageSelfie: json['image_selfie'],
      leftHand: json['left_hand'],
      rightHand: json['right_hand'],
      status: json['status'],
    );
  }
}
