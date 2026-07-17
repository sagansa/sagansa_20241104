import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/applicant_detail_model.dart';

class UserService {
  Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    var url = '${ApiConstants.baseUrl}/users';
    if (role != null) {
      url += '?role=$role';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load users');
    }
  }

  Future<ApplicantDetail> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return ApplicantDetail.fromJson(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load profile');
    }
  }

  Future<ApplicantDetail> updateProfile(ApplicantDetail data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data.toJson()),
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return ApplicantDetail.fromJson(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> getAdminProfiles({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    var url = '${ApiConstants.baseUrl}/admin/profiles?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load admin profiles');
    }
  }

  Future<Map<String, dynamic>> getAdminProfileDetail(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/profiles/$profileId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load profile detail');
    }
  }

  Future<void> setProfileStatus(String profileId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/profiles/$profileId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': status}),
    );

    final jsonResponse = json.decode(response.body);
    if (response.statusCode != 200 || jsonResponse['success'] != true) {
      throw Exception(jsonResponse['message'] ?? 'Failed to update profile status');
    }
  }
}
