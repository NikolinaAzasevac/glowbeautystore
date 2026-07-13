import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glowbeautystore_admin/models/admin_user_model.dart';
import 'package:glowbeautystore_admin/services/admin_users_service.dart';
import 'package:glowbeautystore_admin/services/assets_manager.dart';
import 'package:glowbeautystore_admin/services/my_app_functions.dart';
import 'package:glowbeautystore_admin/widgets/empty_bag.dart';
import 'package:glowbeautystore_admin/widgets/subtitle_text.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';

class UsersManagementScreen extends StatefulWidget {
  static const routeName = '/UsersManagementScreen';

  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final AdminUsersService _usersService = AdminUsersService();

  Future<void> _updateRole(AdminUserModel user, String role) async {
    if (user.role.toLowerCase() == role) {
      return;
    }
    try {
      await _usersService.updateRole(userId: user.userId, role: role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.userName} is now $role')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Unable to update role.',
        fct: () {},
      );
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  Future<void> _deleteUser(AdminUserModel user) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == user.userId) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'You cannot delete your own admin document while signed in.',
        fct: () {},
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const TitlesTextWidget(label: 'Delete user?'),
              content: SubtitleTextWidget(
                label:
                    'This removes the Firestore user document for ${user.userName}. Continue?',
                fontSize: 14,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }

    try {
      await _usersService.deleteUserDocument(user.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User document deleted')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Unable to delete user.',
        fct: () {},
      );
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }
    final value = timestamp.toDate();
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TitlesTextWidget(label: 'Users management'),
      ),
      body: StreamBuilder<List<AdminUserModel>>(
        stream: _usersService.usersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(snapshot.error.toString()),
              ),
            );
          }

          final users = snapshot.data ?? <AdminUserModel>[];
          if (users.isEmpty) {
            return EmptyBagWidget(
              imagePath: AssetsManager.warning,
              title: 'No users found',
              subtitle: 'Registered users will appear here.',
            );
          }

          final adminCount =
              users.where((user) => user.role.toLowerCase() == 'admin').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TitlesTextWidget(
                        label: 'Users overview',
                        fontSize: 20,
                      ),
                      const SizedBox(height: 8),
                      SubtitleTextWidget(
                        label:
                            '${users.length} users • $adminCount admins • ${users.length - adminCount} standard users',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...users.map(
                (user) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: user.userImage.isNotEmpty
                                  ? NetworkImage(user.userImage)
                                  : null,
                              child: user.userImage.isEmpty
                                  ? const Icon(Icons.person_outline)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TitlesTextWidget(
                                    label: user.userName,
                                    fontSize: 17,
                                  ),
                                  const SizedBox(height: 4),
                                  SubtitleTextWidget(
                                    label: user.userEmail.isEmpty
                                        ? 'No email available'
                                        : user.userEmail,
                                    fontSize: 14,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _RoleChip(role: user.role),
                                      _MetaChip(
                                        icon: Icons.event_outlined,
                                        label:
                                            'Joined ${_formatDate(user.createdAt)}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == '__delete__') {
                                  _deleteUser(user);
                                  return;
                                }
                                _updateRole(user, value);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'user',
                                  child: Text('Set role: user'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'admin',
                                  child: Text('Set role: admin'),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem<String>(
                                  value: '__delete__',
                                  child: Text('Delete user document'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'User ID', value: user.userId),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    final color = isAdmin ? Colors.green : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SubtitleTextWidget(
        label: role.toUpperCase(),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: SubtitleTextWidget(
            label: '$label:',
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
    );
  }
}
