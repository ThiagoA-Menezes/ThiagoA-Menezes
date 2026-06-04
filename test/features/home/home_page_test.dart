import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/database_provider.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/features/home/home_page.dart';

Widget _wrap(AppDatabase db) => ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
      ],
      child: const MaterialApp(home: HomePage()),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('exibe mensagem quando lista vazia', (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum alarme cadastrado.'), findsOneWidget);
  });

  testWidgets('exibe alarme cadastrado no banco', (tester) async {
    await db.alarmeDao.inserir(const Alarme(hora: '08:00', diasDaSemana: 0x1F));
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('FAB navega para tela de criação', (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Novo alarme'), findsOneWidget);
  });
}
