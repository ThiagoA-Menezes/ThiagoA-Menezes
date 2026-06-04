import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarme_feriados/features/configuracoes/configuracoes_page.dart';
import 'package:alarme_feriados/features/configuracoes/configuracoes_providers.dart';

Future<Widget> _wrap({bool use24h = true}) async {
  SharedPreferences.setMockInitialValues({'use_24h': use24h});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: ConfiguracoesPage()),
  );
}

void main() {
  testWidgets('exibe switch "Formato 24 horas" ativado por padrão', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();
    final sw = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Formato 24 horas'),
    );
    expect(sw.value, isTrue);
  });

  testWidgets('exibe exemplo AM/PM quando formato 12h', (tester) async {
    await tester.pumpWidget(await _wrap(use24h: false));
    await tester.pumpAndSettle();
    expect(find.textContaining('AM'), findsOneWidget);
  });

  testWidgets('exibe exemplo 24h quando formato 24h', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();
    expect(find.textContaining('07:00'), findsOneWidget);
  });

  testWidgets('tile de Permissões e bateria está presente', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();
    expect(find.text('Permissões e bateria'), findsOneWidget);
  });

  testWidgets('toggle altera exibição do exemplo', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pumpAndSettle();

    // Antes: 24h
    expect(find.textContaining('07:00'), findsOneWidget);

    // Toggle para 12h
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();

    expect(find.textContaining('AM'), findsOneWidget);
  });
}
