import 'package:alarme_feriados/domain/models/feriado_cache.dart';

/// Contrato para fontes de dados de feriados.
///
/// Para integrar uma API paga basta implementar esta interface e passá-la
/// ao construtor de [FeriadoRepository] via [fontes].
abstract interface class FeriadoFonte {
  /// Retorna feriados para [ano].
  /// [codigoIBGE] filtra por estado/município quando a fonte suportar.
  Future<List<FeriadoCache>> buscarAno(int ano, {String? codigoIBGE});
}
