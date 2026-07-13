import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/screens/cart/bottom_checkout.dart';
import 'package:glow_beauty_store/screens/cart/checkout_screen.dart';
import 'package:glow_beauty_store/screens/cart/cart_widget.dart';
import 'package:glow_beauty_store/screens/root_screen.dart';
import 'package:glow_beauty_store/services/assets_manager.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/common/brand_mark.dart';
import 'package:glow_beauty_store/widgets/empty_bag.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);

    if (cartProvider.getCartitems.isEmpty) {
      return Scaffold(
        body: EmptyBagWidget(
          imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
          title: "Your cart is empty",
          subtitle: "Looks like you have not added anything to your cart yet.",
          buttonText: "Shop now",
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RootScreen.routeName,
              (route) => false,
            );
          },
        ),
      );
    }

    final total = cartProvider.getTotal(productsProvider: productsProvider);

    return Scaffold(
      bottomSheet: CartBottomSheetWidget(function: () async {
        final canContinue = await MyAppFunctions.requireSignedIn(
          context: context,
          subtitle: "Please sign in before checkout.",
        );
        if (!canContinue) {
          return;
        }
        if (!context.mounted) {
          return;
        }
        await Navigator.pushNamed(context, CheckoutScreen.routeName);
      }),
      appBar: AppBar(
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: BrandMark(size: 52),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TitelesTextWidget(
              label: "Cart (${cartProvider.getCartitems.length})",
              fontSize: 18,
            ),
            SubtitleTextWidget(
              label: "${cartProvider.getQty()} items ready for checkout",
              fontSize: 12,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              MyAppFunctions.showErrorOrWarningDialog(
                isError: false,
                context: context,
                subtitle: "Clear cart?",
                fct: () async {
                  cartProvider.clearCartFromFirebase();
                },
              );
            },
            icon: const Icon(Icons.delete_forever_rounded),
            tooltip: 'Clear cart',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xffffeff6),
                    Color(0xfff6e7f7),
                    Color(0xfffffbfd),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                  const SubtitleTextWidget(
                    label: "BAG SUMMARY",
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkPrimary,
                  ),
                  const SizedBox(height: 10),
                  const TitelesTextWidget(
                    label: "Everything you picked for your next glow-up.",
                    fontSize: 26,
                  ),
                  const SizedBox(height: 10),
                  const SubtitleTextWidget(
                    label:
                        "Review your selection, adjust quantities and proceed to checkout when you are ready.",
                    fontSize: 14,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CartSummaryChip(
                        label: "${cartProvider.getCartitems.length} products",
                      ),
                      _CartSummaryChip(
                        label: "${cartProvider.getQty()} items",
                      ),
                      _CartSummaryChip(
                        label: "${total.toStringAsFixed(2)} RSD total",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...cartProvider.getCartitems.values.map(
            (cartItem) => ChangeNotifierProvider.value(
              value: cartItem,
              child: const CartWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryChip extends StatelessWidget {
  const _CartSummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SubtitleTextWidget(
        label: label,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
