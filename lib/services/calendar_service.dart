import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/calendar_model.dart';
import 'api_client.dart';

class CalendarService {
  final ApiClient _api = ApiClient();

  Future<CalendarModel> getCalendarData() async {
    debugPrint('Fetching calendar data');

    try {
      final data = await _api.get('calendar');
      return CalendarModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Calendar service error: $e');
      rethrow;
    }
  }
}
