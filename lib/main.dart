import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/theme_data.dart';
import 'package:glow_beauty_store/providers/addresses_provider.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/order_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/reviews_provider.dart';
import 'package:glow_beauty_store/providers/theme_provider.dart';
import 'package:glow_beauty_store/providers/user_provider.dart';
import 'package:glow_beauty_store/providers/viewed_recently_provider.dart';
import 'package:glow_beauty_store/providers/wishlist_provider.dart';
import 'package:glow_beauty_store/screens/admin/admin_panel_screen.dart';
import 'package:glow_beauty_store/screens/auth/forgot_password.dart';
import 'package:glow_beauty_store/screens/auth/login.dart';
import 'package:glow_beauty_store/screens/auth/register.dart';
import 'package:glow_beauty_store/screens/cart/checkout_screen.dart';
import 'package:glow_beauty_store/screens/inner_screen/orders/order_details_screen.dart';
import 'package:glow_beauty_store/screens/inner_screen/orders/orders_screen.dart';
import 'package:glow_beauty_store/screens/inner_screen/product_details.dart';
import 'package:glow_beauty_store/screens/inner_screen/viewed_recently.dart';
import 'package:glow_beauty_store/screens/inner_screen/wishlist.dart';
import 'package:glow_beauty_store/screens/profile/currency_rates_screen.dart';
import 'package:glow_beauty_store/screens/profile/saved_addresses_screen.dart';
import 'package:glow_beauty_store/screens/root_screen.dart';
import 'package:glow_beauty_store/screens/search_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint(details.exceptionAsString());
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Unhandled platform error: $error');
        debugPrintStack(stackTrace: stack);
        return true;
      };
      final appInitialization = Firebase.initializeApp();
      runApp(
        MyApp(
          appInitialization: appInitialization,
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.appInitialization,
  });

  final Future<FirebaseApp> appInitialization;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: appInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body:
                      Center(child: SelectableText(snapshot.error.toString()))),
            );
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) {
                return ThemeProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return ProductsProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return CartProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return AddressesProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return WishlistProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return ViewedProdProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return UserProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return OrderProvider();
              }),
              ChangeNotifierProvider(create: (_) {
                return ReviewsProvider();
              }),
            ],
            child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
              return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Glow Beauty Store',
                  theme: Styles.themeData(
                      isDarkTheme: themeProvider.getIsDarkTheme,
                      context: context),
                  home: const RootScreen(),
                  routes: {
                    RootScreen.routeName: (context) => const RootScreen(),
                    ProductDetailsScreen.routeName: (context) =>
                        const ProductDetailsScreen(),
                    WishlistScreen.routeName: (context) =>
                        const WishlistScreen(),
                    ViewedRecentlyScreen.routeName: (context) =>
                        const ViewedRecentlyScreen(),
                    RegisterScreen.routeName: (context) =>
                        const RegisterScreen(),
                    LoginScreen.routeName: (context) => const LoginScreen(),
                    OrdersScreen.routeName: (context) => const OrdersScreen(),
                    OrderDetailsScreen.routeName: (context) =>
                        const OrderDetailsScreen(),
                    CheckoutScreen.routeName: (context) =>
                        const CheckoutScreen(),
                    ForgotPasswordScreen.routeName: (context) =>
                        const ForgotPasswordScreen(),
                    SearchScreen.routeName: (context) => const SearchScreen(),
                    SavedAddressesScreen.routeName: (context) =>
                        const SavedAddressesScreen(),
                    AdminPanelScreen.routeName: (context) =>
                        const AdminPanelScreen(),
                    CurrencyRatesScreen.routeName: (context) =>
                        const CurrencyRatesScreen(),
                  });
            }),
          );
        });
  }
}
