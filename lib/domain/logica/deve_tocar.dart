import 'package:alarme_feriados/core/datas.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';

/// Retorna true se [alarme] deve tocar no [dia].
///
/// Retorna false quando:
/// - o alarme estiver inativo;
/// - [dia] não estiver no bitmask [Alarme.diasDaSemana] (bit 0 = segunda);
/// - [dia] for um feriado presente em [diasFeriados] (formato "YYYY-MM-DD").
bool deveTocar({
  required Alarme alarme,
  required DateTime dia,
  required List<String> diasFeriados,
}) {
  if (!alarme.ativo) return false;
  // DateTime.weekday: 1 = seg … 7 = dom  →  bit 0 = seg … bit 6 = dom
  if (alarme.diasDaSemana & (1 << (dia.weekday - 1)) == 0) return false;
  return !diasFeriados.contains(isoDate(dia));
}
