import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/database_provider.dart';
import 'package:alarme_feriados/features/localizacao/localizacao_page.dart';

Widget _wrap(AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((ref) => db)],
      child: const MaterialApp(home: LocalizacaoPage()),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('exibe campos cidade, estado e código IBGE', (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Cidade'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Estado (UF)'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Código IBGE (opcional)'),
      findsOneWidget,
    );
  });

  testWidgets('snackbar ao salvar sem cidade/estado', (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Preencha cidade e estado.'), findsOneWidget);
  });

  testWidgets('salvar com cidade e estado persiste e navega de volta',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Center(child: Text('home'))),
      ),
    ));
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const LocalizacaoPage()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Cidade'), 'Campinas');
    await tester.enterText(find.widgetWithText(TextField, 'Estado (UF)'), 'SP');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    final locs = await db.localizacaoDao.buscarTodos();
    expect(locs.first.cidade, equals('Campinas'));
    expect(locs.first.estado, equals('SP'));
  });
}
