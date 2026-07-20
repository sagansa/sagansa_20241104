import '../models/asset_issue_model.dart';
import 'api_client.dart';

/// Service untuk list & menutup issue aset.
class AssetIssueService {
  final ApiClient _api = ApiClient();

  Future<List<AssetIssueModel>> getIssues({
    int? assetId,
    int? status, // 1=open, 2=closed. Default backend = open.
    int? storeId,
    int? severity,
  }) async {
    final query = <String, String>{};
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (status != null) query['status'] = status.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (severity != null) query['severity'] = severity.toString();

    final data = await _api.get('asset-issues', queryParams: query) as List;
    return data
        .map((e) => AssetIssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getIssuesPaged({
    int page = 1,
    int perPage = 20,
    int? assetId,
    int? status,
    int? storeId,
    int? severity,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (status != null) query['status'] = status.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (severity != null) query['severity'] = severity.toString();

    final json = await _api.getRaw('asset-issues', queryParams: query);
    final List data = json['data'] ?? [];
    final meta = json['pagination'] ?? {};
    final hasMore = (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1);
    return {
      'data': data
          .map((e) => AssetIssueModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'has_more': hasMore,
    };
  }

  Future<void> closeIssue(int id, {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    await _api.post('asset-issues/$id/close', body: body);
  }
}
