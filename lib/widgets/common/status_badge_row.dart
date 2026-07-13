import 'package:flutter/material.dart';

class StatusBadgeRow extends StatelessWidget {
  const StatusBadgeRow({
    super.key,
    required this.children,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
