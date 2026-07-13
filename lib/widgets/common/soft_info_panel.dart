import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/widgets/common/section_card.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';

class SoftInfoPanel extends StatelessWidget {
  const SoftInfoPanel({
    super.key,
    required this.title,
    required this.message,
    this.footer,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor = const Color(0xfffff4f8),
    this.titleColor = AppColors.darkPrimary,
  });

  final String title;
  final String message;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubtitleTextWidget(
            label: title,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
          const SizedBox(height: 6),
          SubtitleTextWidget(
            label: message,
            fontSize: 13,
          ),
          if (footer != null) ...[
            const SizedBox(height: 10),
            footer!,
          ],
        ],
      ),
    );
  }
}
