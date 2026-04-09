import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';
import '../../../shared/widgets/surface_section.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({
    super.key,
    required this.onOpenRoute,
    required this.onLoadSearch,
    required this.savedRoutes,
    required this.onCreateRoute,
    required this.onUpdateRoute,
    required this.onTogglePin,
    required this.onMoveRoute,
    required this.onDeleteRoute,
  });

  final ValueChanged<TripPlan> onOpenRoute;
  final ValueChanged<SearchPair> onLoadSearch;
  final List<SavedRoute> savedRoutes;
  final ValueChanged<SavedRoute> onCreateRoute;
  final ValueChanged<SavedRoute> onUpdateRoute;
  final ValueChanged<String> onTogglePin;
  final void Function(String routeId, int offset) onMoveRoute;
  final ValueChanged<String> onDeleteRoute;

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  String? _selectedTag;

  Set<String> get _allTags => {
        for (final r in widget.savedRoutes) ...r.tags,
      };

  List<SavedRoute> get _filteredRoutes => _selectedTag == null
      ? widget.savedRoutes
      : widget.savedRoutes.where((r) => r.tags.contains(_selectedTag)).toList();

  Future<void> _showCreateSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    final summaryController = TextEditingController();

    final newRoute = await showModalBottomSheet<SavedRoute>(
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
              Text('새 저장 경로', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '경로 이름'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: '출발지'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: '도착지'),
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
                    final origin = originController.text.trim();
                    final destination = destinationController.text.trim();
                    if (origin.isEmpty || destination.isEmpty) {
                      return;
                    }

                    Navigator.of(sheetContext).pop(
                      SavedRoute(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: nameController.text.trim().isEmpty
                            ? '$origin → $destination'
                            : nameController.text.trim(),
                        origin: origin,
                        destination: destination,
                        nextDeparture: '지금 저장',
                        summary: summaryController.text.trim().isEmpty
                            ? '직접 추가한 경로'
                            : summaryController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('저장 경로 추가'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || newRoute == null) {
      return;
    }

    widget.onCreateRoute(newRoute);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('새 저장 경로를 추가했습니다.')),
    );
  }

  Future<void> _showEditSheet(BuildContext context, SavedRoute route) async {
    final nameController = TextEditingController(text: route.name);
    final summaryController = TextEditingController(text: route.summary);
    final tagController = TextEditingController();
    var editedTags = [...route.tags];

    final updatedRoute = await showModalBottomSheet<SavedRoute>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                  Text('저장 경로 편집', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('${route.origin} → ${route.destination}'),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '경로 이름'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryController,
                    decoration: const InputDecoration(labelText: '한 줄 설명'),
                  ),
                  const SizedBox(height: 18),
                  Text('태그', style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '태그를 달면 저장 탭 상단 필터로 빠르게 모아볼 수 있습니다.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  if (editedTags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: editedTags
                          .map(
                            (tag) => InputChip(
                              label: Text(tag),
                              onDeleted: () =>
                                  setSheetState(() => editedTags.remove(tag)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: const InputDecoration(
                            labelText: '태그 이름 입력',
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            final tag = value.trim();
                            if (tag.isNotEmpty && !editedTags.contains(tag)) {
                              setSheetState(() {
                                editedTags.add(tag);
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          final tag = tagController.text.trim();
                          if (tag.isNotEmpty && !editedTags.contains(tag)) {
                            setSheetState(() {
                              editedTags.add(tag);
                              tagController.clear();
                            });
                          }
                        },
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(
                          route.copyWith(
                            name: nameController.text.trim().isEmpty
                                ? route.name
                                : nameController.text.trim(),
                            summary: summaryController.text.trim().isEmpty
                                ? route.summary
                                : summaryController.text.trim(),
                            tags: editedTags,
                          ),
                        );
                      },
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!context.mounted || updatedRoute == null) {
      return;
    }

    widget.onUpdateRoute(updatedRoute);
  }

  Future<void> _confirmDelete(BuildContext context, SavedRoute route) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('저장 경로 삭제'),
          content: Text('${route.name}을(를) 삭제하면 홈과 검색에서 더 이상 바로 불러올 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || shouldDelete != true) {
      return;
    }

    widget.onDeleteRoute(route.id);
  }

  @override
  Widget build(BuildContext context) {
    final allTags = _allTags;
    final routes = _filteredRoutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Text('저장 경로', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('자주 쓰는 이동 경로를 저장해 반복 이동을 빠르게 확인할 수 있습니다.'),
        if (allTags.isNotEmpty) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: _selectedTag == null,
                  onSelected: (_) => setState(() => _selectedTag = null),
                ),
                const SizedBox(width: 8),
                ...allTags.map(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag),
                      selected: _selectedTag == tag,
                      onSelected: (_) => setState(
                        () => _selectedTag = _selectedTag == tag ? null : tag,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        SurfaceSection(
          title: '직접 관리하는 저장 경로',
          subtitle: '최근 검색은 자동 기록, 저장 경로는 직접 이름을 바꾸고 삭제할 수 있는 북마크입니다.',
          trailing: FilledButton.tonalIcon(
            onPressed: () => _showCreateSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('새 경로 추가'),
          ),
          child: Column(
            children: routes.isEmpty
                ? [
                    _EmptyRoutesCard(
                      isFiltered: _selectedTag != null,
                      onAdd: () => _showCreateSheet(context),
                      onClearFilter: () =>
                          setState(() => _selectedTag = null),
                    ),
                  ]
                : List.generate(routes.length, (index) {
                    final item = routes[index];
                    final originalIndex = widget.savedRoutes.indexOf(item);
                    final plan = DemoData.routeCandidates(
                      origin: item.origin,
                      destination: item.destination,
                    ).first;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: const Color(0xFFF8FBFD),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(item.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                  ),
                                  if (item.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.push_pin_rounded,
                                          size: 18),
                                    ),
                                  Text(item.nextDeparture),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${item.origin} → ${item.destination}'),
                              const SizedBox(height: 6),
                              Text(item.summary),
                              if (item.tags.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: item.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _SavedRoutePill(
                                      label: item.isPinned
                                          ? '상단 고정'
                                          : '직접 관리'),
                                  const _SavedRoutePill(label: '이름 변경 가능'),
                                  const _SavedRoutePill(
                                      label: '홈/검색 공통 사용'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        widget.onTogglePin(item.id),
                                    icon: Icon(item.isPinned
                                        ? Icons.push_pin_outlined
                                        : Icons.push_pin_rounded),
                                    label: Text(item.isPinned
                                        ? '고정 해제'
                                        : '즐겨찾기 고정'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: originalIndex == 0 ||
                                            widget.savedRoutes[originalIndex - 1]
                                                    .isPinned !=
                                                item.isPinned
                                        ? null
                                        : () =>
                                            widget.onMoveRoute(item.id, -1),
                                    icon: const Icon(
                                        Icons.arrow_upward_rounded),
                                    label: const Text('위로'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: originalIndex ==
                                                widget.savedRoutes.length -
                                                    1 ||
                                            widget.savedRoutes[originalIndex + 1]
                                                    .isPinned !=
                                                item.isPinned
                                        ? null
                                        : () =>
                                            widget.onMoveRoute(item.id, 1),
                                    icon: const Icon(
                                        Icons.arrow_downward_rounded),
                                    label: const Text('아래로'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        _showEditSheet(context, item),
                                    child: const Text('이름/설명 편집'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => widget.onLoadSearch(
                                      SearchPair(
                                          origin: item.origin,
                                          destination: item.destination),
                                    ),
                                    icon: const Icon(Icons.search_rounded),
                                    label: const Text('검색 불러오기'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () =>
                                        widget.onOpenRoute(plan),
                                    child: const Text('상세 보기'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _confirmDelete(context, item),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
          ),
        ),
      ],
    );
  }
}

class _EmptyRoutesCard extends StatelessWidget {
  const _EmptyRoutesCard({
    required this.isFiltered,
    required this.onAdd,
    required this.onClearFilter,
  });

  final bool isFiltered;
  final VoidCallback onAdd;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            isFiltered
                ? Icons.filter_list_off_rounded
                : Icons.bookmark_add_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered
                ? '이 태그에 해당하는 경로가 없습니다'
                : '아직 저장된 경로가 없습니다',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? '다른 태그를 선택하거나 전체 보기로 돌아가세요.'
                : '자주 쓰는 출발지·도착지 조합을 저장해두면\n검색 없이 바로 불러올 수 있습니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (isFiltered)
            OutlinedButton.icon(
              onPressed: onClearFilter,
              icon: const Icon(Icons.filter_list_off_rounded),
              label: const Text('필터 초기화'),
            )
          else
            FilledButton.tonal(
              onPressed: onAdd,
              child: const Text('첫 경로 추가하기'),
            ),
        ],
      ),
    );
  }
}

class _SavedRoutePill extends StatelessWidget {
  const _SavedRoutePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label),
    );
  }
}