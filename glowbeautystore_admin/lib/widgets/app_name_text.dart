import 'package:flutter/material.dart';

import 'title_text.dart';

class AppNameTextWidget extends StatelessWidget {
  const AppNameTextWidget({super.key, this.fontSize = 30});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TitlesTextWidget(
      label: "Glow Beauty Admin",
      fontSize: fontSize,
    );
  }
}
