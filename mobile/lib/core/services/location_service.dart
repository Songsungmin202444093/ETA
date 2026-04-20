import 'package:geolocator/geolocator.dart';

enum LocationStatus { unknown, denied, deniedForever, granted }

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// 현재 권한 상태 확인
  Future<LocationStatus> checkStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationStatus.denied;

    final permission = await Geolocator.checkPermission();
    return _map(permission);
  }

  /// 권한 요청 (필요 시 시스템 다이얼로그 표시)
  Future<LocationStatus> requestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _map(permission);
  }

  /// 현재 위치 좌표 반환 (권한이 없으면 null)
  Future<Position?> getCurrentPosition() async {
    final status = await checkStatus();
    if (status != LocationStatus.granted) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  LocationStatus _map(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationStatus.granted;
      case LocationPermission.deniedForever:
        return LocationStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationStatus.denied;
    }
  }
}
