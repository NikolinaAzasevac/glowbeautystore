import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductModel with ChangeNotifier {
  final String productId,
      productTitle,
      productPrice,
      productCategory,
      productDescription,
      productImage,
      productQuantity,
      productBrand,
      availabilityStatus;
  final double productRating, discountPercentage;
  final int reviewsCount;
  final bool inStock, isFeatured, isTrending;
  final List<String> galleryImages, tags;
  final List<Map<String, dynamic>> reviews;
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

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawGallery = data['galleryImages'];
    final galleryImages = rawGallery is List
        ? rawGallery.map((image) => image.toString()).toList()
        : <String>[(data['productImage'] ?? '').toString()];
    final reviews = data['reviews'] is List
        ? (data['reviews'] as List)
            .whereType<Map>()
            .map((review) => Map<String, dynamic>.from(review))
            .toList()
        : <Map<String, dynamic>>[];
    return ProductModel(
      productId: (data["productId"] ?? doc.id).toString(),
      productTitle: (data['productTitle'] ?? '').toString(),
      productPrice: (data['productPrice'] ?? '').toString(),
      productCategory: (data['productCategory'] ?? '').toString(),
      productDescription: (data['productDescription'] ?? '').toString(),
      productImage: (data['productImage'] ?? '').toString(),
      productQuantity: (data['productQuantity'] ?? '').toString(),
      productBrand: (data['productBrand'] ?? 'Glow Beauty').toString(),
      productRating: data['productRating'] is num
          ? (data['productRating'] as num).toDouble()
          : 4.5,
      reviewsCount: data['reviewsCount'] is num
          ? (data['reviewsCount'] as num).toInt()
          : 0,
      inStock: data['inStock'] is bool
          ? data['inStock'] as bool
          : ((int.tryParse((data['productQuantity'] ?? '0').toString()) ?? 0) >
              0),
      galleryImages: galleryImages,
      isFeatured: data['isFeatured'] == true,
      isTrending: data['isTrending'] == true,
      discountPercentage: data['discountPercentage'] is num
          ? (data['discountPercentage'] as num).toDouble()
          : 0,
      availabilityStatus: (data['availabilityStatus'] ?? 'In Stock').toString(),
      tags: data['tags'] is List
          ? (data['tags'] as List).map((tag) => tag.toString()).toList()
          : <String>[],
      reviews: reviews,
      createdAt: data['createdAt'],
    );
  }
}
