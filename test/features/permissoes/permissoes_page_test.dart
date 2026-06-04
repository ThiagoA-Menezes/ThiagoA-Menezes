import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/features/permissoes/permissoes_page.dart';

Widget _wrap(Map<String, bool> status) => ProviderScope(
      overrides: [
        permissoesStatusProvider.overrideWith((ref) async => status),
      ],
      child: const MaterialApp(home: PermissoesPage()),
    );

void main() {
  testWidgets('exibe AppBar com título', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.text('Permissões e bateria'), findsOneWidget);
  });

  testWidgets('ícone verde quando permissão concedida', (tester) async {
    await tester.pumpWidget(_wrap({
      'alarme': true,
      'notificacao': true,
      'localizacao': true,
      'bateria': true,
    }));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.byIcon(Icons.cancel_outlined), findsNothing);
  });

  testWidgets('ícone vermelho e botão "Conceder" quando permissão negada', (tester) async {
    await tester.pumpWidget(_wrap({
      'alarme': false,
      'notificacao': false,
      'localizacao': false,
      'bateria': false,
    }));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cancel_outlined), findsWidgets);
    expect(find.text('Conceder'), findsWidgets);
  });

  testWidgets('card educacional de bateria OEM sempre visível', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.textContaining('Xiaomi'), findsOneWidget);
    expect(find.text('Abrir configurações do app'), findsOneWidget);
  });
}
