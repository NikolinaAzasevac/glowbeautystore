import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glowbeautystore_admin/models/admin_user_model.dart';

class AdminUsersService {
  final CollectionReference<Map<String, dynamic>> _usersDb =
      FirebaseFirestore.instance.collection('users');

  Stream<List<AdminUserModel>> usersStream() {
    return _usersDb.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => AdminUserModel.fromFirestore(doc))
            .toList();
      },
    );
  }

  Future<void> updateRole({
    required String userId,
    required String role,
  }) async {
    await _usersDb.doc(userId).update({
      'role': role,
      'isAdmin': role == 'admin',
    });
  }

  Future<void> deleteUserDocument(String userId) async {
    await _usersDb.doc(userId).delete();
  }
}
