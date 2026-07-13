import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/product_model.dart';
import 'package:glow_beauty_store/models/product_review_model.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/reviews_provider.dart';
import 'package:glow_beauty_store/providers/user_provider.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/products/heart_btn.dart';
import 'package:glow_beauty_store/widgets/products/latest_arrival.dart';
import 'package:glow_beauty_store/widgets/products/product_image.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  static const routeName = "/ProductDetailsScreen";
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int selectedImageIndex = 0;

  double _averageRating(List<ProductReviewModel> reviews) {
    if (reviews.isEmpty) {
      return 0;
    }
    final total = reviews.fold<int>(
        0, (runningTotal, review) => runningTotal + review.rating);
    return total / reviews.length;
  }

  Future<void> _openReviewSheet({
    required BuildContext context,
    required ProductModel product,
    ProductReviewModel? existingReview,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final reviewsProvider =
        Provider.of<ReviewsProvider>(context, listen: false);
    final reviewController =
        TextEditingController(text: existingReview?.comment ?? '');
    final formKey = GlobalKey<FormState>();
    double rating = (existingReview?.rating ?? 5).toDouble();
    bool isSubmitting = false;
    bool sheetClosed = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitelesTextWidget(
                      label: existingReview == null
                          ? 'Write Review'
                          : 'Edit Review',
                    ),
                    const SizedBox(height: 8),
                    const SubtitleTextWidget(
                      label:
                          'Share your experience to help other Glow Beauty shoppers.',
                      fontSize: 14,
                    ),
                    const SizedBox(height: 16),
                    SubtitleTextWidget(
                      label: 'Rating: ${rating.toStringAsFixed(0)}/5',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                    ),
                    Slider(
                      value: rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: rating.toStringAsFixed(0),
                      activeColor: AppColors.darkPrimary,
                      onChanged: (value) {
                        setModalState(() {
                          rating = value;
                        });
                      },
                    ),
                    TextFormField(
                      controller: reviewController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Your review',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 10
                              ? 'Please write at least 10 characters.'
                              : null,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    setModalState(() {
                                      isSubmitting = true;
                                    });
                                    try {
                                      final userName =
                                          userProvider.getUserModel?.userName ??
                                              FirebaseAuth.instance.currentUser
                                                  ?.displayName ??
                                              'Glow Customer';
                                      if (existingReview == null) {
                                        await reviewsProvider.addReview(
                                          productId: product.productId,
                                          rating: rating.round(),
                                          comment: reviewController.text.trim(),
                                          userName: userName,
                                        );
                                      } else {
                                        await reviewsProvider.updateReview(
                                          reviewId: existingReview.reviewId,
                                          rating: rating.round(),
                                          comment: reviewController.text.trim(),
                                          userName: userName,
                                        );
                                      }
                                      if (!bottomSheetContext.mounted) return;
                                      sheetClosed = true;
                                      Navigator.pop(bottomSheetContext);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      await MyAppFunctions
                                          .showErrorOrWarningDialog(
                                        context: context,
                                        subtitle: e.toString(),
                                        fct: () {},
                                      );
                                    } finally {
                                      if (!sheetClosed && context.mounted) {
                                        setModalState(() {
                                          isSubmitting = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkPrimary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              isSubmitting ? 'Saving...' : 'Save Review',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<int, int> _ratingDistribution(List<ProductReviewModel> reviews) {
    final distribution = <int, int>{for (int i = 1; i <= 5; i++) i: 0};
    for (final review in reviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final productsProvider = Provider.of<ProductsProvider>(context);
    final productId = ModalRoute.of(context)!.settings.arguments as String?;
    final product = productsProvider.findByProductId(productId ?? '');
    final cartProvider = Provider.of<CartProvider>(context);
    final reviewsProvider =
        Provider.of<ReviewsProvider>(context, listen: false);
    final similarProducts = product == null
        ? <ProductModel>[]
        : productsProvider.similarProducts(product: product);
    final recommendedProducts = productsProvider.recommendedProducts
        .where((item) => item.productId != product?.productId)
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
          ),
        ),
        title: const Text("Glow Beauty Store"),
      ),
      body: product == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<ProductReviewModel>>(
              stream: reviewsProvider.reviewsStream(product.productId),
              builder: (context, snapshot) {
                final firestoreReviews =
                    snapshot.data ?? <ProductReviewModel>[];
                final reviews = firestoreReviews.isNotEmpty
                    ? firestoreReviews
                    : product.reviews;
                final averageRating =
                    reviews.isNotEmpty ? _averageRating(reviews) : 0.0;
                final reviewCount = reviews.length;
                final distribution = _ratingDistribution(reviews);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductImage(
                        imageUrl: product.galleryImages[selectedImageIndex],
                        height: size.height * 0.38,
                        width: double.infinity,
                        boxFit: BoxFit.cover,
                      ),
                      if (product.galleryImages.length > 1)
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final imageUrl = product.galleryImages[index];
                              final isSelected = index == selectedImageIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImageIndex = index;
                                  });
                                },
                                child: Container(
                                  width: 72,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.darkPrimary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ProductImage(
                                      imageUrl: imageUrl,
                                      boxFit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemCount: product.galleryImages.length,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(label: product.productBrand),
                                _InfoChip(
                                  label:
                                      "In ${_formatProductCategory(product.productCategory)}",
                                ),
                                _InfoChip(label: product.availabilityStatus),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.productTitle,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SubtitleTextWidget(
                                      label: "${product.productPrice} RSD",
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkPrimary,
                                    ),
                                    if (product.discountPercentage > 0)
                                      SubtitleTextWidget(
                                        label:
                                            "-${product.discountPercentage.toStringAsFixed(0)}% offer",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xfff5b942),
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                SubtitleTextWidget(
                                  label:
                                      "${averageRating.toStringAsFixed(1)} rating",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                const SizedBox(width: 10),
                                SubtitleTextWidget(
                                  label: "$reviewCount reviews",
                                  fontSize: 14,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HeartButtonWidget(
                                    productId: product.productId,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: SizedBox(
                                      height: kBottomNavigationBarHeight - 6,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.darkPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final canContinue =
                                              await MyAppFunctions
                                                  .requireSignedIn(
                                            context: context,
                                            subtitle:
                                                "Please sign in before adding products to your cart.",
                                          );
                                          if (!canContinue) {
                                            return;
                                          }
                                          if (!context.mounted) {
                                            return;
                                          }
                                          if (cartProvider.isProdinCart(
                                            productId: product.productId,
                                          )) {
                                            return;
                                          }
                                          try {
                                            await cartProvider
                                                .addToCartFirebase(
                                              productId: product.productId,
                                              qty: 1,
                                              context: context,
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            await MyAppFunctions
                                                .showErrorOrWarningDialog(
                                              context: context,
                                              subtitle: e.toString(),
                                              fct: () {},
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          cartProvider.isProdinCart(
                                            productId: product.productId,
                                          )
                                              ? Icons.check
                                              : Icons
                                                  .add_shopping_cart_outlined,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          cartProvider.isProdinCart(
                                            productId: product.productId,
                                          )
                                              ? "In cart"
                                              : "Add to cart",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const TitelesTextWidget(label: "Description"),
                            const SizedBox(height: 12),
                            SubtitleTextWidget(
                              label: product.productDescription,
                              fontSize: 15,
                            ),
                            const SizedBox(height: 24),
                            const TitelesTextWidget(label: "Glow Notes"),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: product.tags.isEmpty
                                  ? const [
                                      _InfoChip(label: "beauty"),
                                      _InfoChip(label: "daily glow"),
                                    ]
                                  : product.tags
                                      .map((tag) => _InfoChip(label: tag))
                                      .toList(),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const TitelesTextWidget(label: "Reviews"),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final canContinue =
                                        await MyAppFunctions.requireSignedIn(
                                      context: context,
                                      subtitle:
                                          "Please sign in before writing a review.",
                                    );
                                    if (!canContinue) {
                                      return;
                                    }
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await _openReviewSheet(
                                      context: context,
                                      product: product,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).cardColor,
                                    foregroundColor: AppColors.darkPrimary,
                                  ),
                                  icon: const Icon(Icons.rate_review),
                                  label: const Text("Write Review"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          averageRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < averageRating.round()
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: const Color(0xfff5b942),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SubtitleTextWidget(
                                          label: "$reviewCount total reviews",
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: List.generate(5, (index) {
                                        final star = 5 - index;
                                        final count = distribution[star] ?? 0;
                                        final factor = reviewCount == 0
                                            ? 0.0
                                            : count / reviewCount;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 26,
                                                child: Text('$star'),
                                              ),
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Color(0xfff5b942),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: factor,
                                                    minHeight: 8,
                                                    backgroundColor: Colors.grey
                                                        .withValues(alpha: 0.2),
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                            Color>(
                                                      AppColors.darkPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 24,
                                                child: Text('$count'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (snapshot.hasError)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SubtitleTextWidget(
                                  label: snapshot.error.toString(),
                                  fontSize: 13,
                                  color: Colors.redAccent,
                                ),
                              ),
                            if (reviews.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: SubtitleTextWidget(
                                  label:
                                      "No reviews yet. Be the first to share your experience.",
                                  fontSize: 14,
                                ),
                              ),
                            ...reviews.take(6).map(
                                  (review) => _ReviewCard(
                                    review: review,
                                    isOwnReview: review.userId ==
                                        FirebaseAuth.instance.currentUser?.uid,
                                    onDelete: review.userId ==
                                            FirebaseAuth
                                                .instance.currentUser?.uid
                                        ? () async {
                                            try {
                                              await reviewsProvider
                                                  .deleteReview(
                                                      review.reviewId);
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              await MyAppFunctions
                                                  .showErrorOrWarningDialog(
                                                context: context,
                                                subtitle: e.toString(),
                                                fct: () {},
                                              );
                                            }
                                          }
                                        : null,
                                    onEdit: review.userId ==
                                            FirebaseAuth
                                                .instance.currentUser?.uid
                                        ? () async {
                                            await _openReviewSheet(
                                              context: context,
                                              product: product,
                                              existingReview: review,
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                            if (similarProducts.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const TitelesTextWidget(
                                label: "Similar Products",
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: similarProducts.length,
                                  itemBuilder: (context, index) {
                                    return ChangeNotifierProvider.value(
                                      value: similarProducts[index],
                                      child:
                                          const LatestArrivalProductsWidget(),
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (recommendedProducts.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const TitelesTextWidget(
                                label: "Recommended Products",
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recommendedProducts.length,
                                  itemBuilder: (context, index) {
                                    return ChangeNotifierProvider.value(
                                      value: recommendedProducts[index],
                                      child:
                                          const LatestArrivalProductsWidget(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

String _formatProductCategory(String category) {
  const labels = {
    'beauty': 'Makeup',
    'makeup': 'Makeup',
    'care': 'Care',
    'skin-care': 'Care',
    'face-care': 'Care',
    'body-care': 'Body Care',
    'hair-care': 'Hair Care',
    'nails': 'Nails',
    'fragrances': 'Fragrance',
    'fragrance': 'Fragrance',
    'sun-care': 'Sun Care',
    'dermocosmetics': 'Dermocosmetics',
    'natural': 'Natural',
    'wellness': 'Wellness',
    'accessories': 'Accessories',
    'womens-jewellery': 'Jewelry',
    'sunglasses': 'Sunglasses',
    'womens-bags': 'Bags',
    'devices': 'Devices',
    'oral-care': 'Oral Care',
    'shaving': 'Shaving',
    'gifts': 'Gifts',
  };
  return labels[category.toLowerCase()] ?? category;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SubtitleTextWidget(
        label: label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    this.isOwnReview = false,
    this.onEdit,
    this.onDelete,
  });

  final ProductReviewModel review;
  final bool isOwnReview;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubtitleTextWidget(
                      label: review.reviewerName,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    if (review.date != null)
                      SubtitleTextWidget(
                        label: _formatDate(review.date),
                        fontSize: 12,
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xfff5b942),
                    size: 16,
                  ),
                ),
              ),
              if (isOwnReview) ...[
                IconButton(
                  onPressed: onEdit == null ? null : () async => onEdit!(),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.darkPrimary,
                  ),
                ),
                IconButton(
                  onPressed: onDelete == null ? null : () async => onDelete!(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SubtitleTextWidget(
            label: review.comment,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}
