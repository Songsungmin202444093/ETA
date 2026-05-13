import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/bus_eta_models.dart';

class BusStopService {
  BusStopService._();
  static final BusStopService instance = BusStopService._();

  /// GPS 좌표 기반 반경 내 정류소 목록 조회
  Future<List<NearbyStation>> getNearbyStations(
    double lat,
    double lng, {
    int radius = AppConfig.defaultSearchRadius,
  }) async {
    final uri = Uri.https(
      'apis.data.go.kr',
      '/6410000/busstationservice/v2/getBusStationAroundListv2',
      {
        'serviceKey': AppConfig.gyeonggiApiKey,
        'x': lng.toStringAsFixed(6),
        'y': lat.toStringAsFixed(6),
        'radius': radius.toString(),
        'numOfRows': '20',
        'pageNo': '1',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    debugPrint('[API] station status=${response.statusCode} body=${response.body.substring(0, response.body.length.clamp(0, 400))}');

    if (response.statusCode != 200) {
      throw Exception('정류소 조회 실패: ${response.statusCode}');
    }

    final stations = _parseStations(response.body, lat, lng);
    if (stations.isEmpty) {
      debugPrint('[API] station empty → using mock data');
      return _mockStations(lat, lng);
    }
    return stations;
  }

  List<NearbyStation> _mockStations(double lat, double lng) {
    // API 키 미승인 시 개발용 목업 데이터
    return [
      NearbyStation(name: '수원역 버스환승센터', distanceMeters: 120, lines: const [], arrivals: const [], stationId: 'mock_1', latitude: lat + 0.001, longitude: lng + 0.001),
      NearbyStation(name: '수원역 북측', distanceMeters: 250, lines: const [], arrivals: const [], stationId: 'mock_2', latitude: lat - 0.001, longitude: lng + 0.002),
      NearbyStation(name: '수원시청', distanceMeters: 380, lines: const [], arrivals: const [], stationId: 'mock_3', latitude: lat + 0.002, longitude: lng - 0.001),
      NearbyStation(name: '팔달구청', distanceMeters: 450, lines: const [], arrivals: const [], stationId: 'mock_4', latitude: lat - 0.002, longitude: lng - 0.002),
    ];
  }

  List<NearbyStation> _parseStations(String body, double myLat, double myLng) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final msgHeader = data['response']?['msgHeader'] as Map<String, dynamic>?;
    final resultCode = msgHeader?['resultCode'];
    debugPrint('[API] station resultCode=$resultCode');
    if (resultCode != 0) return [];

    final rawList = data['response']?['msgBody']?['busStationAroundList'];
    if (rawList == null) return [];
    final items = rawList is List ? rawList : [rawList];

    return items.map((el) {
      final map = el as Map<String, dynamic>;
      final stationId = map['stationId']?.toString() ?? '';
      final name = map['stationName']?.toString() ?? '';
      final x = double.tryParse(map['x']?.toString() ?? '') ?? 0.0;
      final y = double.tryParse(map['y']?.toString() ?? '') ?? 0.0;
      final distanceMeters = _haversineMeters(myLat, myLng, y, x).round();
      return NearbyStation(
        name: name,
        distanceMeters: distanceMeters,
        lines: const [],
        arrivals: const [],
        stationId: stationId,
        latitude: y,
        longitude: x,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  /// Haversine 공식 기반 두 좌표 간 거리(미터)
  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lng2 - lng1) * math.pi / 180;
    final a = math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}
