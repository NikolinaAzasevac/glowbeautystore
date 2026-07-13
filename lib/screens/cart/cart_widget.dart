import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/cart_model.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/screens/cart/quantity_btm_sheet.dart';
import 'package:glow_beauty_store/widgets/products/heart_btn.dart';
import 'package:glow_beauty_store/widgets/products/product_image.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class CartWidget extends StatelessWidget {
  const CartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cartModel = Provider.of<CartModel>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final currentProduct =
        productsProvider.findByProductId(cartModel.productId);
    final cartProvider = Provider.of<CartProvider>(context);

    if (currentProduct == null) {
      return const SizedBox.shrink();
    }

    final unitPrice = currentProduct.priceValue;
    final lineTotal = unitPrice * cartModel.quantity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ProductImage(
                imageUrl: currentProduct.primaryImage,
                height: size.width * 0.28,
                width: size.width * 0.24,
                boxFit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TitelesTextWidget(
                          label: currentProduct.productTitle,
                          maxLines: 2,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          cartProvider.removeCartItemFromFirestore(
                            cartId: cartModel.cartId,
                            productId: currentProduct.productId,
                            qty: cartModel.quantity,
                          );
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.darkPrimary,
                        ),
                        tooltip: 'Remove from cart',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SubtitleTextWidget(
                    label:
                        "${currentProduct.productBrand} • ${_formatProductCategory(currentProduct.productCategory)}",
                    fontSize: 13,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CartInfoChip(
                        label: "${unitPrice.toStringAsFixed(2)} RSD each",
                      ),
                      _CartInfoChip(
                        label: currentProduct.inStock
                            ? 'In stock'
                            : 'Out of stock',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                              ),
                              context: context,
                              builder: (context) {
                                return QuantityBottomSheetWidget(
                                  cartModel: cartModel,
                                );
                              },
                            );
                          },
                          icon: const Icon(IconlyLight.arrowDown2),
                          label: Text("Qty: ${cartModel.quantity}"),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      HeartButtonWidget(
                        bkgColor: AppColors.darkPrimary,
                        productId: currentProduct.productId,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SubtitleTextWidget(
                        label: "Line total",
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      TitelesTextWidget(
                        label: "${lineTotal.toStringAsFixed(2)} RSD",
                        fontSize: 18,
                        color: AppColors.darkPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

class _CartInfoChip extends StatelessWidget {
  const _CartInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
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
