import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';
import '../../../core/storage/saved_route_storage.dart';
import '../../auth/presentation/login_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../route/presentation/route_detail_screen.dart';
import '../../saved_routes/presentation/saved_routes_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  SearchPair? _pendingSearchPair;
  int _searchRequestId = 0;
  List<SavedRoute> _savedRoutes = [...DemoData.savedRoutes];

  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
  }

  Future<void> _loadSavedRoutes() async {
    final routes = await SavedRouteStorage.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _savedRoutes = _normalizeSavedRoutes([...routes]);
    });
  }

  Future<void> _persistSavedRoutes(List<SavedRoute> routes) {
    return SavedRouteStorage.save(routes);
  }

  List<SavedRoute> _normalizeSavedRoutes(List<SavedRoute> routes) {
    final pinned = routes.where((route) => route.isPinned).toList();
    final unpinned = routes.where((route) => !route.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  void _openRoute(TripPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteDetailScreen(plan: plan),
      ),
    );
  }

  void _openSearchWithPair(SearchPair pair) {
    setState(() {
      _pendingSearchPair = pair;
      _searchRequestId += 1;
      _currentIndex = 1;
    });
  }

  void _updateSavedRoute(SavedRoute route) {
    final nextRoutes = _normalizeSavedRoutes(
      _savedRoutes.map((item) => item.id == route.id ? route : item).toList(),
    );

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  void _createSavedRoute(SavedRoute route) {
    final nextRoutes = _normalizeSavedRoutes([route, ..._savedRoutes]);

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  void _deleteSavedRoute(String routeId) {
    final nextRoutes = _normalizeSavedRoutes(
      _savedRoutes.where((item) => item.id != routeId).toList(),
    );

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  void _toggleSavedRoutePin(String routeId) {
    final nextRoutes = _normalizeSavedRoutes(
      _savedRoutes
          .map(
            (item) => item.id == routeId ? item.copyWith(isPinned: !item.isPinned) : item,
          )
          .toList(),
    );

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  void _moveSavedRoute(String routeId, int offset) {
    final index = _savedRoutes.indexWhere((item) => item.id == routeId);
    if (index == -1) {
      return;
    }

    final route = _savedRoutes[index];
    final sameSectionIndexes = <int>[];
    for (var i = 0; i < _savedRoutes.length; i++) {
      if (_savedRoutes[i].isPinned == route.isPinned) {
        sameSectionIndexes.add(i);
      }
    }

    final sectionIndex = sameSectionIndexes.indexOf(index);
    final nextSectionIndex = sectionIndex + offset;
    if (nextSectionIndex < 0 || nextSectionIndex >= sameSectionIndexes.length) {
      return;
    }

    final targetIndex = sameSectionIndexes[nextSectionIndex];
    final nextRoutes = [..._savedRoutes];
    final movingRoute = nextRoutes.removeAt(index);
    nextRoutes.insert(targetIndex, movingRoute);
    final normalized = _normalizeSavedRoutes(nextRoutes);

    setState(() {
      _savedRoutes = normalized;
    });

    _persistSavedRoutes(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenRoute: _openRoute,
        onLoadSearch: _openSearchWithPair,
        savedRoutes: _savedRoutes,
        onRefresh: _loadSavedRoutes,
      ),
      SearchScreen(
        onOpenRoute: _openRoute,
        onSaveRoute: _createSavedRoute,
        savedRoutes: _savedRoutes,
        prefillPair: _pendingSearchPair,
        prefillRequestId: _searchRequestId,
      ),
      const MapScreen(),
      SavedRoutesScreen(
        onOpenRoute: _openRoute,
        onLoadSearch: _openSearchWithPair,
        savedRoutes: _savedRoutes,
        onCreateRoute: _createSavedRoute,
        onUpdateRoute: _updateSavedRoute,
        onTogglePin: _toggleSavedRoutePin,
        onMoveRoute: _moveSavedRoute,
        onDeleteRoute: _deleteSavedRoute,
        onRefresh: _loadSavedRoutes,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: IndexedStack(index: _currentIndex, children: screens)),
          // 로그아웃 버튼 (우측 상단)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: SafeArea(
              child: PopupMenuButton<String>(
                icon: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person_outline_rounded,
                      color: Colors.white, size: 20),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  } else if (value == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  } else if (value == 'logout') {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('auto_login');
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded, size: 18, color: AppTheme.text),
                        SizedBox(width: 10),
                        Text('내 정보'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded, size: 18, color: AppTheme.text),
                        SizedBox(width: 10),
                        Text('설정'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 18, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF102638),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                indicatorColor: const Color(0xFF2C8C99),
                selectedIndex: _currentIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
                  NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: '검색'),
                  NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: '지도'),
                  NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: '저장'),
                ],
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}