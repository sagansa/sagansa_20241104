import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/calendar_model.dart';
import '../utils/constants.dart';

class CalendarService {
  final String? token;

  CalendarService({this.token});

  Future<CalendarModel> getCalendarData() async {
    debugPrint('Fetching calendar data from: ${ApiConstants.calendar}');
    debugPrint(
        'Using token: ${token != null ? 'Token available' : 'No token'}');

    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse(ApiConstants.calendar),
            headers: ApiConstants.headers(token),
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException catch (e) {
      debugPrint('Calendar service network error: $e');
      throw Exception('Koneksi gagal: periksa jaringan Anda');
    } on TimeoutException catch (e) {
      debugPrint('Calendar service timeout: $e');
      throw Exception('Permintaan timeout: server terlalu lama merespons');
    } catch (e) {
      debugPrint('Calendar service request error: $e');
      rethrow;
    }

    debugPrint('Calendar API response status: ${response.statusCode}');
    debugPrint('Calendar API response body: ${response.body}');

    if (response.statusCode == AppConstants.statusSuccess) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return CalendarModel.fromJson(jsonResponse);
      } catch (e) {
        debugPrint('Calendar service JSON parse error: $e');
        throw Exception('Format data kalender tidak valid');
      }
    } else if (response.statusCode == AppConstants.statusUnauthorized) {
      throw Exception('Token tidak valid atau sudah expired');
    } else {
      throw Exception(
          'Gagal mengambil data kalender (Status: ${response.statusCode})');
    }
  }
}