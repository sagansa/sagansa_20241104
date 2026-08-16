/// Calon konsumen (DeliveryAddress) milik user sales.
///
/// Mirip SupplierModel: membawa relasi wilayah (provinsi/kota/kecamatan/
/// kelurahan/kode pos) agar response API self-contained untuk list & form.
class DeliveryAddressModel {
  final int id;
  final String name;
  final String recipientName;
  final String recipientTelpNo;
  final String address;
  final int? provinceId;
  final String? provinceName;
  final int? cityId;
  final String? cityName;
  final int? districtId;
  final String? districtName;
  final int? subdistrictId;
  final String? subdistrictName;
  final int? postalCodeId;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  DeliveryAddressModel({
    required this.id,
    required this.name,
    required this.recipientName,
    required this.recipientTelpNo,
    required this.address,
    this.provinceId,
    this.provinceName,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    this.subdistrictId,
    this.subdistrictName,
    this.postalCodeId,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) => v?.toString();

    int? asInt(dynamic v) {
      if (v == null) return null;
      return v is int ? v : int.tryParse(v.toString());
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      return v is num ? v.toDouble() : double.tryParse(v.toString());
    }

    final province = j['province'] as Map<String, dynamic>?;
    final city = j['city'] as Map<String, dynamic>?;
    final district = j['district'] as Map<String, dynamic>?;
    final subdistrict = j['subdistrict'] as Map<String, dynamic>?;
    final postalCode = j['postal_code'] as Map<String, dynamic>?;

    return DeliveryAddressModel(
      id: asInt(j['id']) ?? 0,
      name: s(j['name']) ?? '',
      recipientName: s(j['recipient_name']) ?? '',
      recipientTelpNo: s(j['recipient_telp_no']) ?? '',
      address: s(j['address']) ?? '',
      provinceId: asInt(j['province_id']),
      provinceName: s(province?['name']),
      cityId: asInt(j['city_id']),
      cityName: s(city?['name']),
      districtId: asInt(j['district_id']),
      districtName: s(district?['name']),
      subdistrictId: asInt(j['subdistrict_id']),
      subdistrictName: s(subdistrict?['name']),
      postalCodeId: asInt(j['postal_code_id']),
      postalCode: s(postalCode?['postal_code']),
      latitude: asDouble(j['latitude']),
      longitude: asDouble(j['longitude']),
    );
  }

  /// Label ringkas untuk dropdown/picker (name, fallback recipient_name).
  String get displayName => name.isNotEmpty ? name : recipientName;

  /// Ringkasan baris-baris untuk tampilan list.
  String get summaryLines => [
        if (recipientName.isNotEmpty && recipientName != name)
          recipientName,
        if (recipientTelpNo.isNotEmpty) recipientTelpNo,
        if (address.isNotEmpty) address,
        [
          subdistrictName,
          districtName,
          cityName,
          provinceName,
        ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
        if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
      ].join('\n');
}