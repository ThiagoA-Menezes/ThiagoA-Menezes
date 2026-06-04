import 'package:drift/drift.dart';

import 'package:alarme_feriados/data/db/alarme_dao.dart';
import 'package:alarme_feriados/data/db/escala_usuario_dao.dart';
import 'package:alarme_feriados/data/db/feriado_cache_dao.dart';
import 'package:alarme_feriados/data/db/localizacao_dao.dart';
import 'package:alarme_feriados/data/db/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Alarmes, EscalasUsuario, Localizacoes, FeriadosCache],
  daos: [AlarmeDao, EscalaUsuarioDao, LocalizacaoDao, FeriadoCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
