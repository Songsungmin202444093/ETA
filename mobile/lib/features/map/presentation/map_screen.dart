import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';

// 인하대 주변 데모 좌표 (실제 주소 기반 근사치)
const _kDefaultCenter = LatLng(37.4502, 126.6571);

const _kStations = [
  _StationData(
    name: '인하대후문',
    position: LatLng(37.4518, 126.6558),
    icon: Icons.directions_bus_rounded,
  ),
  _StationData(
    name: '용현사거리',
    position: LatLng(37.4478, 126.6596),
    icon: Icons.directions_bus_rounded,
  ),
  _StationData(
    name: '인하대역 2번 출구',
    position: LatLng(37.4490, 126.6488),
    icon: Icons.train_rounded,
  ),
];

// 데모 경로 폴리라인 (인하대후문 → 현재 위치 → 인하대역)
const _kRoutePoints = [
  LatLng(37.4518, 126.6558),
  LatLng(37.4510, 126.6575),
  LatLng(37.4502, 126.6571),
  LatLng(37.4495, 126.6530),
  LatLng(37.4490, 126.6488),
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();

  // GPS-ready 구조: 나중에 geolocator StreamSubscription<Position>으로 교체.
  // 현재는 버튼을 누르면 기본 좌표를 내 위치로 가정함.
  LatLng? _myLocation;
  NearbyStation? _selectedStation;

  void _moveToMyLocation() {
    setState(() => _myLocation = _kDefaultCenter);
    _mapController.move(_kDefaultCenter, 15.5);
  }

  void _zoomIn() => _mapController.move(
        _mapController.camera.center,
        _mapController.camera.zoom + 1,
      );

  void _zoomOut() => _mapController.move(
        _mapController.camera.center,
        _mapController.camera.zoom - 1,
      );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 지도 ──────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _kDefaultCenter,
            initialZoom: 15.0,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile',
            ),
            // 데모 경로 폴리라인
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _kRoutePoints,
                  color: const Color(0xFFF28F3B),
                  strokeWidth: 4.5,
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                ),
              ],
            ),
            // 정류장 마커
            MarkerLayer(
              markers: [
                for (final s in _kStations)
                  Marker(
                    point: s.position,
                    width: 90,
                    height: 68,
                    child: GestureDetector(
                      onTap: () {
                        final station = DemoData.nearbyStations.firstWhere(
                          (st) => st.name.startsWith(s.name.substring(0, 4)),
                          orElse: () => DemoData.nearbyStations.first,
                        );
                        setState(() => _selectedStation = station);
                        _mapController.move(s.position, 16);
                      },
                      child: _StationMarker(name: s.name, icon: s.icon),
                    ),
                  ),
                // 내 위치 마커
                if (_myLocation != null)
                  Marker(
                    point: _myLocation!,
                    width: 56,
                    height: 56,
                    child: const _MyLocationMarker(),
                  ),
              ],
            ),
          ],
        ),

        // ── 우측 버튼 패널 ────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 220,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.add,
                tooltip: '확대',
                onTap: _zoomIn,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: Icons.remove,
                tooltip: '축소',
                onTap: _zoomOut,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: Icons.my_location_rounded,
                tooltip: '내 위치',
                onTap: _moveToMyLocation,
                highlighted: _myLocation != null,
              ),
            ],
          ),
        ),

        // ── 선택된 정류장 팝업 ─────────────────────────────────
        if (_selectedStation != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _StationPopup(
              station: _selectedStation!,
              onClose: () => setState(() => _selectedStation = null),
            ),
          ),

        // ── 하단 정류장 목록 패널 ─────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _StationBottomPanel(
            stations: DemoData.nearbyStations,
            onTap: (station, index) {
              setState(() => _selectedStation = station);
              _mapController.move(_kStations[index % _kStations.length].position, 16);
            },
          ),
        ),
      ],
    );
  }
}

// ── 위젯 ──────────────────────────────────────────────────────

class _StationData {
  const _StationData({
    required this.name,
    required this.position,
    required this.icon,
  });
  final String name;
  final LatLng position;
  final IconData icon;
}

class _StationMarker extends StatelessWidget {
  const _StationMarker({required this.name, required this.icon});
  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF163B59),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF163B59),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C8C99).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2C8C99),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFF2C8C99) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: highlighted ? Colors.white : const Color(0xFF163B59),
            ),
          ),
        ),
      ),
    );
  }
}

class _StationPopup extends StatelessWidget {
  const _StationPopup({required this.station, required this.onClose});
  final NearbyStation station;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_rounded, color: Color(0xFF163B59)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${station.distanceMeters}m · ${station.lines.join(' · ')}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: station.arrivals
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${a.line}번 · ${a.arrivalMinutes}분 후',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationBottomPanel extends StatelessWidget {
  const _StationBottomPanel({
    required this.stations,
    required this.onTap,
  });
  final List<NearbyStation> stations;
  final void Function(NearbyStation station, int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('주변 정류장', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF163B59),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${stations.length}곳',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(stations.length, (i) {
            final s = stations[i];
            return InkWell(
              onTap: () => onTap(s, i),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          const Color(0xFF163B59).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF163B59),
                      child: const Icon(Icons.place_outlined, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${s.distanceMeters}m · ${s.lines.join(' · ')}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
