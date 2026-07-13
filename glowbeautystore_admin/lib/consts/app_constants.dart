import 'package:flutter/material.dart';

class AppConstants {
  static const String imageUrl =
      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80';

  static List<String> categoriesList = [
    'beauty',
    'fragrances',
    'skin-care',
    'makeup',
    'hair-care',
  ];

  static List<DropdownMenuItem<String>>? get categoriesDropDownList {
    List<DropdownMenuItem<String>>? menuItem =
        List<DropdownMenuItem<String>>.generate(
      categoriesList.length,
      (index) => DropdownMenuItem(
        value: categoriesList[index],
        child: Text(categoriesList[index]),
      ),
    );
    return menuItem;
  }
}
