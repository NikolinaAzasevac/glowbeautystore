import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:glow_beauty_store/models/product_model.dart';

class BeautyProductsApiService {
  BeautyProductsApiService({http.Client? client})
      : _client = client ?? http.Client();

  static const String _baseUrl = 'https://dummyjson.com';
  static const List<String> _beautyCategories = <String>[
    'beauty',
    'fragrances',
    'skin-care',
    'womens-jewellery',
    'sunglasses',
    'womens-bags',
  ];

  final http.Client _client;

  Future<List<ProductModel>> fetchBeautyProducts() async {
    final responses = await Future.wait(
      _beautyCategories.map((category) async {
        final uri = Uri.parse('$_baseUrl/products/category/$category?limit=0');
        final response = await _client.get(uri).timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw Exception(
                'Products API request timed out.',
              ),
            );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
              'Products API request failed with status ${response.statusCode}.');
        }
        final Map<String, dynamic> decoded =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List products = decoded['products'] as List? ?? <dynamic>[];
        return products
            .whereType<Map>()
            .map((item) =>
                ProductModel.fromApiMap(Map<String, dynamic>.from(item)))
            .toList();
      }),
    );

    final merged = <String, ProductModel>{};
    for (final products in responses) {
      for (final product in products) {
        merged[product.productId] = product;
      }
    }

    final items = merged.values.toList()
      ..sort((a, b) => b.productRating.compareTo(a.productRating));
    return items;
  }
}
