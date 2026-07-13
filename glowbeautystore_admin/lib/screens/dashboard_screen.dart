import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowbeautystore_admin/models/dashboard_btn_model.dart';
import 'package:glowbeautystore_admin/providers/theme_provider.dart';
import 'package:glowbeautystore_admin/services/assets_manager.dart';
import 'package:glowbeautystore_admin/widgets/dashboard_btns.dart';
import 'package:glowbeautystore_admin/widgets/subtitle_text.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/DashboardScreen';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> _collectionCountStream(String collection) {
    return _firestore.collection(collection).snapshots().map(
          (snapshot) => snapshot.docs.length,
        );
  }

  Stream<double> _ordersRevenueStream() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs.fold<double>(0, (runningTotal, doc) {
        final data = doc.data();
        final rawTotal = data['totalPrice'];
        final total = rawTotal is num
            ? rawTotal.toDouble()
            : double.tryParse(rawTotal?.toString() ?? '') ?? 0;
        return runningTotal + total;
      });
    });
  }

  Widget _buildCountCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Stream<String> stream,
    required String subtitle,
  }) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? '--';
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(height: 16),
              SubtitleTextWidget(
                label: title,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 6),
              TitlesTextWidget(
                label: value,
                fontSize: 26,
              ),
              const SizedBox(height: 6),
              SubtitleTextWidget(
                label: subtitle,
                fontSize: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dashboardButtons = DashboardButtonsModel.dashboardBtnList(context);

    return Scaffold(
      appBar: AppBar(
        title: const TitlesTextWidget(label: 'Admin Control Center'),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              AssetsManager.shoppingCart,
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              themeProvider.setDarkTheme(
                themeValue: !themeProvider.getIsDarkTheme,
              );
            },
            icon: Icon(
              themeProvider.getIsDarkTheme ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff1f2937),
                    Color(0xff374151),
                    Color(0xff4b5563),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 26,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubtitleTextWidget(
                    label: 'GLOW BEAUTY ADMIN',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 10),
                  TitlesTextWidget(
                    label: 'Track users, products and orders from one place.',
                    fontSize: 28,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  SubtitleTextWidget(
                    label:
                        'Use the dashboard below to manage the store, adjust roles and keep orders moving.',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const TitlesTextWidget(
              label: 'Live Overview',
              fontSize: 22,
            ),
            const SizedBox(height: 6),
            const SubtitleTextWidget(
              label: 'Real-time insight into the current state of the store.',
              fontSize: 14,
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.96,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCountCard(
                  title: 'Products',
                  icon: Icons.inventory_2_outlined,
                  accentColor: const Color(0xffc2410c),
                  stream: _collectionCountStream('products')
                      .map((value) => value.toString()),
                  subtitle: 'Items available in catalog',
                ),
                _buildCountCard(
                  title: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  accentColor: const Color(0xff2563eb),
                  stream: _collectionCountStream('orders')
                      .map((value) => value.toString()),
                  subtitle: 'Customer orders recorded',
                ),
                _buildCountCard(
                  title: 'Users',
                  icon: Icons.group_outlined,
                  accentColor: const Color(0xff059669),
                  stream: _collectionCountStream('users')
                      .map((value) => value.toString()),
                  subtitle: 'Registered accounts',
                ),
                _buildCountCard(
                  title: 'Revenue',
                  icon: Icons.payments_outlined,
                  accentColor: const Color(0xff7c3aed),
                  stream: _ordersRevenueStream()
                      .map((value) => '${value.toStringAsFixed(0)} RSD'),
                  subtitle: 'Total order value so far',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const TitlesTextWidget(
              label: 'Quick Actions',
              fontSize: 22,
            ),
            const SizedBox(height: 6),
            const SubtitleTextWidget(
              label: 'Jump straight into the main administration tasks.',
              fontSize: 14,
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                dashboardButtons.length,
                (index) => DashboardButtonsWidget(
                  text: dashboardButtons[index].text,
                  imagePath: dashboardButtons[index].imagePath,
                  onPressed: dashboardButtons[index].onPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
