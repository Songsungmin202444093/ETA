/// 경기도 공공데이터 API 설정
class AppConfig {
  AppConfig._();

  static const gyeonggiApiKey =
      '6764224e528100181b665cb430aa73827b5a24627867e44077e012d695bae4c5';

  static const stationServiceBaseUrl =
      'https://apis.data.go.kr/6410000/busstationservice/v2';

  static const arrivalServiceBaseUrl =
      'https://apis.data.go.kr/6410000/busarrivalservice/v2';

  static const locationServiceBaseUrl =
      'https://apis.data.go.kr/6410000/buslocationservice/v2';

  /// 주변 정류소 검색 기본 반경 (미터)
  static const defaultSearchRadius = 500;
}
