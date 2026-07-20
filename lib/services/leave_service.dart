import '../models/leave_model.dart';
import 'api_client.dart';

class LeaveService {
  final ApiClient _api = ApiClient();

  Future<List<LeaveModel>> getLeaves() async {
    final data = await _api.get(
      'leaves',
      queryParams: {'per_page': '1000'},
    );
    final List<dynamic> leavesJson = data is List ? data : [];
    return leavesJson.map((json) => LeaveModel.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getLeavesPaged({int page = 1, int perPage = 20}) async {
    final body = await _api.getRaw(
      'leaves',
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
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

  Future<bool> submitLeave({
    required int reason,
    required DateTime fromDate,
    required DateTime untilDate,
    String? notes,
  }) async {
    await _api.post(
      'leaves',
      body: {
        'reason': reason,
        'from_date': fromDate.toIso8601String(),
        'until_date': untilDate.toIso8601String(),
        'notes': notes,
      },
    );
    return true;
  }

  Future<void> updateLeave(
    int leaveId,
    String reason,
    DateTime fromDate,
    DateTime untilDate,
    String notes,
  ) async {
    await _api.put(
      'leaves/$leaveId',
      body: {
        'reason': int.parse(reason),
        'from_date': fromDate.toIso8601String(),
        'until_date': untilDate.toIso8601String(),
        'notes': notes,
      },
    );
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
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null) params['status'] = status;
    if (userId != null) params['user_id'] = userId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final data = await _api.getRaw('admin/leaves', queryParams: params);
    return {
      'data': data['data']['data'] ?? [],
      'meta': {
        'current_page': data['data']['current_page'],
        'last_page': data['data']['last_page'],
        'total': data['data']['total'],
      },
    };
  }

  /// Approve a leave request (admin only)
  Future<bool> approveLeave(int leaveId, {String? notes}) async {
    await _api.post(
      'admin/leaves/$leaveId/approve',
      body: {
        'notes': notes ?? 'Permintaan cuti disetujui',
      },
    );
    return true;
  }

  /// Reject a leave request (admin only)
  Future<bool> rejectLeave(int leaveId, {String? rejectNote}) async {
    await _api.post(
      'admin/leaves/$leaveId/reject',
      body: {
        'reject_note': rejectNote ?? 'Permintaan cuti ditolak',
      },
    );
    return true;
  }
}
