import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/order_model.dart';
import 'package:glow_beauty_store/screens/inner_screen/orders/order_details_screen.dart';
import 'package:glow_beauty_store/services/order_ui_helpers.dart';
import 'package:glow_beauty_store/widgets/common/status_badge_row.dart';
import 'package:glow_beauty_store/widgets/orders/order_status_chip.dart';
import 'package:glow_beauty_store/widgets/products/product_image.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class OrdersWidget extends StatelessWidget {
  const OrdersWidget({super.key, required this.ordersModel});
  final OrdersModel ordersModel;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final order = ordersModel;
    final isExpress = isExpressDelivery(order.deliveryMethod);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.pushNamed(
            context,
            OrderDetailsScreen.routeName,
            arguments: order,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ProductImage(
                  height: size.width * 0.24,
                  width: size.width * 0.24,
                  imageUrl: order.primaryImage,
                  boxFit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TitelesTextWidget(
                            label: order.orderTitle,
                            maxLines: 2,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StatusBadgeRow(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OrderStatusChip(
                          label: order.orderStatus,
                          icon: Icons.receipt_long_outlined,
                          compact: true,
                        ),
                        OrderStatusChip(
                          label: order.paymentStatus,
                          icon: Icons.verified_outlined,
                          backgroundColor: const Color(0xffeefbf3),
                          foregroundColor: const Color(0xff0f8a4b),
                          compact: true,
                        ),
                        OrderStatusChip(
                          label: order.deliveryMethod,
                          icon: isExpress
                              ? Icons.local_shipping_outlined
                              : Icons.inventory_2_outlined,
                          backgroundColor: isExpress
                              ? const Color(0xffeef5ff)
                              : const Color(0xfffff8ea),
                          foregroundColor: isExpress
                              ? const Color(0xff2457c5)
                              : const Color(0xffb06a00),
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label:
                          '${order.items.length} product lines • ${order.itemCount} items',
                      fontSize: 13,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SubtitleTextWidget(
                          label: 'Delivery:',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SubtitleTextWidget(
                            label: order.deliveryMethod,
                            fontSize: 13,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SubtitleTextWidget(
                          label: 'Payment:',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SubtitleTextWidget(
                            label:
                                '${order.paymentMethod} • ${order.paymentStatus}',
                            fontSize: 13,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label:
                          'Placed ${formatOrderDate(order.createdAt.toDate())}',
                      fontSize: 13,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${order.address}, ${order.city}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SubtitleTextWidget(
                          label: '${order.totalPrice.toStringAsFixed(2)} RSD',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
