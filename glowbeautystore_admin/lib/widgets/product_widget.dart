import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowbeautystore_admin/consts/app_colors.dart';
import 'package:glowbeautystore_admin/providers/products_provider.dart';
import 'package:glowbeautystore_admin/screens/edit_upload_product_from.dart';
import 'package:glowbeautystore_admin/services/my_app_functions.dart';

import 'subtitle_text.dart';
import 'title_text.dart';

class ProductWidget extends StatelessWidget {
  const ProductWidget({
    super.key,
    required this.productId,
  });

  final String productId;

  Future<void> _deleteProduct(
    BuildContext context,
    ProductsProvider productsProvider,
  ) async {
    final product = productsProvider.findByProductId(productId);
    if (product == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const TitlesTextWidget(label: 'Delete product?'),
              content: SubtitleTextWidget(
                label:
                    'This will remove "${product.productTitle}" from Firestore. Continue?',
                fontSize: 14,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || !context.mounted) {
      return;
    }

    try {
      await productsProvider.deleteProduct(productId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Unable to delete product.',
        fct: () {},
      );
    } catch (error) {
      if (!context.mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final currentProduct = productsProvider.findByProductId(productId);
    final size = MediaQuery.of(context).size;

    if (currentProduct == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return EditOrUploadProductScreen(
                    productModel: currentProduct,
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FancyShimmerImage(
                        imageUrl: currentProduct.productImage,
                        height: size.height * 0.2,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton<String>(
                        color: Theme.of(context).cardColor,
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return EditOrUploadProductScreen(
                                    productModel: currentProduct,
                                  );
                                },
                              ),
                            );
                            return;
                          }
                          _deleteProduct(context, productsProvider);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit product'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete product'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TitlesTextWidget(
                  label: currentProduct.productTitle,
                  fontSize: 18,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                SubtitleTextWidget(
                  label: "${currentProduct.productPrice} RSD",
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPrimary,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProductMetaChip(label: currentProduct.productCategory),
                    _ProductMetaChip(
                      label:
                          currentProduct.inStock ? 'In stock' : 'Out of stock',
                    ),
                    if (currentProduct.isFeatured)
                      const _ProductMetaChip(label: 'Featured'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductMetaChip extends StatelessWidget {
  const _ProductMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
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
