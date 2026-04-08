import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/models/bus_eta_models.dart';
import '../../../shared/widgets/surface_section.dart';

class SavedRoutesScreen extends StatelessWidget {
  const SavedRoutesScreen({
    super.key,
    required this.onOpenRoute,
    required this.onLoadSearch,
    required this.savedRoutes,
    required this.onCreateRoute,
    required this.onUpdateRoute,
    required this.onDeleteRoute,
  });

  final ValueChanged<TripPlan> onOpenRoute;
  final ValueChanged<SearchPair> onLoadSearch;
  final List<SavedRoute> savedRoutes;
  final ValueChanged<SavedRoute> onCreateRoute;
  final ValueChanged<SavedRoute> onUpdateRoute;
  final ValueChanged<String> onDeleteRoute;

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

    onCreateRoute(newRoute);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('새 저장 경로를 추가했습니다.')),
    );
  }

  Future<void> _showEditSheet(BuildContext context, SavedRoute route) async {
    final nameController = TextEditingController(text: route.name);
    final summaryController = TextEditingController(text: route.summary);

    final updatedRoute = await showModalBottomSheet<SavedRoute>(
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
              Text('저장 경로 편집', style: Theme.of(sheetContext).textTheme.titleLarge),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop(
                      route.copyWith(
                        name: nameController.text.trim().isEmpty ? route.name : nameController.text.trim(),
                        summary: summaryController.text.trim().isEmpty
                            ? route.summary
                            : summaryController.text.trim(),
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

    if (!context.mounted || updatedRoute == null) {
      return;
    }

    onUpdateRoute(updatedRoute);
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

    onDeleteRoute(route.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Text('저장 경로', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('자주 쓰는 이동 경로를 저장해 반복 이동을 빠르게 확인할 수 있습니다.'),
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
            children: savedRoutes.isEmpty
                ? [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFD),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text('저장된 경로가 없습니다. 홈 또는 검색 흐름에서 자주 쓰는 루트를 다시 구성해 주세요.'),
                    ),
                  ]
                : List.generate(savedRoutes.length, (index) {
                    final item = savedRoutes[index];
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
                                    child: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                                  ),
                                  Text(item.nextDeparture),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${item.origin} → ${item.destination}'),
                              const SizedBox(height: 6),
                              Text(item.summary),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _SavedRoutePill(label: '직접 관리'),
                                  _SavedRoutePill(label: '이름 변경 가능'),
                                  _SavedRoutePill(label: '홈/검색 공통 사용'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _showEditSheet(context, item),
                                    child: const Text('이름/설명 편집'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => onLoadSearch(
                                      SearchPair(origin: item.origin, destination: item.destination),
                                    ),
                                    icon: const Icon(Icons.search_rounded),
                                    label: const Text('검색 불러오기'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => onOpenRoute(plan),
                                    child: const Text('상세 보기'),
                                  ),
                                  TextButton(
                                    onPressed: () => _confirmDelete(context, item),
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