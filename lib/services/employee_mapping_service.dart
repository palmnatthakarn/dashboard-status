import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

class EmployeeMappingService {
  static const String _storageKey = 'employee_name_mappings';
  static const String _knownEmployeesKey = 'known_employee_names';

  /// Get all mappings from local storage.
  static Future<Map<String, String>> getAllMappings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    dLog('Loading employee mappings from storage. Key: $_storageKey');

    if (jsonString == null) {
      dLog('No employee mappings found in storage.');
      return {};
    }

    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      dLog('Loaded ${decoded.length} employee mappings.');
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      dLog('Error decoding employee mappings JSON: $e', error: e);
      return {};
    }
  }

  /// Save a mapping for a specific employee.
  static Future<void> saveMapping(String username, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    final mappings = await getAllMappings();
    final cleanName = displayName.trim();

    if (cleanName.isEmpty) {
      mappings.remove(username);
      dLog('Removing employee mapping for: $username');
    } else {
      mappings[username] = cleanName;
      dLog('Saving employee mapping for: $username -> $cleanName');
    }

    final success = await prefs.setString(_storageKey, json.encode(mappings));
    if (success) {
      dLog('Successfully saved employee mappings.');
    } else {
      dLog('Failed to save employee mappings to SharedPreferences.');
    }
  }

  /// Get display name for a specific username.
  static Future<String> getDisplayName(String username) async {
    final mappings = await getAllMappings();
    return mappings[username] ?? username;
  }

  /// Remove a mapping.
  static Future<void> removeMapping(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final mappings = await getAllMappings()..remove(username);
    await prefs.setString(_storageKey, json.encode(mappings));
  }

  /// Clear all mappings and cached employee names.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_knownEmployeesKey);
  }

  /// Save a list of known employees from API.
  static Future<void> saveKnownEmployees(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKnown = await getKnownEmployees();
    final newSet = {...currentKnown, ...names.where((n) => n.isNotEmpty)};
    await prefs.setStringList(_knownEmployeesKey, newSet.toList()..sort());
  }

  /// Get all known employees from API cache.
  static Future<List<String>> getKnownEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_knownEmployeesKey) ?? [];
  }
}
