import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.boxFit = BoxFit.cover,
  });

  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit boxFit;

  @override
  Widget build(BuildContext context) {
    return FancyShimmerImage(
      imageUrl: imageUrl,
      height: height ?? 300,
      width: width ?? 300,
      boxFit: boxFit,
      errorWidget: Container(
        height: height ?? 300,
        width: width ?? 300,
        color: const Color(0xffffedf5),
        child: const Center(
          child: Icon(
            Icons.spa_outlined,
            color: AppColors.darkPrimary,
            size: 34,
          ),
        ),
      ),
    );
  }
}
