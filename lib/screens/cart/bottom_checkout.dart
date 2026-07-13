import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class CartBottomSheetWidget extends StatelessWidget {
  const CartBottomSheetWidget({super.key, required this.function});

  final Function function;

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final total = cartProvider
        .getTotal(productsProvider: productsProvider)
        .toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubtitleTextWidget(
                      label: "Checkout Summary",
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                    ),
                    const SizedBox(height: 6),
                    TitelesTextWidget(
                      label: "$total RSD",
                      fontSize: 24,
                    ),
                    const SizedBox(height: 4),
                    SubtitleTextWidget(
                      label:
                          "${cartProvider.getCartitems.length} products • ${cartProvider.getQty()} items",
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await function();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text("Proceed"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
