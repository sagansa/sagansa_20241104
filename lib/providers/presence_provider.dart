import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/presence_model.dart';
import '../services/presence_service.dart';

class PresenceProvider with ChangeNotifier {
  List<PresenceModel> _presences = [];

  List<PresenceModel> get presences => _presences;

  PresenceModel? _todayPresence;

  PresenceModel? get todayPresence => _todayPresence;

  void setTodayPresence(PresenceModel? presence) {
    _todayPresence = presence;
    notifyListeners();
  }

  Future<void> fetchPresences() async {
    try {
      developer.log('Starting fetchPresences...', name: 'PresenceProvider');
      final response = await PresenceService.getUserPresence();
      developer.log('Got response from service', name: 'PresenceProvider');

      // Parse the response - getUserPresence returns Map<String, dynamic>
      final List<dynamic> presencesData = response['data'] is List
          ? response['data'] as List
          : [];

      _presences =
          presencesData.map((json) => PresenceModel.fromJson(json)).toList();

      // Parse today's presence if available
      final todayData = response['today'];
      if (todayData != null && todayData is Map<String, dynamic>) {
        _todayPresence = PresenceModel.fromJson(todayData);
      } else {
        _todayPresence = null;
      }

      notifyListeners();
      developer.log(
        'Presences updated in provider: ${_presences.length} items',
        name: 'PresenceProvider',
      );
    } catch (e) {
      developer.log(
        'Error in fetchPresences: $e',
        name: 'PresenceProvider',
        error: e,
      );
      rethrow;
    }
  }
}