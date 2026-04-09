import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';
import '../../../core/storage/recent_search_storage.dart';
import '../../../shared/widgets/surface_section.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onOpenRoute,
    required this.onSaveRoute,
    required this.savedRoutes,
    this.prefillPair,
    this.prefillRequestId = 0,
  });

  final ValueChanged<TripPlan> onOpenRoute;
  final ValueChanged<SavedRoute> onSaveRoute;
  final List<SavedRoute> savedRoutes;
  final SearchPair? prefillPair;
  final int prefillRequestId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _originController = TextEditingController(text: '주안역');
  final _destinationController = TextEditingController(text: '인하대학교');
  final _busWaitController = TextEditingController(text: '10');
  final _rideTimeController = TextEditingController(text: '20');
  final _trainWaitController = TextEditingController(text: '32');
  final _scrollController = ScrollController();
  final _resultsKey = GlobalKey();
  late List<TripPlan> _searchedPlans;
  late List<_PlacePair> _recentSearches;
  int _selectedMode = 0;

  int get _busWaitMinutes => int.tryParse(_busWaitController.text.trim()) ?? 0;
  int get _rideMinutes => int.tryParse(_rideTimeController.text.trim()) ?? 0;
  int get _trainWaitMinutes => int.tryParse(_trainWaitController.text.trim()) ?? 0;
  int get _stationArrivalMinutes => _busWaitMinutes + _rideMinutes;
  int get _transferMarginMinutes => _trainWaitMinutes - _stationArrivalMinutes;

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.prefillRequestId != oldWidget.prefillRequestId && widget.prefillPair != null) {
      _applySearchPair(widget.prefillPair!, recordRecent: true, revealResults: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _recentSearches = const [];
    _searchedPlans = DemoData.routeCandidates(
      origin: _originController.text,
      destination: _destinationController.text,
    );
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _busWaitController.dispose();
    _rideTimeController.dispose();
    _trainWaitController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _marginHeadline {
    if (_transferMarginMinutes >= 7) {
      return '여유 있게 환승 가능합니다.';
    }
    if (_transferMarginMinutes >= 4) {
      return '빠듯하지만 환승 가능 범위입니다.';
    }
    if (_transferMarginMinutes >= 0) {
      return '환승 여유가 너무 적습니다.';
    }
    return '현재 조합으로는 해당 지하철 탑승이 어렵습니다.';
  }

  String get _marginDescription {
    if (_transferMarginMinutes >= 7) {
      return '플랫폼 이동이나 소규모 지연까지 고려해도 비교적 안정적인 편입니다.';
    }
    if (_transferMarginMinutes >= 4) {
      return '도착 후 플랫폼 이동이나 지연 상황까지 고려하면 아직 버틸 수 있는 수준입니다.';
    }
    if (_transferMarginMinutes >= 0) {
      return '실제 이동, 계단, 개찰구 대기까지 고려하면 놓칠 가능성이 높습니다.';
    }
    return '다음 열차를 보거나 더 빠른 버스를 찾는 쪽이 현실적입니다.';
  }

  Color get _marginColor {
    if (_transferMarginMinutes >= 7) {
      return const Color(0xFF1F8F63);
    }
    if (_transferMarginMinutes >= 4) {
      return const Color(0xFF2C8C99);
    }
    if (_transferMarginMinutes >= 0) {
      return const Color(0xFFF28F3B);
    }
    return const Color(0xFFD64545);
  }

  String get _marginStageLabel {
    if (_transferMarginMinutes >= 7) {
      return '여유';
    }
    if (_transferMarginMinutes >= 4) {
      return '보통';
    }
    return '위험';
  }

  IconData get _marginIcon {
    if (_transferMarginMinutes >= 7) {
      return Icons.check_circle;
    }
    if (_transferMarginMinutes >= 4) {
      return Icons.watch_later_outlined;
    }
    return Icons.warning_amber_rounded;
  }

  String get _actionAdvice {
    if (_transferMarginMinutes >= 7) {
      return '현재 조합 유지';
    }
    if (_transferMarginMinutes >= 4) {
      return '탑승 후 이동 동선 최소화';
    }
    return '다음 열차 또는 더 빠른 버스 검토';
  }

  void _swapPlaces() {
    setState(() {
      final currentOrigin = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = currentOrigin;
    });
  }

  List<_PlacePair> _withRecentSearch(SearchPair pair) {
    final entry = _PlacePair(
      origin: pair.origin.trim().isEmpty ? '현재 위치' : pair.origin.trim(),
      destination: pair.destination.trim().isEmpty ? '목적지' : pair.destination.trim(),
    );

    return [
      entry,
      ..._recentSearches.where(
        (item) => item.origin != entry.origin || item.destination != entry.destination,
      ),
    ].take(4).toList();
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _applySearchPair(
    SearchPair pair, {
    bool recordRecent = false,
    bool revealResults = false,
  }) {
    final nextPlans = DemoData.routeCandidates(
      origin: pair.origin,
      destination: pair.destination,
    );
    final nextSearches = recordRecent ? _withRecentSearch(pair) : _recentSearches;

    setState(() {
      _originController.text = pair.origin;
      _destinationController.text = pair.destination;
      _searchedPlans = nextPlans;
      _recentSearches = nextSearches;
    });

    if (recordRecent) {
      _persistRecentSearches(nextSearches);
    }

    if (revealResults) {
      _scrollToResults();
    }
  }

  void _applyPair(_PlacePair pair) {
    _applySearchPair(SearchPair(origin: pair.origin, destination: pair.destination));
  }

  Future<void> _loadRecentSearches() async {
    final entries = await RecentSearchStorage.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _recentSearches = entries
          .map((entry) => _PlacePair(origin: entry.origin, destination: entry.destination))
          .toList();
    });
  }

  Future<void> _persistRecentSearches(List<_PlacePair> items) {
    return RecentSearchStorage.save(
      items
          .map((item) => RecentSearchEntry(origin: item.origin, destination: item.destination))
          .toList(),
    );
  }

  void _removeRecentSearch(_PlacePair pair) {
    final nextSearches = _recentSearches
        .where((item) => item.origin != pair.origin || item.destination != pair.destination)
        .toList();

    setState(() {
      _recentSearches = nextSearches;
    });

    _persistRecentSearches(nextSearches);
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches = const [];
    });

    _persistRecentSearches(const []);
  }

  void _buildRouteCandidates() {
    final pair = SearchPair(
      origin: _originController.text,
      destination: _destinationController.text,
    );
    final plans = DemoData.routeCandidates(
      origin: pair.origin,
      destination: pair.destination,
    );
    final nextSearches = _withRecentSearch(pair);

    setState(() {
      _searchedPlans = plans;
      _recentSearches = nextSearches;
    });

    _persistRecentSearches(nextSearches);
    _scrollToResults();
  }

  Future<void> _saveCurrentRoute() async {
    final origin = _originController.text.trim().isEmpty ? '현재 위치' : _originController.text.trim();
    final destination = _destinationController.text.trim().isEmpty ? '목적지' : _destinationController.text.trim();

    final isDuplicate = widget.savedRoutes.any(
      (route) => route.origin == origin && route.destination == destination,
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 저장된 경로입니다. 저장 탭에서 이름을 수정할 수 있습니다.')),
      );
      return;
    }

    final nameController = TextEditingController(text: '$origin → $destination');
    final summaryController = TextEditingController(
      text: '총 ${_orderedPlans.first.totalMinutes}분, ${_orderedPlans.first.transferCount}회 환승',
    );

    final route = await showModalBottomSheet<SavedRoute>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('현재 경로 저장', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('$origin → $destination'),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '저장 이름'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(labelText: '한 줄 설명'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop(
                      SavedRoute(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: nameController.text.trim().isEmpty
                            ? '$origin → $destination'
                            : nameController.text.trim(),
                        origin: origin,
                        destination: destination,
                        nextDeparture: _orderedPlans.first.departureTime,
                        summary: summaryController.text.trim().isEmpty
                            ? '총 ${_orderedPlans.first.totalMinutes}분, ${_orderedPlans.first.transferCount}회 환승'
                            : summaryController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('저장 경로에 추가'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || route == null) {
      return;
    }

    widget.onSaveRoute(route);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장 경로에 추가했습니다. 홈과 저장 탭에서 바로 사용할 수 있습니다.')),
    );
  }

  Future<void> _saveRecommendedPlan(TripPlan plan) async {
    final isDuplicate = widget.savedRoutes.any(
      (route) =>
          route.origin == plan.origin &&
          route.destination == plan.destination &&
          route.name == plan.title,
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 저장된 추천 경로입니다. 저장 탭에서 순서를 바꿀 수 있습니다.')),
      );
      return;
    }

    final nameController = TextEditingController(text: plan.title);
    final summaryController = TextEditingController(
      text: '총 ${plan.totalMinutes}분, ${plan.transferCount}회 환승, ${plan.riskLevel}',
    );

    final route = await showModalBottomSheet<SavedRoute>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('추천 경로 저장', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${plan.origin} → ${plan.destination}'),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '저장 이름'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(labelText: '한 줄 설명'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop(
                      SavedRoute(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: nameController.text.trim().isEmpty ? plan.title : nameController.text.trim(),
                        origin: plan.origin,
                        destination: plan.destination,
                        nextDeparture: plan.departureTime,
                        summary: summaryController.text.trim().isEmpty
                            ? '총 ${plan.totalMinutes}분, ${plan.transferCount}회 환승, ${plan.riskLevel}'
                            : summaryController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('추천 경로 저장'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || route == null) {
      return;
    }

    widget.onSaveRoute(route);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('추천 경로를 저장했습니다. 저장 탭에서 고정과 순서 변경이 가능합니다.')),
    );
  }

  List<TripPlan> get _orderedPlans {
    final plans = [..._searchedPlans];

    switch (_selectedMode) {
      case 1:
        plans.sort((a, b) => _riskRank(a.riskLevel).compareTo(_riskRank(b.riskLevel)));
      case 2:
        plans.sort((a, b) => a.transferCount.compareTo(b.transferCount));
      default:
        plans.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    }

    return plans;
  }

  int _riskRank(String riskLevel) {
    switch (riskLevel) {
      case '여유':
        return 0;
      case '보통':
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _orderedPlans;
    final originLabel = _originController.text.trim().isEmpty
        ? '현재 위치'
        : _originController.text.trim();
    final destinationLabel = _destinationController.text.trim().isEmpty
        ? '목적지'
        : _destinationController.text.trim();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Text('경로 탐색', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('출발지와 도착지만 입력하면 총 이동 시간과 환승 위험도를 자동으로 계산합니다.'),
        const SizedBox(height: 18),
        SurfaceSection(
          title: '탐색 조건',
          subtitle: '교통체증은 제외하고, 대중교통 조합과 환승 리스크를 기준으로 후보를 만듭니다.',
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('최적')),
                  ButtonSegment(value: 1, label: Text('안정 우선')),
                  ButtonSegment(value: 2, label: Text('환승 적음')),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedMode = value.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _originController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.trip_origin),
                            labelText: '출발지',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _destinationController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.flag_outlined),
                            labelText: '도착지',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: IconButton.filledTonal(
                      onPressed: _swapPlaces,
                      tooltip: '출발지와 도착지 바꾸기',
                      icon: const Icon(Icons.swap_vert_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '최근 검색',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '검색할 때 자동으로 기록되는 히스토리입니다. 개별 삭제와 전체 비우기가 가능합니다.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_recentSearches.isNotEmpty)
                      TextButton(
                        onPressed: _clearRecentSearches,
                        child: const Text('비우기'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.isEmpty
                    ? [
                        const _EmptyHintChip(label: '검색한 경로가 여기에 저장됩니다'),
                      ]
                    : _recentSearches
                        .map(
                          (pair) => InputChip(
                            label: Text('${pair.origin} → ${pair.destination}'),
                            onPressed: () => _applyPair(pair),
                            onDeleted: () => _removeRecentSearch(pair),
                            deleteIcon: const Icon(Icons.close, size: 18),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '저장 경로 불러오기',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '직접 저장해 두는 북마크 경로입니다. 이름 변경과 삭제는 저장 탭에서 관리합니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.savedRoutes.isEmpty
                    ? [
                        const _EmptyHintChip(label: '저장 탭에서 경로를 관리하면 여기에서 바로 불러올 수 있습니다'),
                      ]
                    : widget.savedRoutes
                        .map(
                          (route) => ActionChip(
                            label: Text(route.name),
                            avatar: const Icon(Icons.bookmark_outline, size: 18),
                            onPressed: () => _applyPair(
                              _PlacePair(origin: route.origin, destination: route.destination),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _buildRouteCandidates,
                        child: const Text('ETA 계산하기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveCurrentRoute,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('현재 경로 저장'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SurfaceSection(
          title: '환승 여유 계산기',
          subtitle: '자동 추천 아래에서 세부 환승 상황을 따로 검토할 수 있는 보조 계산기입니다.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MinuteInput(
                      controller: _busWaitController,
                      label: '버스 도착까지',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MinuteInput(
                      controller: _rideTimeController,
                      label: '역까지 이동',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MinuteInput(
                      controller: _trainWaitController,
                      label: '지하철 도착까지',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _marginColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _marginColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_marginIcon, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                _marginStageLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('기준: 3분 이하 위험, 4~6분 보통, 7분 이상 여유'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '역 도착 예상: $_stationArrivalMinutes분 뒤',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '환승 여유: $_transferMarginMinutes분',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _marginColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _marginHeadline,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(_marginDescription),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '권고: $_actionAdvice',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _marginColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        KeyedSubtree(
          key: _resultsKey,
          child: SurfaceSection(
            title: '추천 결과',
            subtitle: '$originLabel에서 $destinationLabel까지의 후보 경로입니다.',
            child: Column(
              children: plans
                  .map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(
                        plan: plan,
                        onTap: () => widget.onOpenRoute(plan),
                        onSave: () => _saveRecommendedPlan(plan),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MinuteInput extends StatelessWidget {
  const _MinuteInput({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: '분',
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap, required this.onSave});

  final TripPlan plan;
  final VoidCallback onTap;
  final VoidCallback onSave;

  List<RouteSegment> get _transportSegments =>
      plan.segments.where((segment) => segment.mode != '도보').toList();

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (plan.riskLevel) {
      '여유' => const Color(0xFF1F8F63),
      '보통' => const Color(0xFFF28F3B),
      _ => const Color(0xFFD64545),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(24),
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(text: '${plan.departureTime} 출발'),
                _MetaPill(text: '${plan.arrivalTime} 도착'),
                _MetaPill(text: '도보 ${plan.walkingMinutes}분'),
                _MetaPill(text: '환승 ${plan.transferCount}회'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이동 조합',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < _transportSegments.length; index++) ...[
                        _ModePill(mode: _transportSegments[index].mode),
                        if (index != _transportSegments.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Icon(Icons.arrow_forward_rounded, size: 16),
                          ),
                      ],
                    ],
                  ),
                  if (_transportSegments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final segment in _transportSegments.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SegmentPreview(segment: segment),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('이 추천 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.mode});

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
          Text(
            mode,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SegmentPreview extends StatelessWidget {
  const _SegmentPreview({required this.segment});

  final RouteSegment segment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  segment.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${segment.durationMinutes}분'),
            ],
          ),
          const SizedBox(height: 4),
          Text(segment.detail),
        ],
      ),
    );
  }
}

class _PlacePair {
  const _PlacePair({required this.origin, required this.destination});

  final String origin;
  final String destination;
}

class _EmptyHintChip extends StatelessWidget {
  const _EmptyHintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label),
    );
  }
}