import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/feriados/feriado_repository.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';
import 'package:alarme_feriados/features/feriados/feriados_page.dart';
import 'package:alarme_feriados/features/feriados/feriados_providers.dart';

AppDatabase _memDb() => AppDatabase(NativeDatabase.memory());

Widget _wrap(AppDatabase db, {MockClient? client}) => ProviderScope(
      overrides: [
        feriadoRepositoryProvider.overrideWith(
          (ref) => FeriadoRepository(
            db,
            client: client ??
                MockClient((_) async => Response(jsonEncode([]), 200)),
          ),
        ),
      ],
      child: const MaterialApp(home: FeriadosPage()),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = _memDb());
  tearDown(() => db.close());

  testWidgets('exibe mensagem quando cache vazio e API retorna vazio',
      (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum feriado. Toque em ↻ para buscar.'),
      findsOneWidget,
    );
  });

  testWidgets('exibe feriados retornados pela API', (tester) async {
    final client = MockClient(
      (_) async => Response(
        jsonEncode([
          {'date': '${DateTime.now().year}-01-01', 'name': 'Ano Novo', 'type': 'national'},
        ]),
        200,
      ),
    );
    await tester.pumpWidget(_wrap(db, client: client));
    await tester.pumpAndSettle();

    expect(find.text('Ano Novo'), findsOneWidget);
    expect(find.text('NACIONAL / ESTADUAL'), findsOneWidget);
  });

  testWidgets('feriado de hoje exibe chip "Hoje"', (tester) async {
    final hoje = DateTime.now();
    final dataHoje =
        '${hoje.year.toString().padLeft(4, '0')}-'
        '${hoje.month.toString().padLeft(2, '0')}-'
        '${hoje.day.toString().padLeft(2, '0')}';

    final client = MockClient(
      (_) async => Response(
        jsonEncode([
          {'date': dataHoje, 'name': 'Feriado Hoje', 'type': 'national'},
        ]),
        200,
      ),
    );
    await tester.pumpWidget(_wrap(db, client: client));
    await tester.pumpAndSettle();

    expect(find.text('Hoje'), findsOneWidget);
  });

  testWidgets('feriado municipal aparece na seção "Municipal"', (tester) async {
    final ano = DateTime.now().year;
    await db.feriadoCacheDao.inserir(FeriadoCache(
      data: '$ano-07-09',
      nome: 'Revolução Const.',
      tipo: 'municipal',
      codigoIBGE: '3509502',
      ano: ano,
    ));
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Revolução Const.'), findsOneWidget);
    expect(find.text('MUNICIPAL (MANUAL)'), findsOneWidget);
  });

  testWidgets('botão sync está presente no AppBar', (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.sync), findsOneWidget);
  });
}
