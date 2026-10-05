import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static const String _firstLaunchDateKey = 'first_launch_date';

  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        return AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (e) {
      debugPrint('Error clearing settings: $e');
    }
  }

  /// Get the first launch date, or set it if not already set
  Future<DateTime> getFirstLaunchDate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_firstLaunchDateKey);
    
    if (storedDate != null) {
      return DateTime.parse(storedDate);
    }
    
    // First time - store current date
    final now = DateTime.now();
    await prefs.setString(_firstLaunchDateKey, now.toIso8601String());
    return now;
  }

  /// Check if user has been using the app for at least the specified number of days
  Future<bool> hasUsedAppForDays(int days) async {
    final firstLaunchDate = await getFirstLaunchDate();
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunchDate).inDays;
    return daysSinceFirstLaunch >= days;
  }
}
