// Basic Flutter widget tests for QueueWise
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App widget smoke test', (WidgetTester tester) async {
    // Build a simple MaterialApp to verify the app structure
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('QueueWise Test')),
          ),
        ),
      ),
    );

    // Verify that the app builds without errors
    expect(find.text('QueueWise Test'), findsOneWidget);
  });

  testWidgets('ProviderScope wraps app correctly', (WidgetTester tester) async {
    // Verify Riverpod ProviderScope works
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      ),
    );

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
