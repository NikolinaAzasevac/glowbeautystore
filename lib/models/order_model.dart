import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.productTitle,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productTitle;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  factory OrderLineItem.fromMap(Map<String, dynamic> data) {
    return OrderLineItem(
      productId: (data['productId'] ?? '').toString(),
      productTitle: (data['productTitle'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      quantity: data['quantity'] is num
          ? (data['quantity'] as num).toInt()
          : int.tryParse((data['quantity'] ?? '').toString()) ?? 0,
      unitPrice: data['unitPrice'] is num
          ? (data['unitPrice'] as num).toDouble()
          : double.tryParse((data['unitPrice'] ?? '').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }
}

class OrdersModel with ChangeNotifier {
  final String orderId;
  final String userId;
  final String userName;
  final String customerName;
  final String customerEmail;
  final String phoneNumber;
  final String address;
  final String city;
  final String zipCode;
  final String deliveryMethod;
  final String paymentMethod;
  final String orderStatus;
  final String paymentStatus;
  final double subtotal;
  final double shippingFee;
  final double totalPrice;
  final Timestamp createdAt;
  final List<OrderLineItem> items;

  OrdersModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.customerName,
    required this.customerEmail,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.zipCode,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.orderStatus,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingFee,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
  });

  int get itemCount =>
      items.fold<int>(0, (runningTotal, item) => runningTotal + item.quantity);

  String get primaryImage => items.isEmpty ? '' : items.first.imageUrl;

  String get orderTitle =>
      items.isEmpty ? 'Glow Beauty Order' : items.first.productTitle;

  factory OrdersModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['products'];

    final items = rawItems is List && rawItems.isNotEmpty
        ? rawItems
            .whereType<Map>()
            .map((item) =>
                OrderLineItem.fromMap(Map<String, dynamic>.from(item)))
            .toList()
        : <OrderLineItem>[
            OrderLineItem(
              productId: (data['productId'] ?? '').toString(),
              productTitle: (data['productTitle'] ?? '').toString(),
              imageUrl: (data['imageUrl'] ?? '').toString(),
              quantity: data['quantity'] is num
                  ? (data['quantity'] as num).toInt()
                  : int.tryParse((data['quantity'] ?? '').toString()) ?? 0,
              unitPrice: data['price'] is num
                  ? (data['price'] as num).toDouble()
                  : double.tryParse((data['price'] ?? '').toString()) ?? 0,
            ),
          ];

    final createdAt = data['createdAt'] ?? data['orderDate'];

    return OrdersModel(
      orderId: (data['orderId'] ?? doc.id).toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      customerName: ((data['shippingInfo'] as Map?)?['fullName'] ??
              data['userName'] ??
              '')
          .toString(),
      customerEmail:
          ((data['shippingInfo'] as Map?)?['email'] ?? '').toString(),
      phoneNumber:
          ((data['shippingInfo'] as Map?)?['phoneNumber'] ?? '').toString(),
      address: ((data['shippingInfo'] as Map?)?['address'] ?? '').toString(),
      city: ((data['shippingInfo'] as Map?)?['city'] ?? '').toString(),
      zipCode: ((data['shippingInfo'] as Map?)?['zipCode'] ?? '').toString(),
      deliveryMethod:
          (data['deliveryMethod'] ?? 'Standard Delivery').toString(),
      paymentMethod: (data['paymentMethod'] ?? 'Card').toString(),
      orderStatus: (data['orderStatus'] ?? 'Paid').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'Paid').toString(),
      subtotal: data['subtotal'] is num
          ? (data['subtotal'] as num).toDouble()
          : double.tryParse(
                  (data['totalPrice'] ?? data['price'] ?? '').toString()) ??
              0,
      shippingFee: data['shippingFee'] is num
          ? (data['shippingFee'] as num).toDouble()
          : 0,
      totalPrice: data['totalPrice'] is num
          ? (data['totalPrice'] as num).toDouble()
          : double.tryParse(
                  (data['totalPrice'] ?? data['price'] ?? '').toString()) ??
              0,
      createdAt: createdAt is Timestamp ? createdAt : Timestamp.now(),
      items: items,
    );
  }
}
