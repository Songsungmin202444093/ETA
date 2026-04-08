import 'package:flutter/material.dart';

import '../../../core/models/bus_eta_models.dart';

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key, required this.plan});

  final TripPlan plan;

  List<RouteSegment> get _transportSegments =>
      plan.segments.where((segment) => segment.mode != '도보').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = switch (plan.riskLevel) {
      '안전' => const Color(0xFF1F8F63),
      '주의' => const Color(0xFFF28F3B),
      _ => const Color(0xFFD64545),
    };

    return Scaffold(
      appBar: AppBar(title: Text(plan.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF163B59), Color(0xFF2C8C99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.origin} → ${plan.destination}',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatChip(label: '총 소요', value: '${plan.totalMinutes}분'),
                      const SizedBox(width: 10),
                      _StatChip(label: '도보', value: '${plan.walkingMinutes}분'),
                      const SizedBox(width: 10),
                      _StatChip(label: '환승', value: '${plan.transferCount}회'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${plan.departureTime} 출발 · ${plan.arrivalTime} 도착',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < _transportSegments.length; index++) ...[
                        _TransportBadge(mode: _transportSegments[index].mode),
                        if (index != _transportSegments.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          plan.riskLevel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(plan.recommendation)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('환승 판단', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(plan.transferHint, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF28F3B)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(plan.warning)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('구간별 상세', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                children: [
                  for (var index = 0; index < plan.segments.length; index++)
                    _TimelineItem(
                      segment: plan.segments[index],
                      isLast: index == plan.segments.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TransportBadge extends StatelessWidget {
  const _TransportBadge({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      '버스' => Icons.directions_bus_rounded,
      '지하철' => Icons.train_rounded,
      _ => Icons.directions_walk_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(mode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.segment, required this.isLast});

  final RouteSegment segment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (segment.mode) {
      '버스' => const Color(0xFF163B59),
      '지하철' => const Color(0xFF2C8C99),
      _ => const Color(0xFF6A7785),
    };

    final icon = switch (segment.mode) {
      '버스' => Icons.directions_bus_rounded,
      '지하철' => Icons.train_rounded,
      _ => Icons.directions_walk_rounded,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 70,
                    color: color.withValues(alpha: 0.22),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          segment.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${segment.durationMinutes}분',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(segment.detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}