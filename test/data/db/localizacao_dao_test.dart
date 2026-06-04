import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/models/localizacao.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const base = Localizacao(
    cidade: 'São Paulo',
    estado: 'SP',
    codigoIBGE: '3550308',
  );

  test('inserir retorna id positivo', () async {
    final id = await db.localizacaoDao.inserir(base);
    expect(id, greaterThan(0));
  });

  test('buscarPorId retorna a localização inserida', () async {
    final id = await db.localizacaoDao.inserir(base);
    final result = await db.localizacaoDao.buscarPorId(id);
    expect(result?.cidade, 'São Paulo');
    expect(result?.codigoIBGE, '3550308');
  });

  test('buscarTodos retorna todas as localizações', () async {
    await db.localizacaoDao.inserir(base);
    await db.localizacaoDao.inserir(
      const Localizacao(cidade: 'Rio de Janeiro', estado: 'RJ', codigoIBGE: '3304557'),
    );
    final list = await db.localizacaoDao.buscarTodos();
    expect(list, hasLength(2));
  });

  test('atualizar modifica a localização existente', () async {
    final id = await db.localizacaoDao.inserir(base);
    await db.localizacaoDao
        .atualizar(base.copyWith(id: id, cidade: 'Campinas'));
    final result = await db.localizacaoDao.buscarPorId(id);
    expect(result?.cidade, 'Campinas');
  });

  test('deletar remove a localização', () async {
    final id = await db.localizacaoDao.inserir(base);
    await db.localizacaoDao.deletar(id);
    expect(await db.localizacaoDao.buscarPorId(id), isNull);
  });
}
