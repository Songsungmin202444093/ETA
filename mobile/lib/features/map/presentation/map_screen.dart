import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/bus_eta_models.dart';
import '../../../core/services/bus_arrival_service.dart';
import '../../../core/services/bus_location_service.dart';
import '../../../core/services/bus_stop_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';

// 경기도 수원시 기본 중심 (API 데이터가 없을 때 폴백)
const _kDefaultCenter = LatLng(37.2636, 127.0286);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();

  LatLng? _myLocation;
  NearbyStation? _selectedStation;
  bool _loadingLocation = false;
  String? _locationError;

  List<NearbyStation> _nearbyStations = [];
  List<BusLocation> _busLocations = [];
  bool _loadingStations = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadStationsAndBuses(double lat, double lng) async {
    if (mounted) setState(() => _loadingStations = true);
    try {
      final stations = await BusStopService.instance.getNearbyStations(lat, lng);

      // 최대 5개 정류소 도착정보 병렬 조회
      final withArrivals = await Future.wait(
        stations.take(5).map((s) async {
          if (s.stationId == null || s.stationId!.isEmpty) return s;
          try {
            final arrivals = await BusArrivalService.instance.getArrivalList(s.stationId!);
            return s.copyWithArrivals(arrivals);
          } catch (_) {
            return s;
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _nearbyStations = withArrivals;
        _loadingStations = false;
      });

      // 모든 노선의 버스 위치 조회
      _refreshBusLocations();

      // 30초마다 버스 위치 자동 갱신
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) _refreshBusLocations();
      });
    } catch (e) {
      if (mounted) setState(() => _loadingStations = false);
    }
  }

  Future<void> _refreshBusLocations() async {
    final allArrivals = _nearbyStations.expand((s) => s.arrivals).toList();
    try {
      final locs = await BusLocationService.instance.getBusLocationsForRoutes(allArrivals);
      if (mounted) setState(() => _busLocations = locs);
    } catch (_) {}
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    final status = await LocationService.instance.checkStatus();

    if (status == LocationStatus.denied || status == LocationStatus.unknown) {
      final requested = await LocationService.instance.requestPermission();
      if (requested != LocationStatus.granted) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
            _locationError = status == LocationStatus.deniedForever
                ? '위치 권한이 영구 거부되었습니다.\n설정 앱에서 권한을 허용해 주세요.'
                : '위치 권한이 없어 현재 위치를 표시할 수 없습니다.';
          });
        }
        return;
      }
    }

    if (status == LocationStatus.deniedForever) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _locationError = '위치 권한이 영구 거부되었습니다.\n설정 앱에서 권한을 허용해 주세요.';
        });
      }
      return;
    }

    final position = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _loadingLocation = false;
        _locationError = 'GPS 신호를 찾을 수 없습니다.\n잠시 후 다시 시도해 주세요.';
      });
      return;
    }

    final myLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _myLocation = myLatLng;
      _loadingLocation = false;
    });
    _mapController.move(myLatLng, 15.5);
    _loadStationsAndBuses(position.latitude, position.longitude);
  }

  Future<void> _moveToMyLocation() async {
    if (_myLocation != null) {
      _mapController.move(_myLocation!, 15.5);
      return;
    }
    await _fetchLocation();
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
            // 정류장 마커
            MarkerLayer(
              markers: [
                for (final s in _nearbyStations)
                  if (s.latitude != null && s.longitude != null)
                    Marker(
                      point: LatLng(s.latitude!, s.longitude!),
                      width: 90,
                      height: 68,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedStation = s);
                          _mapController.move(LatLng(s.latitude!, s.longitude!), 16);
                        },
                        child: _StationMarker(name: s.name, icon: Icons.directions_bus_rounded),
                      ),
                    ),
                // 버스 위치 마커
                for (final bus in _busLocations)
                  Marker(
                    point: LatLng(bus.latitude, bus.longitude),
                    width: 64,
                    height: 48,
                    child: _BusMarker(routeName: bus.routeName),
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

        // 정류장 로딩 인디케이터
        if (_loadingStations)
          const Positioned(
            top: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
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
                loading: _loadingLocation,
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

        // ── 위치 오류 배너 ────────────────────────────────────
        if (_locationError != null && _selectedStation == null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.location_off_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchLocation,
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── 하단 정류장 목록 패널 ─────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _StationBottomPanel(
            stations: _nearbyStations,
            onTap: (station, _) {
              setState(() => _selectedStation = station);
              if (station.latitude != null && station.longitude != null) {
                _mapController.move(LatLng(station.latitude!, station.longitude!), 16);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── 위젯 ──────────────────────────────────────────────────────

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

class _BusMarker extends StatelessWidget {
  const _BusMarker({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF28F3B),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.directions_bus_filled_rounded,
              color: Colors.white, size: 14),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF28F3B),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            routeName,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
    this.loading = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFF2C8C99) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
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
                    (a) => GestureDetector(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('${a.line}번 버스 알림'),
                            content: Text(
                              '${station.name} 정류장에 ${a.line}번이\n'
                              '약 ${a.arrivalMinutes}분 후 도착합니다.\n\n1분 전 알림을 받을까요?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('취소'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('알림 설정'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        await NotificationService.instance.scheduleArrivalAlert(
                          id: a.line.hashCode ^ station.name.hashCode,
                          stationName: station.name,
                          line: a.line,
                          arrivalMinutes: a.arrivalMinutes,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${a.line}번 버스 알림이 설정되었습니다.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${a.line}번 · ${a.arrivalMinutes}분 후',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.notifications_none_rounded, size: 13),
                          ],
                        ),
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
