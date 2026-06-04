import 'package:drift/drift.dart';

@DataClassName('AlarmeRow')
class Alarmes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get hora => text()();
  IntColumn get diasDaSemana => integer()();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  TextColumn get titulo => text().withDefault(const Constant(''))();
}

@DataClassName('EscalaUsuarioRow')
class EscalasUsuario extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tipo => text()();
  IntColumn get diasTrabalho => integer()();
  IntColumn get diasFolga => integer()();
  TextColumn get dataInicioReferencia => text()();
}

@DataClassName('LocalizacaoRow')
class Localizacoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cidade => text()();
  TextColumn get estado => text()();
  TextColumn get codigoIBGE => text().unique()();
}

@DataClassName('FeriadoCacheRow')
class FeriadosCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get data => text()();
  TextColumn get nome => text()();
  TextColumn get tipo => text()();
  TextColumn get codigoIBGE => text()();
  IntColumn get ano => integer()();
}
