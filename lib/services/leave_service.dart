import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/leave_model.dart';
import '../utils/constants.dart';

class LeaveService {
  Future<List<LeaveModel>> getLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse(ApiConstants.leaves)
        .replace(queryParameters: {'per_page': '1000'});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> leavesJson =
          data['data'] is List ? data['data'] : [];
      return leavesJson.map((json) => LeaveModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load leaves');
    }
  }

  Future<Map<String, dynamic>> getLeavesPaged({int page = 1, int perPage = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse(ApiConstants.leaves)
        .replace(queryParameters: {'page': page.toString(), 'per_page': perPage.toString()});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      if (body['success'] == true || body['status'] == 'success') {
        final List<dynamic> data = body['data'] ?? [];
        final meta = body['pagination'] ?? {};
        final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
        return {
          'data': data.map((e) => LeaveModel.fromJson(e)).toList(),
          'has_more': hasMore,
        };
      }
      throw Exception(body['message'] ?? 'Gagal memuat data cuti');
    }
    throw Exception('Gagal memuat data cuti');
  }

  Future<bool> submitLeave({
    required int reason,
    required DateTime fromDate,
    required DateTime untilDate,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse(ApiConstants.leaves),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'reason': reason,
        'from_date': fromDate.toIso8601String(),
        'until_date': untilDate.toIso8601String(),
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to submit leave');
    }
  }

  Future<void> updateLeave(
    int leaveId,
    String reason,
    DateTime fromDate,
    DateTime untilDate,
    String notes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('${ApiConstants.leaves}/$leaveId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'reason': int.parse(reason),
        'from_date': fromDate.toIso8601String(),
        'until_date': untilDate.toIso8601String(),
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Gagal mengupdate cuti');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengupdate cuti');
    }
  }

  // Admin methods

  /// Get all leaves (admin sees all staff leaves)
  Future<Map<String, dynamic>> getAdminLeaves({
    int page = 1,
    int perPage = 20,
    String? status,
    int? userId,
    String? search,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null) params['status'] = status;
    if (userId != null) params['user_id'] = userId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse(ApiConstants.adminLeaves)
        .replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return {
        'data': data['data']['data'] ?? [],
        'meta': {
          'current_page': data['data']['current_page'],
          'last_page': data['data']['last_page'],
          'total': data['data']['total'],
        },
      };
    } else {
      throw Exception('Gagal memuat data cuti');
    }
  }

  /// Approve a leave request (admin only)
  Future<bool> approveLeave(int leaveId, {String? notes}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('${ApiConstants.adminLeaves}/$leaveId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'notes': notes ?? 'Permintaan cuti disetujui',
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] == true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menyetujui cuti');
    }
  }

  /// Reject a leave request (admin only)
  Future<bool> rejectLeave(int leaveId, {String? rejectNote}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('${ApiConstants.adminLeaves}/$leaveId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'reject_note': rejectNote ?? 'Permintaan cuti ditolak',
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] == true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menolak cuti');
    }
  }
}
