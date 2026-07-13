import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: const LinearGradient(
          colors: [
            AppColors.darkPrimary,
            Color(0xffe36f9f),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.spa_rounded,
        color: Colors.white,
        size: size * 0.58,
      ),
    );
  }
}
