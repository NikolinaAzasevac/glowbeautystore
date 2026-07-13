import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glow_beauty_store/models/product_model.dart';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> products = [];
  bool isLoading = false;
  String? errorMessage;
  bool usingRemoteCatalog = false;

  List<ProductModel> get getProducts {
    return products;
  }

  List<ProductModel> get featuredProducts {
    final featured = products.where((product) => product.isFeatured).toList();
    if (featured.isNotEmpty) {
      return featured;
    }
    return _categoryBalanced(products, limit: 6);
  }

  List<ProductModel> get trendingProducts {
    final trending = products.where((product) => product.isTrending).toList();
    if (trending.isNotEmpty) {
      return trending;
    }
    return _categoryBalanced(products, limit: 8);
  }

  List<ProductModel> get bestSellerProducts {
    final reviewedProducts = products
        .where(
            (product) => product.reviewsCount > 0 || product.productRating > 0)
        .toList()
      ..sort((a, b) {
        final reviewCompare = b.reviewsCount.compareTo(a.reviewsCount);
        if (reviewCompare != 0) {
          return reviewCompare;
        }
        return b.productRating.compareTo(a.productRating);
      });
    return reviewedProducts.take(8).toList();
  }

  List<ProductModel> get newArrivalProducts {
    final sorted = [...products]..sort((a, b) {
        final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bMillis.compareTo(aMillis);
      });
    return sorted.take(8).toList();
  }

  List<ProductModel> get recommendedProducts {
    return _categoryBalanced(products, limit: 8);
  }

  List<ProductModel> _categoryBalanced(
    List<ProductModel> source, {
    required int limit,
  }) {
    final byCategory = <String, List<ProductModel>>{};
    for (final product in source) {
      byCategory.putIfAbsent(product.productCategory, () => []).add(product);
    }

    final balanced = <ProductModel>[];
    var hasMoreProducts = true;
    var round = 0;
    while (balanced.length < limit && hasMoreProducts) {
      hasMoreProducts = false;
      for (final categoryProducts in byCategory.values) {
        if (round < categoryProducts.length) {
          balanced.add(categoryProducts[round]);
          hasMoreProducts = true;
        }
        if (balanced.length == limit) {
          break;
        }
      }
      round++;
    }
    return balanced;
  }

  List<String> get popularSearches {
    final tags = <String>{
      for (final product in products) product.productCategory,
      for (final product in products) product.productBrand,
      'skincare',
      'serum',
      'perfume',
      'jewelry',
      'sunglasses',
      'glow',
    };
    return tags.where((tag) => tag.trim().isNotEmpty).take(8).toList();
  }

  ProductModel? findByProductId(String productId) {
    if (products.where((element) => element.productId == productId).isEmpty) {
      return null;
    }
    return products.firstWhere((element) => element.productId == productId);
  }

  List<ProductModel> findByCategory({required String categoryName}) {
    final normalized = categoryName.trim().toLowerCase();
    final allowedCategories = switch (normalized) {
      'beauty' || 'makeup' => const ['makeup', 'beauty'],
      'face-care' || 'care' || 'skincare' => const [
          'care',
          'face-care',
          'skin-care',
        ],
      'fragrance' || 'perfume' => const ['fragrance', 'fragrances'],
      'accessories' => const [
          'accessories',
          'womens-jewellery',
          'sunglasses',
          'womens-bags',
        ],
      _ => <String>[normalized],
    };

    return products
        .where((product) =>
            allowedCategories.contains(product.productCategory.toLowerCase()))
        .toList();
  }

  List<ProductModel> categoryPreview(String categoryName) {
    final categoryProducts = findByCategory(categoryName: categoryName);
    if (categoryProducts.isEmpty) {
      return <ProductModel>[];
    }
    final sorted = [...categoryProducts]
      ..sort((a, b) => b.productRating.compareTo(a.productRating));
    return sorted.take(8).toList();
  }

  List<ProductModel> searchQuery(
      {required String searchText, required List<ProductModel> passedList}) {
    List<ProductModel> searchList = passedList
        .where((element) =>
            element.productTitle
                .toLowerCase()
                .contains(searchText.toLowerCase()) ||
            element.productBrand
                .toLowerCase()
                .contains(searchText.toLowerCase()) ||
            element.productCategory
                .toLowerCase()
                .contains(searchText.toLowerCase()))
        .toList();
    return searchList;
  }

  List<ProductModel> similarProducts({
    required ProductModel product,
    int limit = 6,
  }) {
    final matches = products
        .where((item) =>
            item.productId != product.productId &&
            (item.productCategory == product.productCategory ||
                item.productBrand == product.productBrand))
        .toList();
    return matches.take(limit).toList();
  }

  final productDb = FirebaseFirestore.instance.collection("products");

  Future<List<ProductModel>> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && products.isNotEmpty) {
      return products;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await productDb
          .orderBy('createdAt', descending: false)
          .get()
          .timeout(const Duration(seconds: 8))
          .then((productSnapshot) {
        products.clear();
        for (var element in productSnapshot.docs) {
          final product = ProductModel.fromFirestore(element);
          products.insert(0, product);
        }
      });
      usingRemoteCatalog = false;
      errorMessage ??=
          products.isEmpty ? 'No products available right now.' : null;
      return products;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<ProductModel>> fetchProductsStream() {
    try {
      return productDb.snapshots().map((snapshot) {
        products.clear();
        for (var element in snapshot.docs) {
          products.insert(0, ProductModel.fromFirestore(element));
        }
        return products;
      });
    } catch (e) {
      rethrow;
    }
  }

//   List<ProductModel> products = [
// // Books
//     ProductModel(
// //1
//       productId: 'UUP',
//       productTitle: "Uvod u programiranje",
//       productPrice: "1200.00",
//       productCategory: "Books",
//       productDescription: "Description",
//       productImage:
//           "https://media.istockphoto.com/id/157482029/photo/stack-of-books.jpg?s=612x612&w=0&k=20&c=ZxSsWKNcVpEzrJ3_kxAUuhBCT3P_dfnmJ81JegPD8eE=",
//       productQuantity: "10",
//     ),
//     ProductModel(
// //2
//       productId: 'UMPS',
//       productTitle: "Uvod u mikroprocesorske sisteme",
//       productPrice: "1200.00",
//       productCategory: "Books",
//       productDescription: "Description",
//       productImage:
//           "https://media.istockphoto.com/id/162833243/photo/blank-book.jpg?s=612x612&w=0&k=20&c=7xDB49s-hV2U87Wx6Kk9NhHbW6H-f0eb3wWSR5sqlEk=",
//       productQuantity: "15",
//     ),
// // Stationery
//     ProductModel(
// //3
//       productId: const Uuid().v4(),
//       productTitle: "Marker",
//       productPrice: "20.00",
//       productCategory: "Stationery",
//       productDescription: "Description",
//       productImage:
//           "https://media.istockphoto.com/id/183136428/photo/pink-highlighter-with-the-cap-off-on-white-background.jpg?s=612x612&w=0&k=20&c=u75MvVSdfu1EKlCOdAqFNRIUWck98jY6FMJlr42bVpg=",
//       productQuantity: "200",
//     ),
//     ProductModel(
// //4
//       productId: const Uuid().v4(),
//       productTitle: "Gumica",
//       productPrice: "50.00",
//       productCategory: "Stationery",
//       productDescription: "Description",
//       productImage:
//           "https://media.istockphoto.com/id/96955913/photo/erased-line.jpg?s=612x612&w=0&k=20&c=IxC4-X1jLlXt_jPP_FRMuqw5qqgYuZVVZLV3pN__3VU=",
//       productQuantity: "300",
//     ),
// // Merch
//     ProductModel(
// //5
//       productId: const Uuid().v4(),
//       productTitle: "Majica",
//       productPrice: "1000.00",
//       productCategory: "Merch",
//       productDescription: "Description",
//       productImage:
//           "https://media.istockphoto.com/id/465485415/photo/blue-t-shirt-clipping-path.jpg?s=612x612&w=0&k=20&c=VzE9RWytBIg6wb47plb5kl08brIuzAnlN1B6W1Pd6tg=",
//       productQuantity: "100",
//     ),
//     ProductModel(
// //6
//       productId: const Uuid().v4(),
//       productTitle: "Ceger",
//       productPrice: "1200.00",
//       productCategory: "Merch",
//       productDescription: "Description",
//       productImage:
//           "https://media.istockphoto.com/id/2219139040/photo/cotton-canvas-burlap-bag-with-drawstring-mock-up-isolated-zero-waste-concept-eco-sack-made.jpg?s=612x612&w=0&k=20&c=M_wKIgzEEOuagok_l8Fv9lJ2Fc-CwtofLxQshTfjUMQ=",
//       productQuantity: "100",
//     ),
//   ];
}
