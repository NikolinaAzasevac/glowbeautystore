import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderLineItem {
  const AdminOrderLineItem({
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

  factory AdminOrderLineItem.fromMap(Map<String, dynamic> data) {
    return AdminOrderLineItem(
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
}

class AdminOrderModel {
  const AdminOrderModel({
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
  final List<AdminOrderLineItem> items;

  int get itemCount =>
      items.fold<int>(0, (runningTotal, item) => runningTotal + item.quantity);

  String get primaryImage => items.isEmpty ? '' : items.first.imageUrl;

  String get orderTitle =>
      items.isEmpty ? 'Glow Beauty Order' : items.first.productTitle;

  factory AdminOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['products'];

    final items = rawItems is List && rawItems.isNotEmpty
        ? rawItems
            .whereType<Map>()
            .map((item) =>
                AdminOrderLineItem.fromMap(Map<String, dynamic>.from(item)))
            .toList()
        : <AdminOrderLineItem>[];

    final shippingInfo = data['shippingInfo'] is Map
        ? Map<String, dynamic>.from(data['shippingInfo'] as Map)
        : const <String, dynamic>{};
    final createdAt = data['createdAt'] ?? data['orderDate'];

    return AdminOrderModel(
      orderId: (data['orderId'] ?? doc.id).toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      customerName:
          (shippingInfo['fullName'] ?? data['userName'] ?? '').toString(),
      customerEmail: (shippingInfo['email'] ?? '').toString(),
      phoneNumber: (shippingInfo['phoneNumber'] ?? '').toString(),
      address: (shippingInfo['address'] ?? '').toString(),
      city: (shippingInfo['city'] ?? '').toString(),
      zipCode: (shippingInfo['zipCode'] ?? '').toString(),
      deliveryMethod:
          (data['deliveryMethod'] ?? 'Standard Delivery').toString(),
      paymentMethod: (data['paymentMethod'] ?? 'Card').toString(),
      orderStatus: (data['orderStatus'] ?? 'Paid').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'Paid').toString(),
      subtotal: data['subtotal'] is num
          ? (data['subtotal'] as num).toDouble()
          : double.tryParse((data['subtotal'] ?? '').toString()) ?? 0,
      shippingFee: data['shippingFee'] is num
          ? (data['shippingFee'] as num).toDouble()
          : double.tryParse((data['shippingFee'] ?? '').toString()) ?? 0,
      totalPrice: data['totalPrice'] is num
          ? (data['totalPrice'] as num).toDouble()
          : double.tryParse((data['totalPrice'] ?? '').toString()) ?? 0,
      createdAt: createdAt is Timestamp ? createdAt : Timestamp.now(),
      items: items,
    );
  }
}
