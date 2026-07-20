import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

class ApiClient {
  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Sends a GET request to the specified endpoint path.
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    AppLogger.debug('ApiClient GET: $uri');
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// Deteksi response sukses dari backend yang **inkonsisten**:
  /// - Sebagian controller pakai `'success' => true`
  /// - Sebagian controller (Leave, Readiness, Presence, Hygiene, Location,
  ///   AdminTrackLocation) pakai `'status' => 'success'`
  /// Keduanya dianggap sukses agar legacy controller tetap kompatibel.
  bool _isSuccess(Map<String, dynamic> json) =>
      json['success'] == true || json['status'] == 'success';

  /// GET yang langsung return `List<T>`.
  ///
  /// Memanggil [get] lalu decode setiap elemen via [fromJson].
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final data = await get(path, queryParams: queryParams);
    final list = data is List ? data : const <dynamic>[];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET yang return single object `T`.
  Future<T> getObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final data = await get(path, queryParams: queryParams);
    return fromJson(data as Map<String, dynamic>);
  }

  /// Sama seperti [get], tapi mengembalikan SELURUH body JSON (termasuk
  /// key `pagination`/`meta`) agar pemanggil bisa membaca metadata paginasi.
  Future<Map<String, dynamic>> getRaw(String path,
      {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    AppLogger.debug('ApiClient GET (raw): $uri');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) return json;
      throw Exception('Format respons tidak dikenali.');
    }

    final json = jsonDecode(response.body);
    final errors = json['errors'];
    if (errors != null && errors is Map) {
      final message = errors.values.expand((e) => e as List).join(', ');
      throw Exception(message);
    }

    throw Exception(json['message'] ??
        'Terjadi kesalahan pada server (Status ${response.statusCode}).');
  }

  /// Sends a POST request to the specified endpoint path.
  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    AppLogger.debug('ApiClient POST: $uri');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// POST yang return single object `T`.
  Future<T> postObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    dynamic body,
  }) async {
    final data = await post(path, body: body);
    return fromJson(data as Map<String, dynamic>);
  }

  /// Sama seperti [post], tapi mengembalikan SELURUH body JSON agar
  /// pemanggil bisa membaca field di luar `data`.
  Future<Map<String, dynamic>> postRaw(String path, {dynamic body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    AppLogger.debug('ApiClient POST (raw): $uri');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) return json;
      throw Exception('Format respons tidak dikenali.');
    }

    final json = jsonDecode(response.body);
    final errors = json['errors'];
    if (errors != null && errors is Map) {
      final message = errors.values.expand((e) => e as List).join(', ');
      throw Exception(message);
    }

    throw Exception(json['message'] ??
        'Terjadi kesalahan pada server (Status ${response.statusCode}).');
  }

  /// Sends a PUT request to the specified endpoint path.
  Future<dynamic> put(String path, {dynamic body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    AppLogger.debug('ApiClient PUT: $uri');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT yang return single object `T`.
  Future<T> putObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    dynamic body,
  }) async {
    final data = await put(path, body: body);
    return fromJson(data as Map<String, dynamic>);
  }

  /// Sends a DELETE request to the specified endpoint path.
  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    AppLogger.debug('ApiClient DELETE: $uri');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// Sends a multipart request (e.g. for uploads).
  Future<dynamic> multipart({
    required String method,
    required String path,
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/$path');
    AppLogger.debug('ApiClient Multipart $method: $uri');

    final request = http.MultipartRequest(method, uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields.addAll(fields);
    if (files != null) {
      request.files.addAll(files);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    AppLogger.debug('ApiClient Response (${response.statusCode}): '
        '${AppLogger.preview(response.body)}');
    final json = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json is Map<String, dynamic> && _isSuccess(json)) {
        return json['data'];
      }
    }

    // Handle Laravel validation errors or similar custom maps
    final errors = json['errors'];
    if (errors != null && errors is Map) {
      final message = errors.values.expand((e) => e as List).join(', ');
      throw Exception(message);
    }

    throw Exception(json['message'] ?? 'Terjadi kesalahan pada server (Status ${response.statusCode}).');
  }
}
