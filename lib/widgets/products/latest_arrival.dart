import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/product_model.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/viewed_recently_provider.dart';
import 'package:glow_beauty_store/screens/inner_screen/product_details.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/products/heart_btn.dart';
import 'package:glow_beauty_store/widgets/products/product_image.dart';
import 'package:glow_beauty_store/widgets/products/product_rating_label.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';

class LatestArrivalProductsWidget extends StatelessWidget {
  const LatestArrivalProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () async {
          viewedProdProvider.addOrRemoveFromViewedProd(
            productId: productModel.productId,
          );
          Navigator.pushNamed(context, ProductDetailsScreen.routeName,
              arguments: productModel.productId);
        },
        child: SizedBox(
          width: size.width * 0.72,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18.0),
                  child: ProductImage(
                    imageUrl: productModel.productImage,
                    height: size.width * 0.24,
                    width: size.width * 0.24,
                    boxFit: BoxFit.cover,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubtitleTextWidget(
                        label: productModel.productBrand.toUpperCase(),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary,
                        maxLines: 1,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        productModel.productTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xfff5b942),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ProductRatingLabel(
                              productId: productModel.productId,
                              fontSize: 11,
                              parenthesizedCount: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: SubtitleTextWidget(
                              label: "${productModel.productPrice} RSD",
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkPrimary,
                              maxLines: 1,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HeartButtonWidget(
                                productId: productModel.productId,
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: () async {
                                  final canContinue =
                                      await MyAppFunctions.requireSignedIn(
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
                                      productId: productModel.productId)) {
                                    return;
                                  }
                                  try {
                                    await cartProvider.addToCartFirebase(
                                        productId: productModel.productId,
                                        qty: 1,
                                        context: context);
                                  } catch (e) {
                                    await MyAppFunctions
                                        .showErrorOrWarningDialog(
                                      // ignore: use_build_context_synchronously
                                      context: context,
                                      subtitle: e.toString(),
                                      fct: () {},
                                    );
                                  }
                                },
                                icon: Icon(
                                  cartProvider.isProdinCart(
                                          productId: productModel.productId)
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: AppColors.darkPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      StatusBadgeLine(
                        isInStock: productModel.inStock,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadgeLine extends StatelessWidget {
  const StatusBadgeLine({super.key, required this.isInStock});

  final bool isInStock;

  @override
  Widget build(BuildContext context) {
    return SubtitleTextWidget(
      label: isInStock ? "In stock" : "Out of stock",
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isInStock ? Colors.green : Colors.redAccent,
      maxLines: 1,
    );
  }
}
