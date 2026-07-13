import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glow_beauty_store/models/saved_address_model.dart';

class AddressesProvider with ChangeNotifier {
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _userAddresses(String uid) {
    return _userDoc(uid).collection('addresses');
  }

  Stream<List<SavedAddressModel>> addressesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<List<SavedAddressModel>>.empty();
    }
    return _userAddresses(user.uid)
        .orderBy('isPrimary', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavedAddressModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<SavedAddressModel>> fetchAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return <SavedAddressModel>[];
    }
    final snapshot = await _userAddresses(user.uid).get();
    final addresses = snapshot.docs
        .map((doc) => SavedAddressModel.fromMap(doc.data()))
        .toList();
    addresses.sort((a, b) {
      if (a.isPrimary == b.isPrimary) {
        return a.fullName.compareTo(b.fullName);
      }
      return a.isPrimary ? -1 : 1;
    });
    return addresses;
  }

  Future<void> saveAddress(SavedAddressModel address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login before managing addresses.');
    }
    final addressesDb = _userAddresses(user.uid);
    if (address.isPrimary) {
      final currentAddresses = await addressesDb.get();
      for (final doc in currentAddresses.docs) {
        if (doc.id != address.addressId && doc.data()['isPrimary'] == true) {
          await doc.reference.update({'isPrimary': false});
        }
      }
    }
    await addressesDb.doc(address.addressId).set(address.toMap());
  }

  Future<void> deleteAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login before managing addresses.');
    }
    await _userAddresses(user.uid).doc(addressId).delete();
  }

  Future<SavedAddressModel?> fetchCheckoutDefaultAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    final userDoc = await _userDoc(user.uid).get();
    final data = userDoc.data();
    final checkoutDefaults = data?['checkoutDefaults'];
    if (checkoutDefaults is! Map) {
      return null;
    }
    final rawShippingAddress = checkoutDefaults['shippingAddress'];
    if (rawShippingAddress is! Map) {
      return null;
    }

    return SavedAddressModel.fromMap({
      'addressId': (checkoutDefaults['addressId'] ??
              rawShippingAddress['addressId'] ??
              '')
          .toString(),
      'fullName': rawShippingAddress['fullName'],
      'phoneNumber': rawShippingAddress['phoneNumber'],
      'addressLine': rawShippingAddress['addressLine'],
      'city': rawShippingAddress['city'],
      'zipCode': rawShippingAddress['zipCode'],
      'isPrimary': false,
    });
  }

  Future<void> saveCheckoutDefaultAddress({
    required SavedAddressModel address,
    String? selectedAddressId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login before managing addresses.');
    }
    await _userDoc(user.uid).set({
      'checkoutDefaults': {
        'addressId': selectedAddressId ?? address.addressId,
        'shippingAddress': {
          'fullName': address.fullName,
          'phoneNumber': address.phoneNumber,
          'addressLine': address.addressLine,
          'city': address.city,
          'zipCode': address.zipCode,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
