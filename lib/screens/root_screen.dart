import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/user_provider.dart';
import 'package:glow_beauty_store/providers/wishlist_provider.dart';
import 'package:glow_beauty_store/screens/cart/cart_screen.dart';
import 'package:glow_beauty_store/screens/home_screen.dart';
import 'package:glow_beauty_store/screens/profile_screen.dart';
import 'package:glow_beauty_store/screens/search_screen.dart';

class RootScreen extends StatefulWidget {
  static const String routeName = "/RootScreen";
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late List<Widget> screens;
  int currentScreen = 0;
  late PageController controller;
  bool isLoadingProd = true;
  @override
  void initState() {
    super.initState();

    screens = const [
      HomeScreen(),
      SearchScreen(),
      CartScreen(),
      ProfileScreen(),
    ];
    controller = PageController(initialPage: currentScreen);
  }

  Future<void> fetchFCT() async {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistsProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await Future.wait([
        productsProvider.fetchProducts(),
        userProvider.fetchUserInfo(),
        cartProvider.fetchCart(),
        wishlistsProvider.fetchWishlist(),
      ]);
    } catch (error) {
      log(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoadingProd = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    if (isLoadingProd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && isLoadingProd) {
          fetchFCT();
        }
      });
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    if (isLoadingProd) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentScreen,
        height: kBottomNavigationBarHeight,
        onDestinationSelected: (index) {
          setState(() {
            currentScreen = index;
          });
          controller.jumpToPage(currentScreen);
        },
        destinations: [
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.home),
            icon: Icon(IconlyLight.home),
            label: "Home",
          ),
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.search),
            icon: Icon(IconlyLight.search),
            label: "Search",
          ),
          NavigationDestination(
            selectedIcon: const Icon(IconlyBold.bag2),
            icon: Badge(
                isLabelVisible: cartProvider.getCartitems.isNotEmpty,
                backgroundColor: AppColors.darkPrimary,
                label: Text(cartProvider.getCartitems.length.toString()),
                child: const Icon(IconlyLight.bag2)),
            label: "Cart",
          ),
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.profile),
            icon: Icon(IconlyLight.profile),
            label: "Profile",
          )
        ],
      ),
    );
  }
}
