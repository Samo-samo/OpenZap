import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/app/app.dart';

void main() {
  testWidgets('OpenZapApp builds without error', (tester) async {
    await tester.pumpWidget(const OpenZapApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'OpenZap');
  });
}
