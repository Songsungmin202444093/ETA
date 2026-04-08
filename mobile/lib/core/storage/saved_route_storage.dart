import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_data.dart';
import '../models/bus_eta_models.dart';

class SavedRouteStorage {
  static const _storageKey = 'saved_route_entries';

  static Future<List<SavedRoute>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final items = preferences.getStringList(_storageKey) ?? const [];

    if (items.isEmpty) {
      return DemoData.savedRoutes;
    }

    return items
        .map((item) => SavedRoute.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .where(
          (route) =>
              route.id.isNotEmpty &&
              route.name.isNotEmpty &&
              route.origin.isNotEmpty &&
              route.destination.isNotEmpty,
        )
        .toList();
  }

  static Future<void> save(List<SavedRoute> routes) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = routes.map((route) => jsonEncode(route.toJson())).toList();

    await preferences.setStringList(_storageKey, payload);
  }
}