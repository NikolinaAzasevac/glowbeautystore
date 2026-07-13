import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glowbeautystore_admin/models/admin_order_model.dart';

class AdminOrdersService {
  static const List<String> statuses = <String>[
    'Paid',
    'Processing',
    'Packed',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  final CollectionReference<Map<String, dynamic>> _ordersDb =
      FirebaseFirestore.instance.collection('orders');

  Stream<List<AdminOrderModel>> ordersStream() {
    return _ordersDb
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminOrderModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _ordersDb.doc(orderId).update({
      'orderStatus': status,
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await _ordersDb.doc(orderId).delete();
  }
}
