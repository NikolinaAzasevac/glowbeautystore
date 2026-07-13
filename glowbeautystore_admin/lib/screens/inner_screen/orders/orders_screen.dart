import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glowbeautystore_admin/models/admin_order_model.dart';
import 'package:glowbeautystore_admin/screens/inner_screen/orders/orders_widget.dart';
import 'package:glowbeautystore_admin/services/admin_orders_service.dart';
import 'package:glowbeautystore_admin/services/assets_manager.dart';
import 'package:glowbeautystore_admin/services/my_app_functions.dart';
import 'package:glowbeautystore_admin/widgets/empty_bag.dart';
import 'package:glowbeautystore_admin/widgets/subtitle_text.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';

class OrdersScreenFree extends StatefulWidget {
  static const routeName = '/OrderScreen';

  const OrdersScreenFree({super.key});

  @override
  State<OrdersScreenFree> createState() => _OrdersScreenFreeState();
}

class _OrdersScreenFreeState extends State<OrdersScreenFree> {
  final AdminOrdersService _ordersService = AdminOrdersService();

  Future<void> _updateStatus(AdminOrderModel order, String status) async {
    if (order.orderStatus == status) {
      return;
    }
    try {
      await _ordersService.updateOrderStatus(
        orderId: order.orderId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $status')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Unable to update order status.',
        fct: () {},
      );
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  Future<void> _deleteOrder(AdminOrderModel order) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const TitlesTextWidget(label: 'Delete order?'),
              content: SubtitleTextWidget(
                label:
                    'This will permanently delete order ${order.orderId}. Continue?',
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
    if (!shouldDelete) {
      return;
    }

    try {
      await _ordersService.deleteOrder(order.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Unable to delete order.',
        fct: () {},
      );
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TitlesTextWidget(
          label: 'Placed orders',
        ),
      ),
      body: StreamBuilder<List<AdminOrderModel>>(
        stream: _ordersService.ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(snapshot.error.toString()),
              ),
            );
          }

          final orders = snapshot.data ?? <AdminOrderModel>[];
          if (orders.isEmpty) {
            return EmptyBagWidget(
              imagePath: AssetsManager.order,
              title: 'No orders have been placed yet',
              subtitle: 'Customer checkout orders will appear here.',
            );
          }

          final revenue = orders.fold<double>(
            0,
            (runningTotal, order) => runningTotal + order.totalPrice,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TitlesTextWidget(
                        label: 'Orders overview',
                        fontSize: 20,
                      ),
                      const SizedBox(height: 8),
                      SubtitleTextWidget(
                        label:
                            '${orders.length} orders • ${revenue.toStringAsFixed(2)} RSD total revenue',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrdersWidgetFree(
                    order: order,
                    onStatusSelected: (status) => _updateStatus(order, status),
                    onDelete: () => _deleteOrder(order),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
