import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';
import 'package:alarme_feriados/services/reagendador.dart';

// Helper local — evita importar core/datas.dart nos testes
String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  // ─── Critério de aceite ────────────────────────────────────────────────────
  // "alarme em dia de feriado simulado não dispara"
  test('validarDisparo retorna false quando hoje é feriado', () async {
    final hoje = DateTime.now();

    final id = await db.alarmeDao.inserir(
      const Alarme(hora: '07:00', diasDaSemana: 0x7F),
    );
    await db.feriadoCacheDao.inserir(FeriadoCache(
      data: _iso(hoje),
      nome: 'Feriado Simulado',
      tipo: 'nacional',
      codigoIBGE: '0',
      ano: hoje.year,
    ));

    final result = await Reagendador.validarDisparo(id, db: db);
    expect(result, isFalse);
  });

  test('validarDisparo retorna true quando não é feriado e dia está no bitmask', () async {
    // Hora futura para garantir que o alarme não passou
    final id = await db.alarmeDao.inserir(
      const Alarme(hora: '23:59', diasDaSemana: 0x7F),
    );
    // Sem feriados inseridos

    final result = await Reagendador.validarDisparo(id, db: db);
    expect(result, isTrue);
  });

  test('validarDisparo retorna false para alarme inexistente', () async {
    final result = await Reagendador.validarDisparo(9999, db: db);
    expect(result, isFalse);
  });
}
