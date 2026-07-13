import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';

void main() {
  testWidgets('Title widget renders provided label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TitlesTextWidget(label: 'Admin Dashboard'),
        ),
      ),
    );

    expect(find.text('Admin Dashboard'), findsOneWidget);
  });
}
