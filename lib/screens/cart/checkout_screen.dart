import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/order_model.dart';
import 'package:glow_beauty_store/models/saved_address_model.dart';
import 'package:glow_beauty_store/providers/addresses_provider.dart';
import 'package:glow_beauty_store/providers/cart_provider.dart';
import 'package:glow_beauty_store/providers/order_provider.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/providers/user_provider.dart';
import 'package:glow_beauty_store/screens/inner_screen/orders/orders_screen.dart';
import 'package:glow_beauty_store/screens/profile/saved_addresses_screen.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/common/section_card.dart';
import 'package:glow_beauty_store/widgets/common/soft_info_panel.dart';
import 'package:glow_beauty_store/widgets/common/status_badge.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/CheckoutScreen';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _shippingFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _cardholderController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;

  int _currentStep = 0;
  bool _isSubmitting = false;
  String _deliveryMethod = 'Standard Delivery';
  String _paymentMethod = 'Credit Card';
  String? _selectedAddressId;
  bool _saveAddressForFuture = false;
  bool _saveAsPrimary = false;
  bool _hasAppliedCheckoutDefault = false;
  SavedAddressModel? _checkoutDefaultAddress;
  String? _autofillSourceLabel;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _fullNameController =
        TextEditingController(text: userProvider.getUserModel?.userName ?? '');
    _emailController = TextEditingController(
        text: userProvider.getUserModel?.userEmail ?? user?.email ?? '');
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _zipCodeController = TextEditingController();
    _cardholderController = TextEditingController(
      text: userProvider.getUserModel?.userName ?? '',
    );
    _cardNumberController = TextEditingController(text: '4242 4242 4242 4242');
    _expiryController = TextEditingController(text: '12/30');
    _cvvController = TextEditingController(text: '123');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckoutDefaultAddress();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  double _shippingFee() => _deliveryMethod == 'Express Delivery' ? 590 : 290;

  void _applySavedAddress(SavedAddressModel address) {
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phoneNumber;
    _addressController.text = address.addressLine;
    _cityController.text = address.city;
    _zipCodeController.text = address.zipCode;
  }

  void _clearShippingAutofill() {
    final user = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _selectedAddressId = null;
      _saveAddressForFuture = false;
      _saveAsPrimary = false;
      _hasAppliedCheckoutDefault = true;
      _autofillSourceLabel = null;
    });
    _fullNameController.text = userProvider.getUserModel?.userName ?? '';
    _emailController.text =
        userProvider.getUserModel?.userEmail ?? user?.email ?? '';
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _zipCodeController.clear();
  }

  bool _isSameAddress(
    SavedAddressModel address, {
    required String fullName,
    required String phoneNumber,
    required String addressLine,
    required String city,
    required String zipCode,
  }) {
    return address.fullName.trim().toLowerCase() ==
            fullName.trim().toLowerCase() &&
        address.phoneNumber.trim() == phoneNumber.trim() &&
        address.addressLine.trim().toLowerCase() ==
            addressLine.trim().toLowerCase() &&
        address.city.trim().toLowerCase() == city.trim().toLowerCase() &&
        address.zipCode.trim() == zipCode.trim();
  }

  Future<void> _loadCheckoutDefaultAddress() async {
    final addressesProvider =
        Provider.of<AddressesProvider>(context, listen: false);
    final checkoutDefault =
        await addressesProvider.fetchCheckoutDefaultAddress();
    if (!mounted || checkoutDefault == null) {
      return;
    }
    setState(() {
      _checkoutDefaultAddress = checkoutDefault;
      _selectedAddressId =
          checkoutDefault.addressId.isEmpty ? null : checkoutDefault.addressId;
      _hasAppliedCheckoutDefault = true;
      _autofillSourceLabel = 'Autofilled from last checkout';
    });
    _applySavedAddress(checkoutDefault);
  }

  Widget _buildSavedAddressesSection(
    BuildContext context,
    AddressesProvider addressesProvider,
  ) {
    return StreamBuilder<List<SavedAddressModel>>(
      stream: addressesProvider.addressesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SubtitleTextWidget(
              label: 'Saved addresses unavailable right now.',
              fontSize: 13,
              color: Colors.redAccent,
            ),
          );
        }

        final addresses = snapshot.data ?? <SavedAddressModel>[];
        if (addresses.isEmpty) {
          return SoftInfoPanel(
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            backgroundColor: const Color(0xfffff4f8),
            title: 'No saved addresses yet.',
            message: 'You can continue with manual entry or save one first.',
            footer: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    SavedAddressesScreen.routeName,
                  );
                },
                child: const Text('Manage Addresses'),
              ),
            ),
            margin: const EdgeInsets.only(bottom: 12),
          );
        }

        final normalizedSelectedId = addresses.any(
          (address) => address.addressId == _selectedAddressId,
        )
            ? _selectedAddressId
            : null;
        final primaryAddress = addresses.cast<SavedAddressModel?>().firstWhere(
              (address) => address?.isPrimary == true,
              orElse: () => null,
            );
        final dropdownValue = normalizedSelectedId ?? primaryAddress?.addressId;

        if (!_hasAppliedCheckoutDefault &&
            _selectedAddressId != dropdownValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedAddressId = dropdownValue;
              _hasAppliedCheckoutDefault = true;
              _autofillSourceLabel = 'Autofilled from saved address';
            });
            if (dropdownValue == null) return;
            final selectedAddress = addresses.firstWhere(
              (address) => address.addressId == dropdownValue,
            );
            _applySavedAddress(selectedAddress);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: dropdownValue,
              decoration: const InputDecoration(
                labelText: 'Use Saved Address',
              ),
              items: addresses
                  .map(
                    (address) => DropdownMenuItem<String>(
                      value: address.addressId,
                      child: Text(
                        address.isPrimary
                            ? '${address.fullName} • Primary'
                            : address.fullName,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final selectedAddress = addresses.firstWhere(
                  (address) => address.addressId == value,
                );
                setState(() {
                  _checkoutDefaultAddress = selectedAddress;
                  _selectedAddressId = value;
                  _saveAddressForFuture = false;
                  _saveAsPrimary = false;
                  _autofillSourceLabel = 'Autofilled from saved address';
                });
                _applySavedAddress(selectedAddress);
              },
            ),
            const SizedBox(height: 8),
            if (_autofillSourceLabel != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: _autofillSourceLabel!,
                  icon: Icons.auto_awesome,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_checkoutDefaultAddress != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      _applySavedAddress(_checkoutDefaultAddress!);
                      setState(() {
                        _selectedAddressId =
                            _checkoutDefaultAddress!.addressId.isEmpty
                                ? _selectedAddressId
                                : _checkoutDefaultAddress!.addressId;
                        _hasAppliedCheckoutDefault = true;
                        _autofillSourceLabel = 'Autofilled from last checkout';
                      });
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Use Last Checkout Address'),
                  ),
                OutlinedButton.icon(
                  onPressed: _clearShippingAutofill,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Autofill'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    SavedAddressesScreen.routeName,
                  );
                },
                child: const Text('Manage Addresses'),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _shippingFormKey.currentState?.validate() ?? false;
      case 2:
        return _paymentFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _emailValidator(String? value) {
    return value == null || !value.contains('@') ? 'Invalid email' : null;
  }

  String? _phoneValidator(String? value) {
    return value == null || value.trim().length < 6
        ? 'Invalid phone number'
        : null;
  }

  String? _expiryValidator(String? value) {
    return value == null || value.trim().length < 4 ? 'Invalid expiry' : null;
  }

  String? _cvvValidator(String? value) {
    return value == null || value.trim().length < 3 ? 'Invalid CVV' : null;
  }

  String? _demoCardValidator(String? value) {
    final normalized = value?.replaceAll(' ', '') ?? '';
    if (normalized != '4242424242424242') {
      return 'Use demo card 4242 4242 4242 4242';
    }
    return null;
  }

  Widget _buildStepperControls(ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _isSubmitting ? null : details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _currentStep == 2
                  ? (_isSubmitting ? 'Processing...' : 'Pay Now')
                  : 'Continue',
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _isSubmitting ? null : details.onStepCancel,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Step _buildShippingStep(AddressesProvider addressesProvider) {
    return Step(
      title: const Text('Shipping Information'),
      isActive: _currentStep >= 0,
      content: Form(
        key: _shippingFormKey,
        child: Column(
          children: [
            _buildSavedAddressesSection(context, addressesProvider),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _emailValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(labelText: 'ZIP Code'),
              keyboardType: TextInputType.number,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _saveAddressForFuture,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.darkPrimary,
              title: const Text('Save this address for future checkout'),
              subtitle: const Text(
                'Useful when you entered a new shipping address manually.',
              ),
              onChanged: (value) {
                setState(() {
                  _saveAddressForFuture = value ?? false;
                  if (!_saveAddressForFuture) {
                    _saveAsPrimary = false;
                  }
                });
              },
            ),
            if (_saveAddressForFuture)
              CheckboxListTile(
                value: _saveAsPrimary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.darkPrimary,
                title: const Text('Make it my primary address'),
                onChanged: (value) {
                  setState(() {
                    _saveAsPrimary = value ?? false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Step _buildDeliveryStep() {
    return Step(
      title: const Text('Delivery Method'),
      isActive: _currentStep >= 1,
      content: RadioGroup<String>(
        groupValue: _deliveryMethod,
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _deliveryMethod = value;
          });
        },
        child: const Column(
          children: [
            RadioListTile<String>(
              value: 'Standard Delivery',
              title: Text('Standard Delivery'),
              subtitle: Text('290 RSD · 2-4 business days'),
            ),
            RadioListTile<String>(
              value: 'Express Delivery',
              title: Text('Express Delivery'),
              subtitle: Text('590 RSD · Next business day'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSummaryCard({
    required double subtotal,
    required double shippingFee,
    required double total,
  }) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitelesTextWidget(label: 'Order Summary', fontSize: 18),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Subtotal',
            value: '${subtotal.toStringAsFixed(2)} RSD',
          ),
          _SummaryRow(
            label: 'Shipping',
            value: '${shippingFee.toStringAsFixed(2)} RSD',
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total',
            value: '${total.toStringAsFixed(2)} RSD',
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Step _buildPaymentStep({
    required double subtotal,
    required double shippingFee,
    required double total,
  }) {
    return Step(
      title: const Text('Payment Method'),
      isActive: _currentStep >= 2,
      content: Form(
        key: _paymentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SoftInfoPanel(
              padding: EdgeInsets.all(12),
              borderRadius: 16,
              backgroundColor: Color(0xfffff4f8),
              title: 'Demo Payment Simulation',
              message: 'Use demo card 4242 4242 4242 4242',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: const [
                DropdownMenuItem(
                  value: 'Credit Card',
                  child: Text('Credit Card'),
                ),
                DropdownMenuItem(
                  value: 'Debit Card',
                  child: Text('Debit Card'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Payment Method'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardholderController,
              decoration: const InputDecoration(labelText: 'Cardholder Name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(labelText: 'Card Number'),
              keyboardType: TextInputType.number,
              validator: _demoCardValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(labelText: 'MM/YY'),
                    validator: _expiryValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    validator: _cvvValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildCheckoutSummaryCard(
              subtotal: subtotal,
              shippingFee: shippingFee,
              total: total,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCheckout() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Please login before checkout.',
        fct: () {},
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final addressesProvider =
        Provider.of<AddressesProvider>(context, listen: false);

    final lineItems = cartProvider.getCartitems.values
        .map((cartItem) {
          final product = productsProvider.findByProductId(cartItem.productId);
          if (product == null) {
            return null;
          }
          return OrderLineItem(
            productId: product.productId,
            productTitle: product.productTitle,
            imageUrl: product.primaryImage,
            quantity: cartItem.quantity,
            unitPrice: product.priceValue,
          );
        })
        .whereType<OrderLineItem>()
        .toList();

    if (lineItems.isEmpty) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle:
            'Your cart has no available products. Go back to cart and add a product again.',
        fct: () {},
      );
      return;
    }

    final subtotal = lineItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final shippingFee = _shippingFee();
    final total = subtotal + shippingFee;

    setState(() {
      _isSubmitting = true;
    });
    try {
      await orderProvider.createOrder(
        userId: authUser.uid,
        userName:
            userProvider.getUserModel?.userName ?? authUser.displayName ?? '',
        customerEmail: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        deliveryMethod: _deliveryMethod,
        paymentMethod: _paymentMethod,
        subtotal: subtotal,
        shippingFee: shippingFee,
        totalPrice: total,
        items: lineItems,
      );
      if (_saveAddressForFuture) {
        final existingAddresses =
            await addressesProvider.addressesStream().first;
        final matchedAddress =
            existingAddresses.cast<SavedAddressModel?>().firstWhere(
                  (address) =>
                      address != null &&
                      _isSameAddress(
                        address,
                        fullName: _fullNameController.text,
                        phoneNumber: _phoneController.text,
                        addressLine: _addressController.text,
                        city: _cityController.text,
                        zipCode: _zipCodeController.text,
                      ),
                  orElse: () => null,
                );

        await addressesProvider.saveAddress(
          SavedAddressModel(
            addressId: matchedAddress?.addressId ?? const Uuid().v4(),
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            addressLine: _addressController.text.trim(),
            city: _cityController.text.trim(),
            zipCode: _zipCodeController.text.trim(),
            isPrimary: _saveAsPrimary || existingAddresses.isEmpty,
          ),
        );
      }
      await addressesProvider.saveCheckoutDefaultAddress(
        address: SavedAddressModel(
          addressId: _selectedAddressId ?? '',
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          addressLine: _addressController.text.trim(),
          city: _cityController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          isPrimary: false,
        ),
        selectedAddressId: _selectedAddressId,
      );
      await cartProvider.clearCartFromFirebase();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const TitelesTextWidget(label: 'Payment Successful'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubtitleTextWidget(
                label: 'Demo Payment Simulation',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPrimary,
              ),
              SizedBox(height: 10),
              SubtitleTextWidget(
                label:
                    'Your order has been created, marked as paid and your cart has been cleared.',
                fontSize: 14,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, OrdersScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: e.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesProvider = Provider.of<AddressesProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final subtotal = cartProvider.getTotal(productsProvider: productsProvider);
    final shippingFee = _shippingFee();
    final total = subtotal + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const TitelesTextWidget(label: 'Checkout'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) {
          if (step < 0 || step > 2) {
            return;
          }
          setState(() {
            _currentStep = step;
          });
        },
        onStepContinue: () async {
          if (!_validateCurrentStep()) {
            return;
          }
          if (_currentStep == 2) {
            await _submitCheckout();
            return;
          }
          setState(() {
            _currentStep += 1;
          });
        },
        onStepCancel: () {
          if (_currentStep == 0) {
            Navigator.pop(context);
            return;
          }
          setState(() {
            _currentStep -= 1;
          });
        },
        controlsBuilder: (context, details) => _buildStepperControls(details),
        steps: [
          _buildShippingStep(addressesProvider),
          _buildDeliveryStep(),
          _buildPaymentStep(
            subtotal: subtotal,
            shippingFee: shippingFee,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.darkPrimary,
          )
        : const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
