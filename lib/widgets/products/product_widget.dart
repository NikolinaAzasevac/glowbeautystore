import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/viewed_recently_provider.dart';
import 'package:glow_beauty_store/screens/inner_screen/product_details.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/products/heart_btn.dart';
import 'package:glow_beauty_store/widgets/products/product_image.dart';
import 'package:glow_beauty_store/widgets/products/product_rating_label.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class ProductWidget extends StatefulWidget {
  const ProductWidget({super.key, required this.productId});

  //final String? image, title, price;

  final String productId;
  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  @override
  Widget build(BuildContext context) {
    //final productModelProvider = Provider.of<ProductModel>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productsProvider.findByProductId(widget.productId);
    final cartProvider = Provider.of<CartProvider>(context);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);
    if (getCurrProduct == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: GestureDetector(
        onTap: () async {
          viewedProdProvider.addOrRemoveFromViewedProd(
            productId: getCurrProduct.productId,
          );
          Navigator.pushNamed(
            context,
            ProductDetailsScreen.routeName,
            arguments: widget.productId,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18.0),
                    ),
                    child: ProductImage(
                      imageUrl: getCurrProduct.productImage,
                      height: 112,
                      width: double.infinity,
                      boxFit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: SubtitleTextWidget(
                        label: _formatProductCategory(
                            getCurrProduct.productCategory),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: HeartButtonWidget(
                      productId: getCurrProduct.productId,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubtitleTextWidget(
                      label: getCurrProduct.productBrand.toUpperCase(),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                    ),
                    const SizedBox(
                      height: 3.0,
                    ),
                    TitelesTextWidget(
                      label: getCurrProduct.productTitle,
                      fontSize: 13,
                      maxLines: 2,
                    ),
                    const SizedBox(
                      height: 4.0,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xfff5b942),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ProductRatingLabel(
                            productId: getCurrProduct.productId,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: SubtitleTextWidget(
                            label: "${getCurrProduct.productPrice} RSD",
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkPrimary,
                            maxLines: 1,
                          ),
                        ),
                        Material(
                          borderRadius: BorderRadius.circular(16.0),
                          color: AppColors.lightPrimary,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.0),
                            onTap: () async {
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
                                  productId: getCurrProduct.productId)) {
                                return;
                              }
                              try {
                                await cartProvider.addToCartFirebase(
                                    productId: getCurrProduct.productId,
                                    qty: 1,
                                    context: context);
                              } catch (e) {
                                await MyAppFunctions.showErrorOrWarningDialog(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  subtitle: e.toString(),
                                  fct: () {},
                                );
                              }
                            },
                            splashColor: Colors.blueGrey,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 8,
                              ),
                              child: Icon(
                                cartProvider.isProdinCart(
                                        productId: getCurrProduct.productId)
                                    ? Icons.check_rounded
                                    : Icons.add_shopping_cart_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
