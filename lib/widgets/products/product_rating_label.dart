import 'package:flutter/material.dart';
import 'package:glow_beauty_store/models/product_review_model.dart';
import 'package:glow_beauty_store/providers/reviews_provider.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:provider/provider.dart';

class ProductRatingLabel extends StatelessWidget {
  const ProductRatingLabel({
    super.key,
    required this.productId,
    this.fontSize = 10,
    this.parenthesizedCount = false,
  });

  final String productId;
  final double fontSize;
  final bool parenthesizedCount;

  @override
  Widget build(BuildContext context) {
    final reviewsProvider = Provider.of<ReviewsProvider>(context);

    return StreamBuilder<List<ProductReviewModel>>(
      stream: reviewsProvider.reviewsStream(productId),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? <ProductReviewModel>[];
        final count = reviews.length;
        final average = count == 0
            ? 0.0
            : reviews.fold<int>(
                  0,
                  (runningTotal, review) => runningTotal + review.rating,
                ) /
                count;
        final label = parenthesizedCount
            ? '${average.toStringAsFixed(1)} ($count)'
            : '${average.toStringAsFixed(1)} • $count';

        return SubtitleTextWidget(
          label: label,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          maxLines: 1,
        );
      },
    );
  }
}
