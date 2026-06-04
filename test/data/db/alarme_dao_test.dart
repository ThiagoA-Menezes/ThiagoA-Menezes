import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const base = Alarme(hora: '07:00', diasDaSemana: 0x1F);

  test('inserir retorna id positivo', () async {
    final id = await db.alarmeDao.inserir(base);
    expect(id, greaterThan(0));
  });

  test('buscarPorId retorna o alarme inserido', () async {
    final id = await db.alarmeDao.inserir(base);
    final result = await db.alarmeDao.buscarPorId(id);
    expect(result?.hora, '07:00');
    expect(result?.diasDaSemana, 0x1F);
    expect(result?.ativo, isTrue);
  });

  test('buscarTodos retorna todos os alarmes', () async {
    await db.alarmeDao.inserir(base);
    await db.alarmeDao.inserir(base.copyWith(hora: '08:00'));
    final list = await db.alarmeDao.buscarTodos();
    expect(list, hasLength(2));
  });

  test('atualizar modifica o alarme existente', () async {
    final id = await db.alarmeDao.inserir(base);
    await db.alarmeDao.atualizar(base.copyWith(id: id, hora: '09:00'));
    final result = await db.alarmeDao.buscarPorId(id);
    expect(result?.hora, '09:00');
  });

  test('deletar remove o alarme', () async {
    final id = await db.alarmeDao.inserir(base);
    await db.alarmeDao.deletar(id);
    expect(await db.alarmeDao.buscarPorId(id), isNull);
  });
}
