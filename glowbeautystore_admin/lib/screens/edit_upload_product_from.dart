import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glowbeautystore_admin/consts/app_colors.dart';
import 'package:glowbeautystore_admin/consts/app_constants.dart';
import 'package:glowbeautystore_admin/consts/validator.dart';
import 'package:glowbeautystore_admin/models/product_model.dart';
import 'package:glowbeautystore_admin/services/cloudinary_service.dart';
import 'package:glowbeautystore_admin/services/my_app_functions.dart';
import 'package:glowbeautystore_admin/widgets/subtitle_text.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';
import 'package:uuid/uuid.dart';

class EditOrUploadProductScreen extends StatefulWidget {
  static const routeName = '/EditOrUploadProductScreen';

  const EditOrUploadProductScreen({super.key, this.productModel});
  final ProductModel? productModel;
  @override
  State<EditOrUploadProductScreen> createState() =>
      _EditOrUploadProductScreenState();
}

class _EditOrUploadProductScreenState extends State<EditOrUploadProductScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  late TextEditingController _titleController,
      _brandController,
      _priceController,
      _descriptionController,
      _quantityController,
      _discountController,
      _tagsController;
  String? _categoryValue;
  bool isEditing = false;
  String? productNetworkImage;
  String productImageUrl = "";
  bool _isFeatured = false;
  bool _isTrending = false;
  bool _isSaving = false;

  @override
  void initState() {
    if (widget.productModel != null) {
      isEditing = true;
      productNetworkImage = widget.productModel!.productImage;
      _categoryValue = widget.productModel!.productCategory;
    }
    _titleController =
        TextEditingController(text: widget.productModel?.productTitle);
    _brandController =
        TextEditingController(text: widget.productModel?.productBrand);
    _priceController =
        TextEditingController(text: widget.productModel?.productPrice);
    _descriptionController =
        TextEditingController(text: widget.productModel?.productDescription);
    _quantityController =
        TextEditingController(text: widget.productModel?.productQuantity);
    _discountController = TextEditingController(
      text: widget.productModel?.discountPercentage.toStringAsFixed(0) ?? '0',
    );
    _tagsController = TextEditingController(
      text: widget.productModel?.tags.join(', ') ?? '',
    );
    _isFeatured = widget.productModel?.isFeatured ?? false;
    _isTrending = widget.productModel?.isTrending ?? false;

    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void clearForm() {
    setState(() {
      _titleController.clear();
      _brandController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _quantityController.clear();
      _discountController.text = '0';
      _tagsController.clear();
      _categoryValue = null;
      _isFeatured = false;
      _isTrending = false;
      _pickedImage = null;
      productNetworkImage = null;
    });
  }

  void removePickedImage() {
    setState(() {
      _pickedImage = null;
      productNetworkImage = null;
    });
  }

  List<String> _normalizedTags() {
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  String? _priceValidator(String? value) {
    final text = value?.trim() ?? '';
    final price = double.tryParse(text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  String? _quantityValidator(String? value) {
    final quantity = int.tryParse(value?.trim() ?? '');
    if (quantity == null || quantity < 0) {
      return 'Enter a valid quantity';
    }
    return null;
  }

  String? _discountValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final discount = double.tryParse(text.replaceAll(',', '.'));
    if (discount == null || discount < 0 || discount > 100) {
      return 'Discount must be between 0 and 100';
    }
    return null;
  }

  Map<String, dynamic> _productPayload({
    required String productId,
    required String imageUrl,
    required Timestamp createdAt,
  }) {
    final quantityValue = int.tryParse(_quantityController.text.trim()) ?? 0;
    final discountValue =
        double.tryParse(_discountController.text.trim().replaceAll(',', '.')) ??
            0;
    final normalizedTags = _normalizedTags();
    final brand = _brandController.text.trim().isEmpty
        ? 'Glow Beauty'
        : _brandController.text.trim();
    final inStock = quantityValue > 0;

    return {
      'productId': productId,
      'productTitle': _titleController.text.trim(),
      'productPrice': _priceController.text.trim(),
      'productImage': imageUrl,
      'productCategory': _categoryValue,
      'productDescription': _descriptionController.text.trim(),
      'productQuantity': _quantityController.text.trim(),
      'productBrand': brand,
      'productRating': widget.productModel?.productRating ?? 4.5,
      'reviewsCount': widget.productModel?.reviewsCount ?? 0,
      'inStock': inStock,
      'galleryImages': <String>[imageUrl],
      'isFeatured': _isFeatured,
      'isTrending': _isTrending,
      'discountPercentage': discountValue,
      'availabilityStatus': inStock ? 'In Stock' : 'Out of Stock',
      'tags': normalizedTags,
      'reviews': widget.productModel?.reviews ?? <Map<String, dynamic>>[],
      'createdAt': createdAt,
    };
  }

  Future<void> _uploadProduct() async {
    if (_isSaving) {
      return;
    }
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (_categoryValue == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Choose a product category.',
        fct: () {},
      );
      return;
    }
    if (_pickedImage == null) {
      MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: "Make sure to pick up an image",
          fct: () {});
      return;
    }
    if (isValid) {
      try {
        setState(() {
          _isSaving = true;
        });

        /*
        Za Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child("productsImages")
            .child("${_titleController.text}.jpg");
        await ref.putFile(File(_pickedImage!.path));
        productImageUrl = await ref.getDownloadURL();*/

        productImageUrl =
            await CloudinaryService.uploadImage(File(_pickedImage!.path));

        final productId = const Uuid().v4();
        await FirebaseFirestore.instance
            .collection("products")
            .doc(productId)
            .set(
              _productPayload(
                productId: productId,
                imageUrl: productImageUrl,
                createdAt: Timestamp.now(),
              ),
            );
        Fluttertoast.showToast(
          msg: "Product has been added",
          textColor: Colors.white,
        );
        if (!mounted) return;
        MyAppFunctions.showErrorOrWarningDialog(
            isError: false,
            context: context,
            subtitle: "Clear Form?",
            fct: () {
              clearForm();
            });
      } on FirebaseException catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.message.toString(),
          fct: () {},
        );
      } catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.toString(),
          fct: () {},
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _editProduct() async {
    if (_isSaving) {
      return;
    }
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (_categoryValue == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Choose a product category.',
        fct: () {},
      );
      return;
    }
    if (_pickedImage == null && productNetworkImage == null) {
      MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: "Make sure to pick up an image",
        fct: () {},
      );
      return;
    }
    if (isValid) {
      try {
        setState(() {
          _isSaving = true;
        });

        if (_pickedImage != null) {
          productImageUrl =
              await CloudinaryService.uploadImage(File(_pickedImage!.path));
        }

        final imageToSave = productImageUrl.isNotEmpty
            ? productImageUrl
            : (productNetworkImage ?? "");

        await FirebaseFirestore.instance
            .collection("products")
            .doc(widget.productModel!.productId)
            .update(
              _productPayload(
                productId: widget.productModel!.productId,
                imageUrl: imageToSave,
                createdAt: widget.productModel!.createdAt ?? Timestamp.now(),
              ),
            );
        Fluttertoast.showToast(
          msg: "Product has been edited",
          textColor: Colors.white,
        );
        if (!mounted) return;
        MyAppFunctions.showErrorOrWarningDialog(
            isError: false,
            context: context,
            subtitle: "Clear Form?",
            fct: () {
              clearForm();
            });
      } on FirebaseException catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.message.toString(),
          fct: () {},
        );
      } catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.toString(),
          fct: () {},
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> localImagePicker() async {
    final ImagePicker picker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.camera);
        setState(() {
          productNetworkImage = null;
        });
      },
      galleryFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.gallery);
        setState(() {
          productNetworkImage = null;
        });
      },
      removeFCT: () {
        setState(() {
          _pickedImage = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        bottomSheet: SizedBox(
          height: kBottomNavigationBarHeight + 10,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text(
                    "Clear",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  onPressed: () {
                    if (_isSaving) {
                      return;
                    }
                    clearForm();
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    // backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.upload),
                  label: Text(
                    _isSaving
                        ? "Saving..."
                        : isEditing
                            ? "Edit Product"
                            : "Upload Product",
                  ),
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (isEditing) {
                            _editProduct();
                          } else {
                            _uploadProduct();
                          }
                        },
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          centerTitle: true,
          title: TitlesTextWidget(
            label: isEditing ? "Edit Product" : "Upload a new product",
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),

                // Image Picker
                if (isEditing && productNetworkImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      productNetworkImage!,
                      // width: size.width * 0.7,
                      height: size.width * 0.5,
                      alignment: Alignment.center,
                    ),
                  ),
                ] else if (_pickedImage == null) ...[
                  SizedBox(
                    width: size.width * 0.4 + 10,
                    height: size.width * 0.4,
                    child: DottedBorder(
                        child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: AppColors.darkPrimary,
                          ),
                          TextButton(
                            onPressed: () {
                              localImagePicker();
                            },
                            child: const Text("Pick Product Image"),
                          ),
                        ],
                      ),
                    )),
                  ),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(
                        _pickedImage!.path,
                      ),
                      // width: size.width * 0.7,
                      height: size.width * 0.5,
                      alignment: Alignment.center,
                    ),
                  ),
                ],
                if (_pickedImage != null || productNetworkImage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          localImagePicker();
                        },
                        child: const Text("Pick another image"),
                      ),
                      TextButton(
                        onPressed: () {
                          removePickedImage();
                        },
                        child: const Text(
                          "Remove image",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                ],
                const SizedBox(
                  height: 25,
                ),

                // Category dropdown widget
                DropdownButton(
                    items: AppConstants.categoriesDropDownList,
                    value: _categoryValue,
                    hint: const Text("Choose a Category"),
                    onChanged: (String? value) {
                      setState(() {
                        _categoryValue = value;
                      });
                    }),
                const SizedBox(
                  height: 25,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          key: const ValueKey('Title'),
                          maxLength: 80,
                          minLines: 1,
                          maxLines: 2,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Product Title',
                          ),
                          validator: (value) {
                            return MyValidators.uploadProdTexts(
                              value: value,
                              toBeReturnedString: "Please enter a valid title",
                            );
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _brandController,
                          key: const ValueKey('Brand'),
                          decoration: const InputDecoration(
                            hintText: 'Brand',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: TextFormField(
                                controller: _priceController,
                                key: const ValueKey('Price RSD'),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^(\d+)?\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                    hintText: 'Price',
                                    prefix: SubtitleTextWidget(
                                      label: "RSD ",
                                      color: AppColors.darkPrimary,
                                      fontSize: 16,
                                    )),
                                validator: (value) {
                                  return _priceValidator(value);
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Flexible(
                              flex: 1,
                              child: TextFormField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                key: const ValueKey('Quantity'),
                                decoration: const InputDecoration(
                                  hintText: 'Qty',
                                ),
                                validator: (value) {
                                  return _quantityValidator(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: _discountController,
                                key: const ValueKey('Discount'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^(\d+)?\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Discount %',
                                ),
                                validator: _discountValidator,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _tagsController,
                                key: const ValueKey('Tags'),
                                decoration: const InputDecoration(
                                  hintText: 'Tags separated by commas',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          value: _isFeatured,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Featured product'),
                          onChanged: (value) {
                            setState(() {
                              _isFeatured = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          value: _isTrending,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Trending product'),
                          onChanged: (value) {
                            setState(() {
                              _isTrending = value;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          key: const ValueKey('Description'),
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: 8,
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Product description',
                          ),
                          validator: (value) {
                            return MyValidators.uploadProdTexts(
                              value: value,
                              toBeReturnedString: "Description is missed",
                            );
                          },
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: kBottomNavigationBarHeight + 10,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
