import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowbeautystore_admin/consts/theme_data.dart';
import 'package:glowbeautystore_admin/providers/products_provider.dart';
import 'package:glowbeautystore_admin/providers/theme_provider.dart';
import 'package:glowbeautystore_admin/screens/admin_login_screen.dart';
import 'package:glowbeautystore_admin/screens/dashboard_screen.dart';
import 'package:glowbeautystore_admin/screens/edit_upload_product_from.dart';
import 'package:glowbeautystore_admin/screens/inner_screen/orders/orders_screen.dart';
import 'package:glowbeautystore_admin/screens/search_screen.dart';
import 'package:glowbeautystore_admin/screens/users_management_screen.dart';
import 'package:glowbeautystore_admin/services/admin_role_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(),
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
            ],
            child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Glow Beauty Admin',
                theme: Styles.themeData(
                    isDarkTheme: themeProvider.getIsDarkTheme,
                    context: context),
                home: const AdminAppGate(),
                routes: {
                  OrdersScreenFree.routeName: (context) =>
                      const OrdersScreenFree(),
                  SearchScreen.routeName: (context) => const SearchScreen(),
                  EditOrUploadProductScreen.routeName: (context) =>
                      const EditOrUploadProductScreen(),
                  UsersManagementScreen.routeName: (context) =>
                      const UsersManagementScreen(),
                },
              );
            }),
          );
        });
  }
}

class AdminAppGate extends StatelessWidget {
  const AdminAppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const AdminLoginScreen();
        }

        return FutureBuilder<bool>(
          future: AdminRoleService.isAdminUser(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (roleSnapshot.data == true) {
              return const DashboardScreen();
            }

            return const UnauthorizedAdminScreen();
          },
        );
      },
    );
  }
}
