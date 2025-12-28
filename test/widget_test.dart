// This is a basic Flutter widget test for Emplooy app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emplooy_app/main.dart';
import 'package:emplooy_app/core/storage/local_storage.dart';

void main() {
  testWidgets('Emplooy app smoke test', (WidgetTester tester) async {
    // Inicializar storage
    await LocalStorage.instance.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EmplooyApp(),
      ),
    );

    // Verify that the app loads
    await tester.pumpAndSettle();
    
    // The app should show either language selection or login page
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
