import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

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
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('도착정보 조회 실패: ${response.statusCode}');
    }

    return _parseArrivals(response.body);
  }

  List<ArrivalInfo> _parseArrivals(String xml) {
    final doc = XmlDocument.parse(xml);
    final resultCode = doc.findAllElements('resultCode').firstOrNull?.innerText;
    if (resultCode != null && resultCode != '0') {
      return [];
    }

    final items = doc.findAllElements('busArrivalList');
    final result = <ArrivalInfo>[];

    for (final el in items) {
      final routeId = el.findElements('routeId').firstOrNull?.innerText ?? '';
      final routeName = el.findElements('routeName').firstOrNull?.innerText ?? '';
      final predictTime1 = int.tryParse(
            el.findElements('predictTime1').firstOrNull?.innerText ?? '',
          ) ??
          -1;
      final locationNo1 = int.tryParse(
            el.findElements('locationNo1').firstOrNull?.innerText ?? '',
          ) ??
          0;
      final stationName1 = el.findElements('stationName1').firstOrNull?.innerText ?? '';
      final plateNo1 = el.findElements('plateNo1').firstOrNull?.innerText;

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

      // 두 번째 차량 (predictTime2) 도 별도 항목으로 추가
      final predictTime2 = int.tryParse(
            el.findElements('predictTime2').firstOrNull?.innerText ?? '',
          ) ??
          -1;
      if (predictTime2 > 0) {
        final locationNo2 = int.tryParse(
              el.findElements('locationNo2').firstOrNull?.innerText ?? '',
            ) ??
            0;
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
