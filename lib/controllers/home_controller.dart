import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/leave_service.dart';
import '../services/presence_service.dart';
import '../utils/constants.dart';

class HomeController {
  final BuildContext context;

  HomeController(this.context);

  Future<Map<String, String>> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final loginDataString = prefs.getString(AppConstants.loginDataKey);
    if (loginDataString != null) {
      final loginData = json.decode(loginDataString);
      final userData = loginData['data']['user'];
      return {
        'userName': userData['name'],
        'companyName': userData['company']['name'],
      };
    }
    throw Exception('User data not found');
  }

  Future<Map<String, dynamic>> loadPresenceData() async {
    try {
      final data = await PresenceService.getUserPresence();
      return {
        'todayPresence': data['today'],
        'previousPresences': data['previous'],
      };
    } catch (e) {
      throw Exception('Gagal memuat data: $e');
    }
  }

  Future<bool> checkActiveLeave() async {
    try {
      final leaveService = LeaveService();
      final leaves = await leaveService.getLeaves();
      final now = DateTime.now();

      return leaves.any((leave) =>
          leave.status == AppConstants.leaveStatusApproved &&
          leave.fromDate.isBefore(now) &&
          leave.untilDate.isAfter(now));
    } catch (e) {
      print('Error checking active leave: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return await authProvider.logout();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Map<String, String> splitDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return {
      'date':
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
      'time':
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
    };
  }
}
