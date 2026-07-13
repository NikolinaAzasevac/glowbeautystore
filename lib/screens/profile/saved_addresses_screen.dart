import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/saved_address_model.dart';
import 'package:glow_beauty_store/providers/addresses_provider.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class SavedAddressesScreen extends StatefulWidget {
  static const routeName = '/SavedAddressesScreen';
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  late final AddressesProvider _addressesProvider;
  late Future<List<SavedAddressModel>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesProvider = Provider.of<AddressesProvider>(context, listen: false);
    _addressesFuture = _addressesProvider.fetchAddresses();
  }

  Future<void> _refreshAddresses() async {
    setState(() {
      _addressesFuture = _addressesProvider.fetchAddresses();
    });
    await _addressesFuture;
  }

  Future<void> _openAddressSheet({
    SavedAddressModel? existingAddress,
  }) async {
    final fullNameController =
        TextEditingController(text: existingAddress?.fullName ?? '');
    final phoneController =
        TextEditingController(text: existingAddress?.phoneNumber ?? '');
    final addressController =
        TextEditingController(text: existingAddress?.addressLine ?? '');
    final cityController =
        TextEditingController(text: existingAddress?.city ?? '');
    final zipController =
        TextEditingController(text: existingAddress?.zipCode ?? '');
    final formKey = GlobalKey<FormState>();
    bool isPrimary = existingAddress?.isPrimary ?? false;
    final savedAddress = await showModalBottomSheet<SavedAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitelesTextWidget(
                        label: existingAddress == null
                            ? 'Add New Address'
                            : 'Edit Address',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fullNameController,
                        decoration:
                            const InputDecoration(labelText: 'Full Name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        validator: (value) =>
                            value == null || value.trim().length < 6
                                ? 'Invalid phone number'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration:
                            const InputDecoration(labelText: 'Address Line'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: zipController,
                        decoration:
                            const InputDecoration(labelText: 'ZIP Code'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: isPrimary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set as primary address'),
                        onChanged: (value) {
                          setModalState(() {
                            isPrimary = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.pop(
                              bottomSheetContext,
                              SavedAddressModel(
                                addressId: existingAddress?.addressId ??
                                    const Uuid().v4(),
                                fullName: fullNameController.text.trim(),
                                phoneNumber: phoneController.text.trim(),
                                addressLine: addressController.text.trim(),
                                city: cityController.text.trim(),
                                zipCode: zipController.text.trim(),
                                isPrimary: isPrimary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Address'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (savedAddress == null || !mounted) {
      return;
    }

    try {
      await _addressesProvider.saveAddress(savedAddress);
      if (!mounted) return;
      await _refreshAddresses();
    } catch (e) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: e.toString(),
        fct: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TitelesTextWidget(label: 'Saved Addresses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final canContinue = await MyAppFunctions.requireSignedIn(
            context: context,
            subtitle: 'Please sign in before managing addresses.',
          );
          if (!canContinue || !mounted) {
            return;
          }
          await _openAddressSheet();
        },
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Address'),
      ),
      body: FutureBuilder<List<SavedAddressModel>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SelectableText(snapshot.error.toString()));
          }
          final addresses = snapshot.data ?? <SavedAddressModel>[];
          if (addresses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: SubtitleTextWidget(
                  label:
                      'No saved addresses yet. Add one to speed up future checkout.',
                  fontSize: 16,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.darkPrimary,
            onRefresh: _refreshAddresses,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TitelesTextWidget(
                              label: address.fullName,
                              fontSize: 18,
                            ),
                          ),
                          if (address.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xfffff1f7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const SubtitleTextWidget(
                                label: 'Primary',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkPrimary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SubtitleTextWidget(
                        label: address.phoneNumber,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 6),
                      SubtitleTextWidget(
                        label:
                            '${address.addressLine}, ${address.city}, ${address.zipCode}',
                        fontSize: 14,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _openAddressSheet(existingAddress: address),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await providerDeleteAddress(
                                address.addressId,
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> providerDeleteAddress(
    String addressId,
  ) async {
    final canContinue = await MyAppFunctions.requireSignedIn(
      context: context,
      subtitle: 'Please sign in before managing addresses.',
    );
    if (!canContinue || !mounted) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const TitelesTextWidget(label: 'Delete address?'),
              content: const SubtitleTextWidget(
                label: 'This saved address will be removed from your account.',
                fontSize: 14,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    try {
      await _addressesProvider.deleteAddress(addressId);
      if (!mounted) return;
      await _refreshAddresses();
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }
}
