import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/features/home/home_page.dart';

void main() {
  testWidgets('HomePage renderiza Scaffold vazio', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
