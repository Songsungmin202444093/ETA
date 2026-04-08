import 'package:flutter/material.dart';

class SurfaceSection extends StatelessWidget {
  const SurfaceSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      ...switch (subtitle) {
                        final subtitleText? => [
                          const SizedBox(height: 4),
                          Text(subtitleText, style: textTheme.bodyMedium),
                        ],
                        null => const <Widget>[],
                      },
                    ],
                  ),
                ),
                ...switch (trailing) {
                  final trailingWidget? => [trailingWidget],
                  null => const <Widget>[],
                },
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}