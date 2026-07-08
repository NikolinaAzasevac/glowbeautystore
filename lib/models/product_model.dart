import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glow_beauty_store/models/product_review_model.dart';

class ProductModel with ChangeNotifier {
  final String productId;
  final String productTitle;
  final String productPrice;
  final String productCategory;
  final String productDescription;
  final String productImage;
  final String productQuantity;
  final String productBrand;
  final double productRating;
  final int reviewsCount;
  final bool inStock;
  final List<String> galleryImages;
  final bool isFeatured;
  final bool isTrending;
  final double discountPercentage;
  final String availabilityStatus;
  final List<String> tags;
  final List<ProductReviewModel> reviews;
  Timestamp? createdAt;

  ProductModel({
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productCategory,
    required this.productDescription,
    required this.productImage,
    required this.productQuantity,
    required this.productBrand,
    required this.productRating,
    required this.reviewsCount,
    required this.inStock,
    required this.galleryImages,
    required this.isFeatured,
    required this.isTrending,
    required this.discountPercentage,
    required this.availabilityStatus,
    required this.tags,
    required this.reviews,
    this.createdAt,
  });

  double get priceValue => double.tryParse(productPrice) ?? 0;

  int get quantityValue => int.tryParse(productQuantity) ?? 0;

  String get primaryImage =>
      productImage.isNotEmpty ? productImage : galleryImages.firstOrNull ?? '';

  static List<ProductReviewModel> _mapReviews(dynamic rawReviews) {
    if (rawReviews is! List) {
      return const <ProductReviewModel>[];
    }
    return rawReviews
        .whereType<Map>()
        .map((review) =>
            ProductReviewModel.fromMap(Map<String, dynamic>.from(review)))
        .toList();
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dynamic rawGallery = data['galleryImages'];
    final List<String> gallery = rawGallery is List
        ? rawGallery.map((image) => image.toString()).toList()
        : <String>[];
    final dynamic rawRating = data['productRating'] ?? data['rating'];
    final dynamic rawReviewsCount = data['reviewsCount'];
    final String image = (data['productImage'] ?? '').toString();
    final reviews = _mapReviews(data['reviews']);
    return ProductModel(
      productId: (data['productId'] ?? doc.id).toString(),
      productTitle: (data['productTitle'] ?? 'Beauty Product').toString(),
      productPrice: (data['productPrice'] ?? '0').toString(),
      productCategory: (data['productCategory'] ?? 'Beauty').toString(),
      productDescription:
          (data['productDescription'] ?? 'Glow Beauty Store curated item.')
              .toString(),
      productImage: image,
      productQuantity: (data['productQuantity'] ?? '0').toString(),
      productBrand:
          (data['productBrand'] ?? data['brand'] ?? 'Glow Beauty').toString(),
      productRating: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse(rawRating?.toString() ?? '') ?? 4.5,
      reviewsCount: rawReviewsCount is num
          ? rawReviewsCount.toInt()
          : int.tryParse(rawReviewsCount?.toString() ?? '') ?? 0,
      inStock: data['inStock'] is bool
          ? data['inStock'] as bool
          : ((int.tryParse((data['productQuantity'] ?? '0').toString()) ?? 0) >
              0),
      galleryImages: gallery.isEmpty ? <String>[image] : gallery,
      isFeatured: data['isFeatured'] == true,
      isTrending: data['isTrending'] == true,
      discountPercentage: data['discountPercentage'] is num
          ? (data['discountPercentage'] as num).toDouble()
          : 0,
      availabilityStatus: (data['availabilityStatus'] ??
              (((int.tryParse((data['productQuantity'] ?? '0').toString()) ??
                          0) >
                      0)
                  ? 'In Stock'
                  : 'Out of Stock'))
          .toString(),
      tags: data['tags'] is List
          ? (data['tags'] as List).map((tag) => tag.toString()).toList()
          : <String>[],
      reviews: reviews,
      createdAt: data['createdAt'],
    );
  }

  factory ProductModel.fromApiMap(Map<String, dynamic> data) {
    final rawPrice = data['price'];
    final priceUsd = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final priceRsd = (priceUsd * 110).round();
    final images = data['images'] is List
        ? (data['images'] as List).map((image) => image.toString()).toList()
        : <String>[];
    final createdAt = DateTime.tryParse(
      ((data['meta'] as Map?)?['createdAt'] ?? '').toString(),
    );
    return ProductModel(
      productId: (data['id'] ?? '').toString(),
      productTitle: (data['title'] ?? 'Beauty Product').toString(),
      productPrice: priceRsd.toString(),
      productCategory: (data['category'] ?? 'beauty').toString(),
      productDescription:
          (data['description'] ?? 'Glow Beauty Store curated item.').toString(),
      productImage:
          (data['thumbnail'] ?? data['images']?.first ?? '').toString(),
      productQuantity: (data['stock'] ?? 0).toString(),
      productBrand: (data['brand'] ?? 'Glow Beauty').toString(),
      productRating:
          data['rating'] is num ? (data['rating'] as num).toDouble() : 4.5,
      reviewsCount: 0,
      inStock: (data['stock'] is num ? (data['stock'] as num) > 0 : true),
      galleryImages: images.isEmpty
          ? <String>[(data['thumbnail'] ?? '').toString()]
          : images,
      isFeatured: ((data['rating'] as num?) ?? 0) >= 4.7,
      isTrending: ((data['reviews'] as List?)?.length ?? 0) >= 3,
      discountPercentage: data['discountPercentage'] is num
          ? (data['discountPercentage'] as num).toDouble()
          : 0,
      availabilityStatus: (data['availabilityStatus'] ??
              ((data['stock'] is num && (data['stock'] as num) <= 0)
                  ? 'Out of Stock'
                  : 'In Stock'))
          .toString(),
      tags: data['tags'] is List
          ? (data['tags'] as List).map((tag) => tag.toString()).toList()
          : <String>[],
      reviews: const <ProductReviewModel>[],
      createdAt:
          createdAt == null ? null : Timestamp.fromDate(createdAt.toLocal()),
    );
  }
}
