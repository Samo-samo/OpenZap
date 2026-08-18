import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/app/app.dart';

void main() {
  testWidgets('OpenZapApp builds without error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OpenZapApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('OpenZap'), findsOneWidget);
  });
}