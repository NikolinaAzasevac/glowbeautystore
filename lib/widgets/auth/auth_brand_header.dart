import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: AppColors.lightPrimary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1fad5e82),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'Glow Beauty Store',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
