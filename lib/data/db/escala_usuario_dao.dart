import 'package:drift/drift.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/tables.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';

part 'escala_usuario_dao.g.dart';

@DriftAccessor(tables: [EscalasUsuario])
class EscalaUsuarioDao extends DatabaseAccessor<AppDatabase>
    with _$EscalaUsuarioDaoMixin {
  EscalaUsuarioDao(super.db);

  Future<int> inserir(EscalaUsuario escala) =>
      into(escalasUsuario).insert(_toCompanion(escala));

  Future<EscalaUsuario?> buscarPorId(int id) async {
    final row = await (select(escalasUsuario)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<EscalaUsuario>> buscarTodos() async =>
      (await select(escalasUsuario).get()).map(_toDomain).toList();

  Future<int> atualizar(EscalaUsuario escala) {
    final id = escala.id;
    if (id == null) return Future.value(0);
    return (update(escalasUsuario)..where((t) => t.id.equals(id)))
        .write(_toCompanion(escala));
  }

  Future<int> deletar(int id) =>
      (delete(escalasUsuario)..where((t) => t.id.equals(id))).go();

  EscalaUsuario _toDomain(EscalaUsuarioRow r) => EscalaUsuario(
        id: r.id,
        tipo: r.tipo,
        diasTrabalho: r.diasTrabalho,
        diasFolga: r.diasFolga,
        dataInicioReferencia: r.dataInicioReferencia,
      );

  EscalasUsuarioCompanion _toCompanion(EscalaUsuario e) =>
      EscalasUsuarioCompanion(
        tipo: Value(e.tipo),
        diasTrabalho: Value(e.diasTrabalho),
        diasFolga: Value(e.diasFolga),
        dataInicioReferencia: Value(e.dataInicioReferencia),
      );
}
