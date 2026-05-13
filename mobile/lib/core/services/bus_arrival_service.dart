import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/bus_eta_models.dart';

class BusArrivalService {
  BusArrivalService._();
  static final BusArrivalService instance = BusArrivalService._();

  /// 정류소 ID 기반 실시간 버스 도착정보 목록 조회
  Future<List<ArrivalInfo>> getArrivalList(String stationId) async {
    final uri = Uri.https(
      'apis.data.go.kr',
      '/6410000/busarrivalservice/v2/getBusArrivalListv2',
      {
        'serviceKey': AppConfig.gyeonggiApiKey,
        'stationId': stationId,
        'numOfRows': '30',
        'pageNo': '1',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('도착정보 조회 실패: ${response.statusCode}');
    }

    return _parseArrivals(response.body);
  }

  List<ArrivalInfo> _parseArrivals(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final resultCode = data['response']?['msgHeader']?['resultCode'];
    if (resultCode != 0) return [];

    final rawList = data['response']?['msgBody']?['busArrivalList'];
    if (rawList == null) return [];
    final items = rawList is List ? rawList : [rawList];

    final result = <ArrivalInfo>[];
    for (final el in items) {
      final map = el as Map<String, dynamic>;
      final routeId = map['routeId']?.toString() ?? '';
      final routeName = map['routeName']?.toString() ?? '';
      final predictTime1 = int.tryParse(map['predictTime1']?.toString() ?? '') ?? -1;
      final locationNo1 = int.tryParse(map['locationNo1']?.toString() ?? '') ?? 0;
      final stationName1 = map['stationName1']?.toString() ?? '';
      final plateNo1 = map['plateNo1']?.toString();

      if (routeName.isNotEmpty) {
        result.add(ArrivalInfo(
          line: routeName,
          arrivalMinutes: predictTime1 >= 0 ? predictTime1 : 0,
          remainingStops: locationNo1,
          direction: stationName1,
          routeId: routeId,
          plateNo: plateNo1,
        ));
      }

      final predictTime2 = int.tryParse(map['predictTime2']?.toString() ?? '') ?? -1;
      if (predictTime2 > 0) {
        final locationNo2 = int.tryParse(map['locationNo2']?.toString() ?? '') ?? 0;
        result.add(ArrivalInfo(
          line: routeName,
          arrivalMinutes: predictTime2,
          remainingStops: locationNo2,
          direction: stationName1,
          routeId: routeId,
        ));
      }
    }

    result.sort((a, b) => a.arrivalMinutes.compareTo(b.arrivalMinutes));
    return result;
  }
}
