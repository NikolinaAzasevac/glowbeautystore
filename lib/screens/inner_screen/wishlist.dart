import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/wishlist_provider.dart';
import 'package:glow_beauty_store/screens/root_screen.dart';
import 'package:glow_beauty_store/services/assets_manager.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/empty_bag.dart';
import 'package:glow_beauty_store/widgets/products/product_widget.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class WishlistScreen extends StatefulWidget {
  static const routeName = "/WishlistScreen";
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _cleanupScheduled = false;

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final wishlistItems = wishlistProvider.getWishlists.values.toList();
    final visibleWishlistItems = wishlistItems
        .where(
            (item) => productsProvider.findByProductId(item.productId) != null)
        .toList();
    final staleWishlistItems = wishlistItems
        .where(
            (item) => productsProvider.findByProductId(item.productId) == null)
        .toList();

    if (staleWishlistItems.isNotEmpty && !_cleanupScheduled) {
      _cleanupScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await wishlistProvider.removeStaleWishlistItemsFromFirestore(
          staleItems: staleWishlistItems,
        );
        if (mounted) {
          _cleanupScheduled = false;
        }
      });
    }

    return visibleWishlistItems.isEmpty
        ? Scaffold(
            body: EmptyBagWidget(
              imagePath: "${AssetsManager.imagePath}/bag/wishlist.png",
              title: "Your wishlist is empty",
              subtitle: "Save products you love and they will appear here.",
              buttonText: "Shop now",
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RootScreen.routeName,
                  (route) => false,
                );
              },
            ),
          )
        : Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  "${AssetsManager.imagePath}/bag/wishlist.png",
                ),
              ),
              title: TitelesTextWidget(
                  label: "Wishlist (${visibleWishlistItems.length})"),
              actions: [
                IconButton(
                  onPressed: () {
                    MyAppFunctions.showErrorOrWarningDialog(
                      isError: false,
                      context: context,
                      subtitle: "Clear wishlist?",
                      fct: () async {
                        await wishlistProvider.clearWishlistFromFirebase();
                        //wishlistProvider.clearLocalWishlist();
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                  ),
                ),
              ],
            ),
            body: DynamicHeightGridView(
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              builder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ProductWidget(
                    productId: visibleWishlistItems[index].productId,
                  ),
                );
              },
              itemCount: visibleWishlistItems.length,
              crossAxisCount: 2,
            ),
          );
  }
}
