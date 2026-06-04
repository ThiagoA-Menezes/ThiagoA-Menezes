import 'package:drift/drift.dart';

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/tables.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';

part 'feriado_cache_dao.g.dart';

@DriftAccessor(tables: [FeriadosCache])
class FeriadoCacheDao extends DatabaseAccessor<AppDatabase>
    with _$FeriadoCacheDaoMixin {
  FeriadoCacheDao(super.db);

  Future<int> inserir(FeriadoCache feriado) =>
      into(feriadosCache).insert(_toCompanion(feriado));

  Future<FeriadoCache?> buscarPorId(int id) async {
    final row = await (select(feriadosCache)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<FeriadoCache>> buscarTodos() async =>
      (await select(feriadosCache).get()).map(_toDomain).toList();

  Future<int> atualizar(FeriadoCache feriado) {
    final id = feriado.id;
    if (id == null) return Future.value(0);
    return (update(feriadosCache)..where((t) => t.id.equals(id)))
        .write(_toCompanion(feriado));
  }

  Future<int> deletar(int id) =>
      (delete(feriadosCache)..where((t) => t.id.equals(id))).go();

  FeriadoCache _toDomain(FeriadoCacheRow r) => FeriadoCache(
        id: r.id,
        data: r.data,
        nome: r.nome,
        tipo: r.tipo,
        codigoIBGE: r.codigoIBGE,
        ano: r.ano,
      );

  FeriadosCacheCompanion _toCompanion(FeriadoCache f) => FeriadosCacheCompanion(
        data: Value(f.data),
        nome: Value(f.nome),
        tipo: Value(f.tipo),
        codigoIBGE: Value(f.codigoIBGE),
        ano: Value(f.ano),
      );
}
