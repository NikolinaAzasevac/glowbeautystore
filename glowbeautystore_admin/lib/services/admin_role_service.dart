import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRoleService {
  static Future<bool> isAdminUser(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return false;
    }

    final data = userDoc.data() ?? <String, dynamic>{};
    final role = (data['role'] ?? '').toString().trim().toLowerCase();
    final isAdminFlag = data['isAdmin'] == true;
    return role == 'admin' || isAdminFlag;
  }
}
