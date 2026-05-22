import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openmodels/main.dart';

void main() {
  testWidgets('App smoke test - verifies initialization', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenModelsApp(),
      ),
    );

    // Verify the presence of MaterialApp or expected screen layouts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
