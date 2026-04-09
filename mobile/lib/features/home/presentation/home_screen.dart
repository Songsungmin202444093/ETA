import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';
import '../../../shared/widgets/surface_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenRoute,
    required this.onLoadSearch,
    required this.savedRoutes,
  });

  final ValueChanged<TripPlan> onOpenRoute;
  final ValueChanged<SearchPair> onLoadSearch;
  final List<SavedRoute> savedRoutes;

  List<TripPlan> get _featuredPlans => DemoData.routeCandidates(
        origin: '우리집',
        destination: '인하대학교',
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Text('BusETA', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '출발지와 도착지만으로 총 이동 시간, 환승 위험도, 추천 경로를 한 번에 확인하세요.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF163B59), Color(0xFF2C8C99), Color(0xFF63C5AE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '환승 여유 시간 계산',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '버스, 지하철, 도보 조합을 자동으로 비교해 가장 빠른 경로와 가장 안정적인 경로를 같이 보여줍니다.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _QuickBadge(label: '실시간 ETA'),
                  _QuickBadge(label: '환승 여유 계산'),
                  _QuickBadge(label: 'A→B 자동 추천'),
                  _QuickBadge(label: '저장 경로'),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: () => onOpenRoute(DemoData.recommendedPlans.first),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF163B59),
                ),
                child: const Text('대표 경로 바로 보기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SurfaceSection(
          title: '추천 경로 한눈에',
          subtitle: '검색에 들어가기 전에도 빠른 경로와 안정 경로를 바로 비교할 수 있습니다.',
          child: Column(
            children: _featuredPlans
                .take(2)
                .map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RouteHighlightCard(
                      plan: plan,
                      onTap: () => onOpenRoute(plan),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        SurfaceSection(
          title: '주변 정류장',
          subtitle: 'GPS 기반으로 가까운 정류장을 우선 표시합니다.',
          trailing: TextButton(onPressed: () {}, child: const Text('전체 보기')),
          child: Column(
            children: DemoData.nearbyStations
                .map(
                  (station) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StationCard(station: station),
                  ),
                )
                .toList(),
          ),
        ),
        if (savedRoutes.any((r) => r.isPinned)) ...[
          const SizedBox(height: 18),
          SurfaceSection(
            title: '즐겨찾기',
            subtitle: '핀 고정한 경로입니다. 저장 탭에서 고정을 관리할 수 있습니다.',
            child: Column(
              children: savedRoutes
                  .where((r) => r.isPinned)
                  .map((route) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HomeSavedRouteCard(
                          route: route,
                          onOpenRoute: onOpenRoute,
                          onLoadSearch: onLoadSearch,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 18),
        SurfaceSection(
          title: '저장된 경로',
          subtitle: '최근 검색과 달리 직접 관리하는 북마크 경로입니다. 이름 변경과 삭제는 저장 탭에서 합니다.',
          child: Column(
            children: savedRoutes.where((r) => !r.isPinned).isEmpty
                ? const [_EmptySavedRouteCard()]
                : savedRoutes
                    .where((r) => !r.isPinned)
                    .map((route) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HomeSavedRouteCard(
                            route: route,
                            onOpenRoute: onOpenRoute,
                            onLoadSearch: onLoadSearch,
                          ),
                        ))
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class _HomeSavedRouteCard extends StatelessWidget {
  const _HomeSavedRouteCard({
    required this.route,
    required this.onOpenRoute,
    required this.onLoadSearch,
  });

  final SavedRoute route;
  final ValueChanged<TripPlan> onOpenRoute;
  final ValueChanged<SearchPair> onLoadSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = DemoData.routeCandidates(
      origin: route.origin,
      destination: route.destination,
    ).first;

    final riskAccent = switch (plan.riskLevel) {
      '여유' => const Color(0xFF1F8F63),
      '보통' => const Color(0xFFF28F3B),
      _ => const Color(0xFFD64545),
    };
    final riskBg = switch (plan.riskLevel) {
      '여유' => const Color(0xFFF5FBF7),
      '보통' => const Color(0xFFFFF9F2),
      _ => const Color(0xFFFFF4F4),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: route.isPinned ? const Color(0xFFF0F8FF) : riskBg,
        borderRadius: BorderRadius.circular(22),
        border: route.isPinned
            ? Border.all(
                color: const Color(0xFF2C8C99).withValues(alpha: 0.35),
                width: 1.5)
            : Border(left: BorderSide(color: riskAccent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: route.isPinned ? const Color(0xFF2C8C99) : null,
                child: Icon(
                  route.isPinned ? Icons.push_pin_rounded : Icons.bookmark_outline,
                  color: route.isPinned ? Colors.white : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('${route.origin} → ${route.destination}'),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => onOpenRoute(plan),
                child: const Text('열기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: route.summary),
              _InfoChip(label: route.nextDeparture),
              _RiskChip(level: plan.riskLevel),
              _InfoChip(label: '환승 ${plan.transferCount}회'),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => onLoadSearch(
                SearchPair(origin: route.origin, destination: route.destination),
              ),
              icon: const Icon(Icons.search_rounded),
              label: const Text('검색에 불러오기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedRouteCard extends StatelessWidget {
  const _EmptySavedRouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text('저장된 경로가 없습니다. 저장 탭에서 발표용 경로를 다시 관리할 수 있습니다.'),
    );
  }
}

class _QuickBadge extends StatelessWidget {
  const _QuickBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station});

  final NearbyStation station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${station.distanceMeters}m · ${station.lines.join(' · ')}'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: station.arrivals
                .map(
                  (arrival) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${arrival.line} · ${arrival.arrivalMinutes}분 · ${arrival.remainingStops}정거장 전',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RouteHighlightCard extends StatelessWidget {
  const _RouteHighlightCard({required this.plan, required this.onTap});

  final TripPlan plan;
  final VoidCallback onTap;

  List<RouteSegment> get _transportSegments =>
      plan.segments.where((segment) => segment.mode != '도보').toList();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('${plan.totalMinutes}분'),
              ],
            ),
            const SizedBox(height: 6),
            Text('${plan.origin} → ${plan.destination}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RiskChip(level: plan.riskLevel),
                _InfoChip(label: '환승 ${plan.transferCount}회'),
                _InfoChip(label: '도보 ${plan.walkingMinutes}분'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _transportSegments.length; index++) ...[
                  _ModeBadge(mode: _transportSegments[index].mode),
                  if (index != _transportSegments.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 16),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(plan.recommendation),
          ],
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      '여유' => const Color(0xFF1F8F63),
      '보통' => const Color(0xFFF28F3B),
      _ => const Color(0xFFD64545),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(level, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      '버스' => Icons.directions_bus_rounded,
      '지하철' => Icons.train_rounded,
      _ => Icons.directions_walk_rounded,
    };

    final color = switch (mode) {
      '버스' => const Color(0xFF163B59),
      '지하철' => const Color(0xFF2C8C99),
      _ => const Color(0xFF6A7785),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(mode, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}