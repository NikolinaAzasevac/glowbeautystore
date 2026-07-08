import 'package:glow_beauty_store/models/categories_model.dart';

class AppConstants {
  static const String imageUrl =
      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=800&q=80';

  static List<String> bannersImages = [
    "https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80",
    "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80",
    "https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=1200&q=80",
  ];

  static List<CategoriesModel> categoriesList = [
    CategoriesModel(id: "makeup", name: "Makeup"),
    CategoriesModel(id: "face-care", name: "Care"),
    CategoriesModel(id: "fragrance", name: "Fragrance"),
    CategoriesModel(id: "accessories", name: "Accessories"),
  ];
}
