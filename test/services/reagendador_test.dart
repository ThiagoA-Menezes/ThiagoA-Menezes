import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';
import 'package:alarme_feriados/domain/models/localizacao.dart';
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

  // ─── Filtro por localização ───────────────────────────────────────────────
  test('feriado estadual é ignorado quando localização não configurada', () async {
    final hoje = DateTime.now();
    final id = await db.alarmeDao.inserir(
      const Alarme(hora: '23:59', diasDaSemana: 0x7F),
    );
    // Feriado estadual de SP sem localização salva
    await db.feriadoCacheDao.inserir(FeriadoCache(
      data: _iso(hoje),
      nome: 'Feriado Estadual SP',
      tipo: 'estadual',
      codigoIBGE: '35',
      ano: hoje.year,
    ));

    // Sem localização → feriado estadual não conta → alarme deve tocar
    final result = await Reagendador.validarDisparo(id, db: db);
    expect(result, isTrue);
  });

  test('feriado estadual bloqueia alarme quando localização está em SP', () async {
    final hoje = DateTime.now();
    final id = await db.alarmeDao.inserir(
      const Alarme(hora: '07:00', diasDaSemana: 0x7F),
    );
    await db.feriadoCacheDao.inserir(FeriadoCache(
      data: _iso(hoje),
      nome: 'Feriado Estadual SP',
      tipo: 'estadual',
      codigoIBGE: '35',
      ano: hoje.year,
    ));
    // Localização em SP: codigoIBGE começa com "35"
    await db.localizacaoDao.inserir(const Localizacao(
      cidade: 'Campinas',
      estado: 'SP',
      codigoIBGE: '3509502',
    ));

    final result = await Reagendador.validarDisparo(id, db: db);
    expect(result, isFalse);
  });

  // ─── Escala ───────────────────────────────────────────────────────────────
  test('validarDisparo retorna false em dia de folga da escala', () async {
    final hoje = DateTime.now();
    // Escala: 1 dia trabalho + 100 dias folga, referência = 1 dia atrás
    // → hoje cai em posição 1 → folga
    final referencia = _iso(hoje.subtract(const Duration(days: 1)));
    final id = await db.alarmeDao.inserir(
      const Alarme(hora: '07:00', diasDaSemana: 0x7F),
    );
    await db.escalaUsuarioDao.inserir(EscalaUsuario(
      tipo: 'teste',
      diasTrabalho: 1,
      diasFolga: 100,
      dataInicioReferencia: referencia,
    ));

    final result = await Reagendador.validarDisparo(id, db: db);
    expect(result, isFalse);
  });
}
