import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glow_beauty_store/models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final List<OrdersModel> orders = [];
  List<OrdersModel> get getOrders => orders;

  Future<List<OrdersModel>> fetchOrder() async {
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      orders.clear();
      notifyListeners();
      return orders;
    }
    var uid = user.uid;
    try {
      await FirebaseFirestore.instance
          .collection("orders")
          .where('userId', isEqualTo: uid)
          .get()
          .then((orderSnapshot) {
        orders.clear();
        for (var element in orderSnapshot.docs) {
          orders.add(OrdersModel.fromFirestore(element));
        }
        orders.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
      });
      notifyListeners();
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOrder({
    required String userId,
    required String userName,
    required String customerEmail,
    required String fullName,
    required String phoneNumber,
    required String address,
    required String city,
    required String zipCode,
    required String deliveryMethod,
    required String paymentMethod,
    required double subtotal,
    required double shippingFee,
    required double totalPrice,
    required List<OrderLineItem> items,
  }) async {
    final orderRef = FirebaseFirestore.instance.collection("orders").doc();
    await orderRef.set({
      'orderId': orderRef.id,
      'userId': userId,
      'userName': userName,
      'products': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'totalPrice': totalPrice,
      'deliveryMethod': deliveryMethod,
      'paymentMethod': paymentMethod,
      'orderStatus': 'Paid',
      'paymentStatus': 'Paid',
      'createdAt': Timestamp.now(),
      'shippingInfo': {
        'fullName': fullName,
        'email': customerEmail,
        'phoneNumber': phoneNumber,
        'address': address,
        'city': city,
        'zipCode': zipCode,
      },
    });
    await fetchOrder();
  }
}
