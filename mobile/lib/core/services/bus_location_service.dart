import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/bus_eta_models.dart';

class BusLocationService {
  BusLocationService._();
  static final BusLocationService instance = BusLocationService._();

  /// 노선 ID 기반 실시간 버스 위치 목록 조회
  Future<List<BusLocation>> getBusLocations(String routeId, {String routeName = ''}) async {
    final uri = Uri.https(
      'apis.data.go.kr',
      '/6410000/buslocationservice/v2/getBusLocationListv2',
      {
        'serviceKey': AppConfig.gyeonggiApiKey,
        'routeId': routeId,
        'numOfRows': '100',
        'pageNo': '1',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('버스 위치 조회 실패: ${response.statusCode}');
    }

    return _parseLocations(response.body, routeId, routeName);
  }

  /// 여러 노선의 위치 정보를 한 번에 조회
  Future<List<BusLocation>> getBusLocationsForRoutes(
    List<ArrivalInfo> arrivals,
  ) async {
    final routeIds = arrivals
        .map((a) => a.routeId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (routeIds.isEmpty) return [];

    final futures = routeIds.map((id) {
      final routeName = arrivals
          .firstWhere((a) => a.routeId == id, orElse: () => const ArrivalInfo(
                line: '',
                arrivalMinutes: 0,
                remainingStops: 0,
                direction: '',
              ))
          .line;
      return getBusLocations(id, routeName: routeName).catchError((_) => <BusLocation>[]);
    });

    final results = await Future.wait(futures);
    return results.expand((list) => list).toList();
  }

  List<BusLocation> _parseLocations(String body, String routeId, String routeName) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final resultCode = data['response']?['msgHeader']?['resultCode'];
    if (resultCode != 0) return [];

    final rawList = data['response']?['msgBody']?['busLocationList'];
    if (rawList == null) return [];
    final items = rawList is List ? rawList : [rawList];

    return items.map((el) {
      final map = el as Map<String, dynamic>;
      final x = double.tryParse(map['x']?.toString() ?? '');
      final y = double.tryParse(map['y']?.toString() ?? '');
      if (x == null || y == null || x == 0 || y == 0) return null;
      final stationSeq = int.tryParse(map['stationSeq']?.toString() ?? '') ?? 0;
      final plateNo = map['plateNo']?.toString();
      final remainSeat = int.tryParse(map['remainSeatCnt']?.toString() ?? '');
      return BusLocation(
        routeId: routeId,
        routeName: routeName,
        latitude: y,
        longitude: x,
        stationSeq: stationSeq,
        plateNo: plateNo,
        remainSeatCnt: remainSeat,
      );
    }).whereType<BusLocation>().toList();
  }
}
