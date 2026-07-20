import '../models/applicant_detail_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    final data = await _api.get('users', queryParams: role != null ? {'role': role} : null);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<ApplicantDetail> getProfile() async {
    final data = await _api.get('profile');
    if (data == null) return ApplicantDetail();
    return ApplicantDetail.fromJson(data);
  }

  Future<ApplicantDetail> updateProfile(ApplicantDetail data) async {
    final result = await _api.put('profile', body: data.toJson());
    if (result == null) return ApplicantDetail();
    return ApplicantDetail.fromJson(result);
  }

  Future<Map<String, dynamic>> getAdminProfiles({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    return await _api.getRaw('admin/profile', queryParams: queryParams);
  }

  Future<Map<String, dynamic>> getAdminProfileDetail(dynamic profileId) async {
    final data = await _api.get('admin/profile/$profileId');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setProfileStatus(dynamic profileId, String status) async {
    final data = await _api.put('admin/profile/$profileId/status', body: {'status': status});
    return data as Map<String, dynamic>;
  }
}
