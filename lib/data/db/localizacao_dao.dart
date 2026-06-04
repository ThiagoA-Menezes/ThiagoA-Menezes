import 'package:drift/drift.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/tables.dart';
import 'package:alarme_feriados/domain/models/localizacao.dart';

part 'localizacao_dao.g.dart';

@DriftAccessor(tables: [Localizacoes])
class LocalizacaoDao extends DatabaseAccessor<AppDatabase>
    with _$LocalizacaoDaoMixin {
  LocalizacaoDao(super.db);

  Future<int> inserir(Localizacao loc) =>
      into(localizacoes).insert(_toCompanion(loc));

  Future<Localizacao?> buscarPorId(int id) async {
    final row = await (select(localizacoes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Localizacao>> buscarTodos() async =>
      (await select(localizacoes).get()).map(_toDomain).toList();

  Future<int> atualizar(Localizacao loc) {
    final id = loc.id;
    if (id == null) return Future.value(0);
    return (update(localizacoes)..where((t) => t.id.equals(id)))
        .write(_toCompanion(loc));
  }

  Future<int> deletar(int id) =>
      (delete(localizacoes)..where((t) => t.id.equals(id))).go();

  Localizacao _toDomain(LocalizacaoRow r) => Localizacao(
        id: r.id,
        cidade: r.cidade,
        estado: r.estado,
        codigoIBGE: r.codigoIBGE,
      );

  LocalizacoesCompanion _toCompanion(Localizacao l) => LocalizacoesCompanion(
        cidade: Value(l.cidade),
        estado: Value(l.estado),
        codigoIBGE: Value(l.codigoIBGE),
      );
}
