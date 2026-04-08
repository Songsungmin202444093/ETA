import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../shared/widgets/surface_section.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Text('주변 정류장 지도', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('GPS 기반 주변 정류장 탐색과 지도 기반 선택 흐름을 발표용으로 시각화했습니다.'),
        const SizedBox(height: 18),
        SurfaceSection(
          title: '현재 위치 기반 탐색',
          subtitle: '실제 지도 SDK 대신 발표용 모형 지도를 사용합니다.',
          child: Column(
            children: [
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD7EEF5), Color(0xFFEAF7F2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _MapPainter()),
                    ),
                    const Positioned(
                      left: 140,
                      top: 110,
                      child: _MapPin(label: '현재 위치', icon: Icons.my_location),
                    ),
                    const Positioned(
                      left: 58,
                      top: 60,
                      child: _MapPin(label: '인하대후문', icon: Icons.directions_bus),
                    ),
                    const Positioned(
                      right: 54,
                      top: 70,
                      child: _MapPin(label: '용현사거리', icon: Icons.directions_bus),
                    ),
                    const Positioned(
                      right: 76,
                      bottom: 62,
                      child: _MapPin(label: '인하대역', icon: Icons.train),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Chip(label: Text('현위치 표시')),
                  Chip(label: Text('주변 정류장 자동 탐색')),
                  Chip(label: Text('지도에서 직접 선택')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SurfaceSection(
          title: '근처 정류장 요약',
          child: Column(
            children: DemoData.nearbyStations
                .map(
                  (station) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF163B59).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFF163B59),
                        child: const Icon(Icons.place_outlined),
                      ),
                      title: Text(station.name),
                      subtitle: Text('${station.distanceMeters}m · ${station.lines.join(' · ')}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFF163B59),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFB7D9E2)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final route = Paint()
      ..color = const Color(0xFFF28F3B)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(40, size.height - 70), Offset(size.width - 50, 50), road);
    canvas.drawLine(Offset(20, 90), Offset(size.width - 30, size.height - 70), road);
    canvas.drawLine(Offset(size.width * 0.35, 20), Offset(size.width * 0.35, size.height - 20), road);
    canvas.drawLine(Offset(60, size.height - 80), Offset(size.width - 100, 95), route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}