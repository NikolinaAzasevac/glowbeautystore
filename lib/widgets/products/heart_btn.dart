import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/providers/wishlist_provider.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';

class HeartButtonWidget extends StatefulWidget {
  const HeartButtonWidget({
    super.key,
    this.bkgColor = Colors.transparent,
    this.size = 20,
    required this.productId,
    //this.isInWishlist,
  });
  final Color bkgColor;
  final double size;
  final String productId;
  //final bool? isInWishlist;
  @override
  State<HeartButtonWidget> createState() => _HeartButtonWidgetState();
}

class _HeartButtonWidgetState extends State<HeartButtonWidget> {
  @override
  Widget build(BuildContext context) {
    final wishlistsProvider = Provider.of<WishlistProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: widget.bkgColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        style: IconButton.styleFrom(elevation: 10),
        onPressed: () async {
          final canContinue = await MyAppFunctions.requireSignedIn(
            context: context,
            subtitle: "Please sign in before saving products to your wishlist.",
          );
          if (!canContinue) {
            return;
          }
          if (!context.mounted) {
            return;
          }
          // wishlistsProvider.addOrRemoveFromWishlist(
          //   productId: widget.productId,
          // );
          if (wishlistsProvider.getWishlists.containsKey(widget.productId)) {
            await wishlistsProvider.removeWishlistItemFromFirestore(
              wishlistId:
                  wishlistsProvider.getWishlists[widget.productId]!.wishlistId,
              productId: widget.productId,
            );
          } else {
            await wishlistsProvider.addToWishlistFirebase(
              productId: widget.productId,
              context: context,
            );
          }
          await wishlistsProvider.fetchWishlist();
        },
        icon: Icon(
          wishlistsProvider.isProdinWishlist(
            productId: widget.productId,
          )
              ? IconlyBold.heart
              : IconlyLight.heart,
          size: widget.size,
          color: wishlistsProvider.isProdinWishlist(
            productId: widget.productId,
          )
              ? AppColors.lightPrimary
              : AppColors.darkPrimary,
        ),
      ),
    );
  }
}
