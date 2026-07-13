import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  static const routeName = '/admin-panel';

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserProvider>().getUserModel;
    final isAdmin = userModel?.role.toLowerCase() == 'admin';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(IconlyLight.user3), text: 'Users'),
              Tab(icon: Icon(IconlyLight.bag), text: 'Products'),
              Tab(icon: Icon(IconlyLight.buy), text: 'Orders'),
              Tab(icon: Icon(IconlyLight.star), text: 'Reviews'),
            ],
          ),
        ),
        body: isAdmin
            ? const TabBarView(
                children: [
                  _UsersTab(),
                  _ProductsTab(),
                  _OrdersTab(),
                  _ReviewsTab(),
                ],
              )
            : const _AdminLockedView(),
      ),
    );
  }
}

class _AdminLockedView extends StatelessWidget {
  const _AdminLockedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Admin access required. Refresh profile after changing the role.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorView(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _LoadingView();
        }

        final docs = [...snapshot.data!.docs]..sort((a, b) =>
            _text(a.data()['userEmail'])
                .compareTo(_text(b.data()['userEmail'])));

        if (docs.isEmpty) {
          return const _EmptyView(message: 'No users yet.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final role = _text(data['role'], fallback: 'user');
            final isCurrentUser =
                doc.id == FirebaseAuth.instance.currentUser?.uid;

            return _AdminCard(
              title: _text(data['userName'], fallback: 'Unnamed user'),
              subtitle: _text(data['userEmail']),
              badge: role,
              icon: IconlyLight.profile,
              trailing: Wrap(
                spacing: 6,
                children: [
                  TextButton(
                    onPressed: () async {
                      final nextRole = role == 'admin' ? 'user' : 'admin';
                      await _runAdminAction(
                        context,
                        () => doc.reference.update({'role': nextRole}),
                        success: 'Role changed to $nextRole.',
                      );
                    },
                    child: Text(role == 'admin' ? 'Make user' : 'Make admin'),
                  ),
                  IconButton(
                    tooltip: 'Delete user document',
                    onPressed: isCurrentUser
                        ? null
                        : () async {
                            final confirmed = await _confirm(
                              context,
                              'Delete user document?',
                              'This removes the Firestore profile document, not the Firebase Auth account.',
                            );
                            if (!confirmed || !context.mounted) return;
                            await _runAdminAction(
                              context,
                              doc.reference.delete,
                              success: 'User document deleted.',
                            );
                          },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  void _refreshProducts() {
    context.read<ProductsProvider>().fetchProducts(forceRefresh: true);
  }

  static const _categoryOptions = <String, String>{
    'makeup': 'Makeup',
    'care': 'Care',
    'fragrance': 'Fragrance',
    'accessories': 'Accessories',
  };

  static const _categoryLabels = <String, String>{
    ..._categoryOptions,
    'beauty': 'Makeup',
    'skin-care': 'Care',
    'face-care': 'Care',
    'fragrances': 'Fragrance',
    'womens-jewellery': 'Accessories',
    'sunglasses': 'Accessories',
    'womens-bags': 'Accessories',
  };

  String _normalizeCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'beauty') return 'makeup';
    if (normalized == 'skin-care' || normalized == 'face-care') return 'care';
    if (normalized == 'fragrances') return 'fragrance';
    if (normalized == 'womens-jewellery' ||
        normalized == 'sunglasses' ||
        normalized == 'womens-bags') {
      return 'accessories';
    }
    return _categoryOptions.containsKey(normalized) ? normalized : 'makeup';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openProductSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const _LoadingView();
          }

          final docs = [...snapshot.data!.docs]..sort((a, b) {
              final aTime = _timestampMillis(a.data()['createdAt']);
              final bTime = _timestampMillis(b.data()['createdAt']);
              return bTime.compareTo(aTime);
            });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final category = _text(data['productCategory']);

              return _AdminCard(
                title: _text(data['productTitle'], fallback: 'Product'),
                subtitle:
                    '${_text(data['productBrand'], fallback: 'Glow Beauty')} • ${_text(data['productPrice'], fallback: '0')} RSD',
                badge: _categoryLabels[category] ?? category,
                icon: IconlyLight.bag,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit product',
                      onPressed: () => _openProductSheet(context, doc: doc),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete product',
                      onPressed: () async {
                        final confirmed = await _confirm(
                          context,
                          'Delete product?',
                          'This product will be removed from the Firestore catalog.',
                        );
                        if (!confirmed || !context.mounted) return;
                        await _runAdminAction(
                          context,
                          doc.reference.delete,
                          success: 'Product deleted.',
                        );
                        if (!context.mounted) return;
                        _refreshProducts();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openProductSheet(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final titleController =
        TextEditingController(text: _text(data['productTitle']));
    final brandController =
        TextEditingController(text: _text(data['productBrand']));
    final priceController =
        TextEditingController(text: _text(data['productPrice']));
    final quantityController = TextEditingController(
        text: _text(data['productQuantity'], fallback: '5'));
    final imageController =
        TextEditingController(text: _text(data['productImage']));
    final descriptionController = TextEditingController(
      text: _text(
        data['productDescription'],
        fallback: 'Glow Beauty Store curated item.',
      ),
    );
    final formKey = GlobalKey<FormState>();
    String category = _normalizeCategory(_text(data['productCategory']));
    bool inStock = data['inStock'] != false;
    bool isSaving = false;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      doc == null ? 'Add product' : 'Edit product',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _AdminTextField(
                      controller: titleController,
                      label: 'Product title',
                    ),
                    _AdminTextField(
                      controller: brandController,
                      label: 'Brand',
                    ),
                    _AdminTextField(
                      controller: priceController,
                      label: 'Price RSD',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: quantityController,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categoryOptions.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    _AdminTextField(
                      controller: imageController,
                      label: 'Image URL',
                    ),
                    _AdminTextField(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('In stock'),
                      value: inStock,
                      onChanged: (value) {
                        setSheetState(() => inStock = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSaving = true);
                              final productsRef = FirebaseFirestore.instance
                                  .collection('products');
                              final ref = doc?.reference ?? productsRef.doc();
                              final productData = {
                                'productTitle': titleController.text.trim(),
                                'productBrand': brandController.text.trim(),
                                'productPrice': priceController.text.trim(),
                                'productQuantity':
                                    quantityController.text.trim(),
                                'productCategory': category,
                                'productImage': imageController.text.trim(),
                                'galleryImages': [imageController.text.trim()],
                                'productDescription':
                                    descriptionController.text.trim(),
                                'productRating': data['productRating'] ?? 4.8,
                                'reviewsCount': data['reviewsCount'] ?? 0,
                                'inStock': inStock,
                                'availabilityStatus':
                                    inStock ? 'In Stock' : 'Out of Stock',
                                'isFeatured': data['isFeatured'] ?? false,
                                'isTrending': data['isTrending'] ?? false,
                                'discountPercentage':
                                    data['discountPercentage'] ?? 0,
                                'tags': [category],
                                'productId': ref.id,
                                'createdAt':
                                    data['createdAt'] ?? Timestamp.now(),
                                'updatedAt': Timestamp.now(),
                              };
                              try {
                                await ref.set(
                                  productData,
                                  SetOptions(merge: true),
                                );
                                if (!mounted) return;
                                _refreshProducts();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Product saved.'),
                                  ),
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (error) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => isSaving = false);
                                }
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(isSaving ? 'Saving...' : 'Save product'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  static const _statuses = [
    'Paid',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorView(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _LoadingView();
        }

        final docs = [...snapshot.data!.docs]..sort((a, b) {
            final aTime = _timestampMillis(a.data()['createdAt']);
            final bTime = _timestampMillis(b.data()['createdAt']);
            return bTime.compareTo(aTime);
          });

        if (docs.isEmpty) {
          return const _EmptyView(message: 'No orders yet.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final orderStatus = _text(data['orderStatus'], fallback: 'Paid');

            return _AdminCard(
              title: _orderTitle(data),
              subtitle:
                  '${_text(data['userName'], fallback: 'Customer')} • ${_money(data['totalPrice'])}',
              badge: orderStatus,
              icon: IconlyLight.buy,
              trailing: DropdownButton<String>(
                value: _statuses.contains(orderStatus) ? orderStatus : 'Paid',
                underline: const SizedBox.shrink(),
                items: _statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  await _runAdminAction(
                    context,
                    () => doc.reference.update({'orderStatus': value}),
                    success: 'Order status updated.',
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _orderTitle(Map<String, dynamic> data) {
    final products = data['products'];
    if (products is List && products.isNotEmpty && products.first is Map) {
      final first = Map<String, dynamic>.from(products.first as Map);
      return _text(first['productTitle'], fallback: 'Glow Beauty Order');
    }
    return 'Glow Beauty Order';
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorView(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _LoadingView();
        }

        final docs = [...snapshot.data!.docs]..sort((a, b) {
            final aTime = _timestampMillis(a.data()['createdAt']);
            final bTime = _timestampMillis(b.data()['createdAt']);
            return bTime.compareTo(aTime);
          });

        if (docs.isEmpty) {
          return const _EmptyView(message: 'No reviews yet.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _AdminCard(
              title: _text(data['userName'], fallback: 'Reviewer'),
              subtitle: _text(data['comment'], fallback: 'No comment'),
              badge: '${_text(data['rating'], fallback: '5')} stars',
              icon: IconlyLight.star,
              trailing: IconButton(
                tooltip: 'Delete review',
                onPressed: () async {
                  final confirmed = await _confirm(
                    context,
                    'Delete review?',
                    'This review will be removed from the app.',
                  );
                  if (!confirmed || !context.mounted) return;
                  await _runAdminAction(
                    context,
                    doc.reference.delete,
                    success: 'Review deleted.',
                  );
                },
                icon: const Icon(Icons.delete_outline),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.darkPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SelectableText(message, textAlign: TextAlign.center),
      ),
    );
  }
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _money(dynamic value) {
  final price = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return '${price.toStringAsFixed(0)} RSD';
}

int _timestampMillis(dynamic value) {
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }
  return 0;
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String subtitle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

Future<void> _runAdminAction(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success)),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}
