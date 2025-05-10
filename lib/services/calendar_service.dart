import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calendar_model.dart';
import '../utils/constants.dart';

class CalendarService {
  final String? token;

  CalendarService({this.token});

  Future<CalendarModel> getCalendarData() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.calendar),
        headers: ApiConstants.headers(token),
      );

      if (response.statusCode == AppConstants.statusSuccess) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return CalendarModel.fromJson(jsonResponse);
      } else {
        throw Exception('Gagal mengambil data kalender');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
