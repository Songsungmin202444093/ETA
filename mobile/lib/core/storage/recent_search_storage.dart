import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchEntry {
  const RecentSearchEntry({required this.origin, required this.destination});

  final String origin;
  final String destination;

  Map<String, String> toJson() => {
        'origin': origin,
        'destination': destination,
      };

  factory RecentSearchEntry.fromJson(Map<String, dynamic> json) {
    return RecentSearchEntry(
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
    );
  }
}

class RecentSearchStorage {
  static const _storageKey = 'recent_search_entries';
  static const _maxEntries = 4;

  static Future<List<RecentSearchEntry>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final items = preferences.getStringList(_storageKey) ?? const [];

    return items
        .map((item) => RecentSearchEntry.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .where((entry) => entry.origin.isNotEmpty && entry.destination.isNotEmpty)
        .toList();
  }

  static Future<void> save(List<RecentSearchEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = entries
        .take(_maxEntries)
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();

    await preferences.setStringList(_storageKey, payload);
  }
}