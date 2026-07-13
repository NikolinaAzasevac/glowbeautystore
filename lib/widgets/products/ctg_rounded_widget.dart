import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/screens/search_screen.dart';

class CategoryRoundedWidget extends StatelessWidget {
  const CategoryRoundedWidget({
    super.key,
    required this.name,
    required this.categoryId,
  });

  final String name;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, SearchScreen.routeName,
            arguments: categoryId);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xfffff6fa),
                  Color(0xfff7e6f0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _categoryIcon(categoryId),
                color: AppColors.darkPrimary,
                size: 34,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkPrimary,
              height: 1.15,
            ),
          )
        ],
      ),
    );
  }

  IconData _categoryIcon(String categoryId) {
    switch (categoryId) {
      case 'makeup':
      case 'beauty':
        return Icons.brush_outlined;
      case 'face-care':
      case 'care':
      case 'skincare':
        return Icons.spa_outlined;
      case 'body-care':
        return Icons.soap_outlined;
      case 'hair-care':
        return Icons.content_cut_outlined;
      case 'nails':
        return Icons.back_hand_outlined;
      case 'fragrance':
        return Icons.local_florist_outlined;
      case 'sun-care':
        return Icons.wb_sunny_outlined;
      case 'dermocosmetics':
        return Icons.health_and_safety_outlined;
      case 'natural':
        return Icons.eco_outlined;
      case 'wellness':
        return Icons.bathtub_outlined;
      case 'accessories':
        return Icons.diamond_outlined;
      case 'devices':
        return Icons.electrical_services_outlined;
      case 'oral-care':
        return Icons.sentiment_satisfied_alt_outlined;
      case 'shaving':
        return Icons.cleaning_services_outlined;
      case 'gifts':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
