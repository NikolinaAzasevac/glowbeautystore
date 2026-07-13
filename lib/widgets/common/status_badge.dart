import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor = const Color(0xfffff4f8),
    this.foregroundColor = AppColors.darkPrimary,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: compact ? 16 : 18,
        color: foregroundColor,
      ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      label: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
      materialTapTargetSize: compact
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: compact ? EdgeInsets.zero : null,
    );
  }
}
