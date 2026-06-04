import 'package:drift/drift.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/tables.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';

part 'alarme_dao.g.dart';

@DriftAccessor(tables: [Alarmes])
class AlarmeDao extends DatabaseAccessor<AppDatabase> with _$AlarmeDaoMixin {
  AlarmeDao(super.db);

  Future<int> inserir(Alarme alarme) =>
      into(alarmes).insert(_toCompanion(alarme));

  Future<Alarme?> buscarPorId(int id) async {
    final row = await (select(alarmes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Alarme>> buscarTodos() async =>
      (await select(alarmes).get()).map(_toDomain).toList();

  Future<int> atualizar(Alarme alarme) {
    final id = alarme.id;
    if (id == null) return Future.value(0);
    return (update(alarmes)..where((t) => t.id.equals(id)))
        .write(_toCompanion(alarme));
  }

  Future<int> deletar(int id) =>
      (delete(alarmes)..where((t) => t.id.equals(id))).go();

  Alarme _toDomain(AlarmeRow r) => Alarme(
        id: r.id,
        hora: r.hora,
        diasDaSemana: r.diasDaSemana,
        ativo: r.ativo,
        titulo: r.titulo,
      );

  AlarmesCompanion _toCompanion(Alarme a) => AlarmesCompanion(
        hora: Value(a.hora),
        diasDaSemana: Value(a.diasDaSemana),
        ativo: Value(a.ativo),
        titulo: Value(a.titulo),
      );
}
