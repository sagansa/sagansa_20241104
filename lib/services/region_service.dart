import '../models/supplier_model.dart';
import 'api_client.dart';

/// Lookup wilayah berjenjang (Provinsi → Kota → Kecamatan → Kelurahan →
/// Kode Pos) dari endpoint `SupplierController`. Dipakai form konsumen
/// (DeliveryAddress) di fitur sales.
class RegionService {
  final ApiClient _api = ApiClient();

  Future<List<ProvinceModel>> getProvinces() async {
    final data = await _api.get('provinces');
    return (data as List<dynamic>)
        .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CityModel>> getCities(int provinceId) async {
    final data = await _api.get('cities',
        queryParams: {'province_id': '$provinceId'});
    return (data as List<dynamic>)
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DistrictModel>> getDistricts(int cityId) async {
    final data = await _api.get('districts',
        queryParams: {'city_id': '$cityId'});
    return (data as List<dynamic>)
        .map((e) => DistrictModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubdistrictModel>> getSubdistricts(int districtId) async {
    final data = await _api.get('subdistricts',
        queryParams: {'district_id': '$districtId'});
    return (data as List<dynamic>)
        .map((e) => SubdistrictModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PostalCodeModel>> getPostalCodes(int subdistrictId) async {
    final data = await _api.get('postal-codes',
        queryParams: {'subdistrict_id': '$subdistrictId'});
    return (data as List<dynamic>)
        .map((e) => PostalCodeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}