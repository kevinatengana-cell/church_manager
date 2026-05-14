// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:metrique_local/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EvangelisationApp());

    // Verify that our app builds successfully without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
