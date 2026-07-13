import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/order_model.dart';
import 'package:glow_beauty_store/providers/order_provider.dart';
import 'package:glow_beauty_store/screens/inner_screen/orders/orders_widget.dart';
import 'package:glow_beauty_store/screens/root_screen.dart';
import 'package:glow_beauty_store/services/order_ui_helpers.dart';
import 'package:glow_beauty_store/services/assets_manager.dart';
import 'package:glow_beauty_store/widgets/common/section_card.dart';
import 'package:glow_beauty_store/widgets/common/status_badge_row.dart';
import 'package:glow_beauty_store/widgets/empty_bag.dart';
import 'package:glow_beauty_store/widgets/orders/order_status_chip.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/OrdersScreen';
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrdersModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<OrdersModel>> _fetchOrders() {
    return Provider.of<OrderProvider>(context, listen: false).fetchOrder();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrderProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: const TitelesTextWidget(
            label: 'My Orders',
          ),
        ),
        body: FutureBuilder<List<OrdersModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: SelectableText(snapshot.error.toString()),
              );
            } else if (!snapshot.hasData || ordersProvider.getOrders.isEmpty) {
              return EmptyBagWidget(
                imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
                title: "No orders yet",
                subtitle: "Your completed checkout orders will appear here.",
                buttonText: "Shop now",
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RootScreen.routeName,
                    (route) => false,
                  );
                },
              );
            }
            final orders = ordersProvider.getOrders;
            final totalSpent = orders.fold<double>(
              0,
              (sum, order) => sum + order.totalPrice,
            );
            final latestOrder = orders.first;
            return RefreshIndicator(
              color: AppColors.darkPrimary,
              onRefresh: _refreshOrders,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: orders.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == 0) {
                    return SectionCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TitelesTextWidget(
                            label: 'Orders Overview',
                            fontSize: 20,
                          ),
                          const SizedBox(height: 8),
                          const SubtitleTextWidget(
                            label:
                                'Track your recent purchases, delivery progress and payment status.',
                            fontSize: 14,
                          ),
                          const SizedBox(height: 14),
                          StatusBadgeRow(
                            children: [
                              _OrdersMetricChip(
                                label: '${orders.length} orders',
                                icon: Icons.inventory_2_outlined,
                              ),
                              _OrdersMetricChip(
                                label:
                                    '${totalSpent.toStringAsFixed(2)} RSD spent',
                                icon: Icons.payments_outlined,
                                backgroundColor: const Color(0xffeefbf3),
                                foregroundColor: const Color(0xff0f8a4b),
                              ),
                              _OrdersMetricChip(
                                label:
                                    'Latest ${formatOrderDate(latestOrder.createdAt.toDate(), includeTime: false)}',
                                icon: Icons.schedule_outlined,
                                backgroundColor: const Color(0xffeef5ff),
                                foregroundColor: const Color(0xff2457c5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  final order = orders[index - 1];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    child: OrdersWidget(ordersModel: order),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(
                      // thickness: 8,
                      // color: Colors.red,
                      );
                },
              ),
            );
          },
        ));
  }
}

class _OrdersMetricChip extends StatelessWidget {
  const _OrdersMetricChip({
    required this.label,
    required this.icon,
    this.backgroundColor = const Color(0xfffff4f8),
    this.foregroundColor = AppColors.darkPrimary,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return OrderStatusChip(
      label: label,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
