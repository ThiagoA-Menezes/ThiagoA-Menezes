import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/feriados/feriado_fonte.dart';
import 'package:alarme_feriados/data/feriados/feriado_repository.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _brasilApiJson(List<String> datas) => datas
    .map((d) => {
          'date': d,
          'name': 'Feriado ${d.substring(5)}',
          'type': 'national',
        })
    .toList();

MockClient _mockOk(List<String> datas) =>
    MockClient((_) async => Response(jsonEncode(_brasilApiJson(datas)), 200));

/// Stub de FeriadoFonte para testar arquitetura plugável sem HTTP.
class _FonteExtra implements FeriadoFonte {
  _FonteExtra(this._dados);
  final List<FeriadoCache> _dados;

  @override
  Future<List<FeriadoCache>> buscarAno(int ano, {String? codigoIBGE}) async =>
      _dados.where((f) => f.ano == ano).toList();
}

// ─── Testes ───────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  FeriadoRepository _repo({List<String> datas = const ['2025-01-01', '2025-04-21']}) =>
      FeriadoRepository(db, client: _mockOk(datas));

  // ─── Critério de aceite ──────────────────────────────────────────────────
  // "feriado do dia aparece e bloqueia o alarme"
  test('sincronizarAno persiste nacionais da BrasilAPI no cache', () async {
    await _repo().sincronizarAno(2025);

    final feriados = await _repo().feriadosDoAno(2025);
    expect(feriados.length, equals(2));
    expect(feriados.map((f) => f.data),
        containsAll(['2025-01-01', '2025-04-21']));
    expect(feriados.every((f) => f.tipo == 'nacional'), isTrue);
  });

  test('sincronizarAno não re-busca quando cache existe (cache hit)', () async {
    var chamadas = 0;
    final repo = FeriadoRepository(
      db,
      client: MockClient((_) async {
        chamadas++;
        return Response(jsonEncode(_brasilApiJson(['2025-01-01'])), 200);
      }),
    );

    await repo.sincronizarAno(2025);
    await repo.sincronizarAno(2025);

    expect(chamadas, equals(1));
  });

  test('sincronizarAno com forcar=true re-busca da API', () async {
    var chamadas = 0;
    final repo = FeriadoRepository(
      db,
      client: MockClient((_) async {
        chamadas++;
        return Response(jsonEncode(_brasilApiJson(['2025-01-01'])), 200);
      }),
    );

    await repo.sincronizarAno(2025);
    await repo.sincronizarAno(2025, forcar: true);

    expect(chamadas, equals(2));
  });

  test('inserirManual adiciona feriado municipal sem remover nacionais', () async {
    await _repo().sincronizarAno(2025);

    await _repo().inserirManual(const FeriadoCache(
      data: '2025-07-09',
      nome: 'Revolução Constitucionalista',
      tipo: 'municipal',
      codigoIBGE: '3509502',
      ano: 2025,
    ));

    final feriados = await _repo().feriadosDoAno(2025);
    expect(feriados.length, equals(3));
    expect(feriados.any((f) => f.tipo == 'municipal'), isTrue);
    expect(feriados.any((f) => f.tipo == 'nacional'), isTrue);
  });

  test('sincronizarAno forçado preserva feriados municipais', () async {
    final repo = FeriadoRepository(db, client: _mockOk(['2025-01-01']));
    await repo.sincronizarAno(2025);
    await repo.inserirManual(const FeriadoCache(
      data: '2025-07-09',
      nome: 'Feriado Municipal',
      tipo: 'municipal',
      codigoIBGE: '0',
      ano: 2025,
    ));

    await repo.sincronizarAno(2025, forcar: true);

    final feriados = await repo.feriadosDoAno(2025);
    expect(
      feriados.any((f) => f.tipo == 'municipal'),
      isTrue,
      reason: 'Municipal não deve ser removido pelo sync',
    );
  });

  test('deletar remove feriado do cache', () async {
    await _repo().sincronizarAno(2025);
    final repo = _repo();
    final feriados = await repo.feriadosDoAno(2025);
    final id = feriados.first.id!;

    await repo.deletar(id);

    final depois = await repo.feriadosDoAno(2025);
    expect(depois.any((f) => f.id == id), isFalse);
  });

  test('buscarPorAno isola feriados por ano', () async {
    await FeriadoRepository(db, client: _mockOk(['2025-01-01']))
        .sincronizarAno(2025);
    await FeriadoRepository(db, client: _mockOk(['2026-04-21']))
        .sincronizarAno(2026);

    final de2025 = await _repo().feriadosDoAno(2025);
    final de2026 = await _repo().feriadosDoAno(2026);

    expect(de2025.every((f) => f.ano == 2025), isTrue);
    expect(de2026.every((f) => f.ano == 2026), isTrue);
  });

  test('BrasilAPI retornando 500 não persiste dados', () async {
    final repo = FeriadoRepository(
      db,
      client: MockClient((_) async => Response('error', 500)),
    );

    await repo.sincronizarAno(2025);

    expect(await repo.feriadosDoAno(2025), isEmpty);
  });

  test('fonte adicional plugável é consultada junto com a principal', () async {
    final repoPlugavel = FeriadoRepository(
      db,
      fontes: [
        _FonteExtra([
          FeriadoCache(
            data: '2025-01-01',
            nome: 'Ano Novo',
            tipo: 'nacional',
            codigoIBGE: '0',
            ano: 2025,
          ),
        ]),
        _FonteExtra([
          FeriadoCache(
            data: '2025-07-09',
            nome: 'Feriado Estadual Extra',
            tipo: 'estadual',
            codigoIBGE: '35',
            ano: 2025,
          ),
        ]),
      ],
    );

    await repoPlugavel.sincronizarAno(2025);

    final feriados = await repoPlugavel.feriadosDoAno(2025);
    expect(feriados.length, equals(2));
    expect(feriados.any((f) => f.tipo == 'estadual'), isTrue);
    expect(feriados.any((f) => f.tipo == 'nacional'), isTrue);
  });
}
