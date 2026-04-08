import '../models/bus_eta_models.dart';

class DemoData {
  static const nearbyStations = <NearbyStation>[
    NearbyStation(
      name: '인하대후문',
      distanceMeters: 180,
      lines: ['5-1', '13', '515'],
      arrivals: [
        ArrivalInfo(line: '5-1', arrivalMinutes: 3, remainingStops: 2, direction: '주안역'),
        ArrivalInfo(line: '13', arrivalMinutes: 7, remainingStops: 4, direction: '송도신도시'),
      ],
    ),
    NearbyStation(
      name: '용현사거리',
      distanceMeters: 320,
      lines: ['27', '46', '82'],
      arrivals: [
        ArrivalInfo(line: '27', arrivalMinutes: 2, remainingStops: 1, direction: '인천터미널'),
        ArrivalInfo(line: '82', arrivalMinutes: 10, remainingStops: 6, direction: '송내역'),
      ],
    ),
    NearbyStation(
      name: '인하대역 2번 출구',
      distanceMeters: 540,
      lines: ['수인분당선'],
      arrivals: [
        ArrivalInfo(line: '급행', arrivalMinutes: 6, remainingStops: 1, direction: '왕십리'),
      ],
    ),
  ];

  static const recommendedPlans = <TripPlan>[
    TripPlan(
      title: '학교 가는 길',
      origin: '주안역',
      destination: '인하대학교',
      departureTime: '08:10',
      arrivalTime: '08:39',
      totalMinutes: 29,
      walkingMinutes: 6,
      transferCount: 0,
      riskLevel: '안전',
      recommendation: '가장 단순한 직행 경로입니다.',
      transferHint: '인하대역에서 4분 안에 환승하면 여유가 있습니다.',
      warning: '5-1번이 2분 이상 지연되면 다음 차량 탑승을 권장합니다.',
      segments: [
        RouteSegment(mode: '도보', label: '주안역 2번 출구 이동', durationMinutes: 4, detail: '횡단보도 1회 포함'),
        RouteSegment(mode: '버스', label: '5-1 탑승', durationMinutes: 18, detail: '인하대후문 하차, 6개 정류장 이동'),
        RouteSegment(mode: '도보', label: '인하대학교 정문까지 이동', durationMinutes: 7, detail: '완만한 오르막 구간'),
      ],
    ),
    TripPlan(
      title: '알바 가는 길',
      origin: '인하대학교',
      destination: '송도 컨벤시아',
      departureTime: '17:20',
      arrivalTime: '17:58',
      totalMinutes: 38,
      walkingMinutes: 8,
      transferCount: 1,
      riskLevel: '주의',
      recommendation: '퇴근 시간대엔 여유 시간을 꼭 확인해야 합니다.',
      transferHint: '수인분당선 하차 후 버스 환승까지 5분 정도 확보됩니다.',
      warning: '퇴근 시간대라 30-1번 배차 간격이 흔들릴 수 있습니다.',
      segments: [
        RouteSegment(mode: '도보', label: '인하대역 이동', durationMinutes: 5, detail: '후문 기준 최단 경로'),
        RouteSegment(mode: '지하철', label: '수인분당선 탑승', durationMinutes: 14, detail: '원인재역 하차'),
        RouteSegment(mode: '버스', label: '82번 환승', durationMinutes: 13, detail: '컨벤시아 앞 하차'),
        RouteSegment(mode: '도보', label: '목적지 이동', durationMinutes: 6, detail: '도보 420m'),
      ],
    ),
  ];

  static const savedRoutes = <SavedRoute>[
    SavedRoute(
      id: 'commute-campus',
      name: '통학 루트',
      origin: '주안역',
      destination: '인하대학교',
      nextDeparture: '08:10 출발',
      summary: '총 29분, 버스 1회 탑승',
    ),
    SavedRoute(
      id: 'parttime-songdo',
      name: '알바 루트',
      origin: '인하대학교',
      destination: '송도 컨벤시아',
      nextDeparture: '17:20 출발',
      summary: '총 38분, 지하철 1회 + 버스 1회',
    ),
    SavedRoute(
      id: 'home-bupyeong',
      name: '집 가는 길',
      origin: '인하대학교',
      destination: '부평역',
      nextDeparture: '22:05 출발',
      summary: '총 42분, 막차 체크 필요',
    ),
  ];

  static List<TripPlan> routeCandidates({
    required String origin,
    required String destination,
  }) {
    final from = origin.trim().isEmpty ? '현재 위치' : origin.trim();
    final to = destination.trim().isEmpty ? '목적지' : destination.trim();

    return [
      TripPlan(
        title: '최단 경로',
        origin: from,
        destination: to,
        departureTime: '지금 출발',
        arrivalTime: '47분 후 도착',
        totalMinutes: 47,
        walkingMinutes: 9,
        transferCount: 1,
        riskLevel: '위험',
        recommendation: '총 시간은 가장 짧지만 환승 여유가 2분뿐입니다.',
        transferHint: '첫 번째 버스 하차 후 다음 버스까지 2분 여유라 놓칠 가능성이 큽니다.',
        warning: '버스-버스 환승이라 배차가 조금만 흔들려도 다음 차량을 기다릴 수 있습니다.',
        segments: const [
          RouteSegment(mode: '도보', label: '출발지 주변 정류장 이동', durationMinutes: 6, detail: '도보 430m'),
          RouteSegment(mode: '버스', label: '27번 탑승', durationMinutes: 19, detail: 'A정류장까지 7개 정류장 이동'),
          RouteSegment(mode: '버스', label: '82번 환승', durationMinutes: 16, detail: 'B역 방향으로 이동'),
          RouteSegment(mode: '도보', label: '목적지까지 이동', durationMinutes: 6, detail: '도보 390m'),
        ],
      ),
      TripPlan(
        title: '안정 경로',
        origin: from,
        destination: to,
        departureTime: '지금 출발',
        arrivalTime: '52분 후 도착',
        totalMinutes: 52,
        walkingMinutes: 11,
        transferCount: 1,
        riskLevel: '안전',
        recommendation: '총 시간은 조금 늘어나지만 환승 여유가 8분으로 안정적입니다.',
        transferHint: '첫 번째 버스에서 내려 역까지 이동 후 지하철 탑승까지 8분 여유가 있습니다.',
        warning: '막차 시간대만 아니라면 가장 무난한 경로입니다.',
        segments: const [
          RouteSegment(mode: '도보', label: '가까운 정류장 이동', durationMinutes: 5, detail: '도보 300m'),
          RouteSegment(mode: '버스', label: '5-1번 탑승', durationMinutes: 17, detail: 'A역 환승 정류장 하차'),
          RouteSegment(mode: '지하철', label: '수인분당선 탑승', durationMinutes: 21, detail: 'B역 하차'),
          RouteSegment(mode: '도보', label: '목적지까지 이동', durationMinutes: 9, detail: '출구에서 620m 이동'),
        ],
      ),
      TripPlan(
        title: '환승 적은 경로',
        origin: from,
        destination: to,
        departureTime: '지금 출발',
        arrivalTime: '58분 후 도착',
        totalMinutes: 58,
        walkingMinutes: 13,
        transferCount: 0,
        riskLevel: '안전',
        recommendation: '한 번에 가는 대신 시간이 더 걸리지만 놓칠 위험이 가장 적습니다.',
        transferHint: '직행 버스만 이용하므로 중간 환승 판단이 필요 없습니다.',
        warning: '배차 간격이 긴 노선이라 첫 차를 놓치면 대기 시간이 늘 수 있습니다.',
        segments: const [
          RouteSegment(mode: '도보', label: '직행 정류장 이동', durationMinutes: 8, detail: '도보 540m'),
          RouteSegment(mode: '버스', label: '512번 직행 탑승', durationMinutes: 38, detail: '중간 환승 없이 종점 근처 하차'),
          RouteSegment(mode: '도보', label: '목적지까지 이동', durationMinutes: 12, detail: '도보 810m'),
        ],
      ),
    ];
  }
}