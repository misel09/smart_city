import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_city/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartCityApp());

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
