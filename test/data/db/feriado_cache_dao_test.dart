import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const base = FeriadoCache(
    data: '2025-01-01',
    nome: 'Ano Novo',
    tipo: 'nacional',
    codigoIBGE: '0',
    ano: 2025,
  );

  test('inserir retorna id positivo', () async {
    final id = await db.feriadoCacheDao.inserir(base);
    expect(id, greaterThan(0));
  });

  test('buscarPorId retorna o feriado inserido', () async {
    final id = await db.feriadoCacheDao.inserir(base);
    final result = await db.feriadoCacheDao.buscarPorId(id);
    expect(result?.nome, 'Ano Novo');
    expect(result?.tipo, 'nacional');
    expect(result?.ano, 2025);
  });

  test('buscarTodos retorna todos os feriados', () async {
    await db.feriadoCacheDao.inserir(base);
    await db.feriadoCacheDao
        .inserir(base.copyWith(data: '2025-04-21', nome: 'Tiradentes'));
    final list = await db.feriadoCacheDao.buscarTodos();
    expect(list, hasLength(2));
  });

  test('atualizar modifica o feriado existente', () async {
    final id = await db.feriadoCacheDao.inserir(base);
    await db.feriadoCacheDao
        .atualizar(base.copyWith(id: id, nome: 'Confraternização Universal'));
    final result = await db.feriadoCacheDao.buscarPorId(id);
    expect(result?.nome, 'Confraternização Universal');
  });

  test('deletar remove o feriado', () async {
    final id = await db.feriadoCacheDao.inserir(base);
    await db.feriadoCacheDao.deletar(id);
    expect(await db.feriadoCacheDao.buscarPorId(id), isNull);
  });
}
