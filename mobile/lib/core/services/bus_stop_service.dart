import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../config/app_config.dart';
import '../models/bus_eta_models.dart';

class BusStopService {
  BusStopService._();
  static final BusStopService instance = BusStopService._();

  /// GPS 좌표 기반 반경 내 정류소 목록 조회
  /// [lng] 경도(x), [lat] 위도(y), [radius] 반경(m, 최대 2000)
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
        'stationX': lng.toString(),
        'stationY': lat.toString(),
        'radius': radius.toString(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('정류소 조회 실패: ${response.statusCode}');
    }

    return _parseStations(response.body, lat, lng);
  }

  List<NearbyStation> _parseStations(String xml, double myLat, double myLng) {
    final doc = XmlDocument.parse(xml);
    final resultCode = doc.findAllElements('resultCode').firstOrNull?.innerText;
    if (resultCode != null && resultCode != '0') {
      return [];
    }

    final items = doc.findAllElements('busStationAroundList');
    return items.map((el) {
      final stationId = el.findElements('stationId').firstOrNull?.innerText ?? '';
      final name = el.findElements('stationName').firstOrNull?.innerText ?? '';
      final x = double.tryParse(el.findElements('x').firstOrNull?.innerText ?? '') ?? 0.0;
      final y = double.tryParse(el.findElements('y').firstOrNull?.innerText ?? '') ?? 0.0;

      final distanceMeters = _haversineMeters(myLat, myLng, y, x).round();

      return NearbyStation(
        name: name,
        distanceMeters: distanceMeters,
        lines: const [],   // 노선 목록은 도착정보 API 로 채움
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
