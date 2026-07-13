import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:glowbeautystore_admin/consts/app_colors.dart';
import 'package:glowbeautystore_admin/consts/app_constants.dart';
import 'package:glowbeautystore_admin/models/admin_order_model.dart';
import 'package:glowbeautystore_admin/services/admin_orders_service.dart';
import 'package:glowbeautystore_admin/widgets/subtitle_text.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';

class OrdersWidgetFree extends StatelessWidget {
  const OrdersWidgetFree({
    super.key,
    required this.order,
    required this.onStatusSelected,
    required this.onDelete,
  });

  final AdminOrderModel order;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onDelete;

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year • $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      case 'shipped':
        return Colors.blue;
      case 'processing':
      case 'packed':
        return Colors.orange;
      default:
        return AppColors.darkPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusColor = _statusColor(order.orderStatus);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FancyShimmerImage(
                    height: size.width * 0.22,
                    width: size.width * 0.22,
                    imageUrl: order.primaryImage.isEmpty
                        ? AppConstants.imageUrl
                        : order.primaryImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitlesTextWidget(
                        label: order.orderTitle,
                        maxLines: 2,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 6),
                      SubtitleTextWidget(
                        label: order.customerName,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 4),
                      SubtitleTextWidget(
                        label:
                            '${order.totalPrice.toStringAsFixed(2)} RSD • ${order.itemCount} items',
                        fontSize: 14,
                        color: AppColors.darkPrimary,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: SubtitleTextWidget(
                          label: order.orderStatus,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == '__delete__') {
                      onDelete();
                      return;
                    }
                    onStatusSelected(value);
                  },
                  itemBuilder: (context) {
                    return [
                      ...AdminOrdersService.statuses.map(
                        (status) => PopupMenuItem<String>(
                          value: status,
                          child: Text('Mark as $status'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: '__delete__',
                        child: Text('Delete order'),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniInfoChip(
                  icon: Icons.schedule_outlined,
                  label: _formatDate(order.createdAt.toDate()),
                ),
                _MiniInfoChip(
                  icon: Icons.local_shipping_outlined,
                  label: order.deliveryMethod,
                ),
                _MiniInfoChip(
                  icon: Icons.credit_card_outlined,
                  label: order.paymentMethod,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const SubtitleTextWidget(
                label: 'View order details',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              children: [
                const SizedBox(height: 8),
                _InfoRow(label: 'Order ID', value: order.orderId),
                _InfoRow(label: 'User ID', value: order.userId),
                _InfoRow(label: 'Email', value: order.customerEmail),
                _InfoRow(label: 'Phone', value: order.phoneNumber),
                _InfoRow(
                  label: 'Address',
                  value: '${order.address}, ${order.city}, ${order.zipCode}',
                ),
                _InfoRow(label: 'Payment status', value: order.paymentStatus),
                const SizedBox(height: 10),
                const SubtitleTextWidget(
                  label: 'Products',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SubtitleTextWidget(
                            label: '${item.productTitle} x${item.quantity}',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SubtitleTextWidget(
                          label: '${item.lineTotal.toStringAsFixed(2)} RSD',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          SubtitleTextWidget(
            label: label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: SubtitleTextWidget(
              label: '$label:',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: SubtitleTextWidget(
              label: value.isEmpty ? '-' : value,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
