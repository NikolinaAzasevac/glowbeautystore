import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  const AdminUserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userImage,
    required this.role,
    required this.createdAt,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final String userImage;
  final String role;
  final Timestamp? createdAt;

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUserModel(
      userId: (data['userId'] ?? doc.id).toString(),
      userName: (data['userName'] ?? 'Glow User').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      userImage: (data['userImage'] ?? '').toString(),
      role: (data['role'] ?? (data['isAdmin'] == true ? 'admin' : 'user'))
          .toString(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : null,
    );
  }
}
