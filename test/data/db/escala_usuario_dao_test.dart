import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const base = EscalaUsuario(
    tipo: '5x2',
    diasTrabalho: 5,
    diasFolga: 2,
    dataInicioReferencia: '2025-01-06',
  );

  test('inserir retorna id positivo', () async {
    final id = await db.escalaUsuarioDao.inserir(base);
    expect(id, greaterThan(0));
  });

  test('buscarPorId retorna a escala inserida', () async {
    final id = await db.escalaUsuarioDao.inserir(base);
    final result = await db.escalaUsuarioDao.buscarPorId(id);
    expect(result?.tipo, '5x2');
    expect(result?.diasTrabalho, 5);
    expect(result?.diasFolga, 2);
  });

  test('buscarTodos retorna todas as escalas', () async {
    await db.escalaUsuarioDao.inserir(base);
    await db.escalaUsuarioDao.inserir(base.copyWith(tipo: '12x36'));
    final list = await db.escalaUsuarioDao.buscarTodos();
    expect(list, hasLength(2));
  });

  test('atualizar modifica a escala existente', () async {
    final id = await db.escalaUsuarioDao.inserir(base);
    await db.escalaUsuarioDao
        .atualizar(base.copyWith(id: id, tipo: '6x1', diasFolga: 1));
    final result = await db.escalaUsuarioDao.buscarPorId(id);
    expect(result?.tipo, '6x1');
    expect(result?.diasFolga, 1);
  });

  test('deletar remove a escala', () async {
    final id = await db.escalaUsuarioDao.inserir(base);
    await db.escalaUsuarioDao.deletar(id);
    expect(await db.escalaUsuarioDao.buscarPorId(id), isNull);
  });
}
