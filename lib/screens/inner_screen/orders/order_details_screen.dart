import 'package:flutter/material.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/order_model.dart';
import 'package:glow_beauty_store/services/order_ui_helpers.dart';
import 'package:glow_beauty_store/widgets/common/section_card.dart';
import 'package:glow_beauty_store/widgets/common/status_badge_row.dart';
import 'package:glow_beauty_store/widgets/orders/order_status_chip.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class OrderDetailsScreen extends StatelessWidget {
  static const routeName = '/OrderDetailsScreen';
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrdersModel;
    final isExpress = isExpressDelivery(order.deliveryMethod);
    return Scaffold(
      appBar: AppBar(
        title: const TitelesTextWidget(label: 'Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: TitelesTextWidget(
                        label: 'Order Summary',
                        fontSize: 20,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfffff1f7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: SubtitleTextWidget(
                        label: order.orderStatus,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StatusBadgeRow(
                  children: [
                    OrderStatusChip(
                      label: order.orderStatus,
                      icon: Icons.receipt_long_outlined,
                    ),
                    OrderStatusChip(
                      label: order.paymentStatus,
                      icon: Icons.verified_outlined,
                      backgroundColor: const Color(0xffeefbf3),
                      foregroundColor: const Color(0xff0f8a4b),
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
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SubtitleTextWidget(
                  label: 'Order ID: ${order.orderId}',
                  fontSize: 13,
                ),
                const SizedBox(height: 6),
                SubtitleTextWidget(
                  label: 'Placed ${formatOrderDate(order.createdAt.toDate())}',
                  fontSize: 13,
                ),
                const SizedBox(height: 6),
                SubtitleTextWidget(
                  label: '${order.paymentMethod} • ${order.paymentStatus}',
                  fontSize: 13,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            key: const PageStorageKey('order_items_tile'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            backgroundColor: Theme.of(context).cardColor,
            collapsedBackgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const TitelesTextWidget(
              label: 'Products',
              fontSize: 18,
            ),
            subtitle: SubtitleTextWidget(
              label: '${order.items.length} lines • ${order.itemCount} items',
              fontSize: 13,
            ),
            children: order.items
                .map(
                  (item) => ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    title: SubtitleTextWidget(
                      label: item.productTitle,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    subtitle: SubtitleTextWidget(
                      label:
                          'Qty ${item.quantity} • ${item.unitPrice.toStringAsFixed(2)} RSD',
                      fontSize: 13,
                    ),
                    trailing: SubtitleTextWidget(
                      label: '${item.lineTotal.toStringAsFixed(2)} RSD',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TitelesTextWidget(
                    label: 'Shipping Information', fontSize: 18),
                const SizedBox(height: 12),
                StatusBadgeRow(
                  children: [
                    OrderStatusChip(
                      label: isExpress
                          ? 'Express delivery selected'
                          : 'Standard delivery selected',
                      icon: isExpress
                          ? Icons.bolt_outlined
                          : Icons.schedule_outlined,
                      backgroundColor: isExpress
                          ? const Color(0xffeef5ff)
                          : const Color(0xfffff8ea),
                      foregroundColor: isExpress
                          ? const Color(0xff2457c5)
                          : const Color(0xffb06a00),
                    ),
                    const OrderStatusChip(
                      label: 'Shipping address on file',
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Full Name', value: order.customerName),
                _DetailRow(label: 'Email', value: order.customerEmail),
                _DetailRow(label: 'Phone', value: order.phoneNumber),
                _DetailRow(label: 'Address', value: order.address),
                _DetailRow(label: 'City', value: order.city),
                _DetailRow(label: 'ZIP Code', value: order.zipCode),
                _DetailRow(label: 'Delivery', value: order.deliveryMethod),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TitelesTextWidget(label: 'Payment Summary', fontSize: 18),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'Subtotal',
                  value: '${order.subtotal.toStringAsFixed(2)} RSD',
                ),
                _SummaryRow(
                  label: 'Shipping',
                  value: '${order.shippingFee.toStringAsFixed(2)} RSD',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total',
                  value: '${order.totalPrice.toStringAsFixed(2)} RSD',
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: SubtitleTextWidget(
              label: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: SubtitleTextWidget(
              label: value,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.darkPrimary,
          )
        : const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
