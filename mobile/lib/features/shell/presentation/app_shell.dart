import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';
import '../../../core/storage/saved_route_storage.dart';
import '../../home/presentation/home_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../route/presentation/route_detail_screen.dart';
import '../../saved_routes/presentation/saved_routes_screen.dart';
import '../../search/presentation/search_screen.dart';

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
      _savedRoutes = [...routes];
    });
  }

  Future<void> _persistSavedRoutes(List<SavedRoute> routes) {
    return SavedRouteStorage.save(routes);
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
    final nextRoutes = _savedRoutes.map((item) => item.id == route.id ? route : item).toList();

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  void _createSavedRoute(SavedRoute route) {
    final nextRoutes = [route, ..._savedRoutes];

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  void _deleteSavedRoute(String routeId) {
    final nextRoutes = _savedRoutes.where((item) => item.id != routeId).toList();

    setState(() {
      _savedRoutes = nextRoutes;
    });

    _persistSavedRoutes(nextRoutes);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenRoute: _openRoute,
        onLoadSearch: _openSearchWithPair,
        savedRoutes: _savedRoutes,
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
        onDeleteRoute: _deleteSavedRoute,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: IndexedStack(index: _currentIndex, children: screens)),
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