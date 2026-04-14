import 'package:flutter/material.dart';

/// 단순 shimmer 없이 애니메이션 그라디언트로 스켈레톤 효과를 구현합니다.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _animation.value * 0.15),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// 저장 경로 카드 스켈레톤
class SavedRouteCardSkeleton extends StatelessWidget {
  const SavedRouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 120, height: 18, borderRadius: 8),
                const Spacer(),
                const SkeletonBox(width: 48, height: 14, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 10),
            const SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
            const SizedBox(height: 6),
            const SkeletonBox(width: 160, height: 14, borderRadius: 6),
            const SizedBox(height: 14),
            Row(
              children: const [
                SkeletonBox(width: 72, height: 32, borderRadius: 16),
                SizedBox(width: 8),
                SkeletonBox(width: 72, height: 32, borderRadius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 홈 화면 추천 경로 카드 스켈레톤
class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 100, height: 16, borderRadius: 6),
            const SizedBox(height: 8),
            const SkeletonBox(width: double.infinity, height: 13, borderRadius: 6),
            const SizedBox(height: 4),
            const SkeletonBox(width: 200, height: 13, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// 스켈레톤 목록 (개수 지정 가능)
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.type = SkeletonType.savedRoute});

  final int count;
  final SkeletonType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => type == SkeletonType.savedRoute
            ? const SavedRouteCardSkeleton()
            : const RouteCardSkeleton(),
      ),
    );
  }
}

enum SkeletonType { savedRoute, routeCard }
