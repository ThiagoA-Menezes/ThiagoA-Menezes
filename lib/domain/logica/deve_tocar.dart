import 'package:alarme_feriados/core/datas.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';

/// Retorna true se [alarme] deve tocar no dia [dia].
///
/// Retorna false quando:
/// - o alarme estiver inativo;
/// - [dia] não estiver no bitmask [Alarme.diasDaSemana] (bit 0 = segunda);
/// - [dia] for um feriado presente em [diasFeriados] (formato "YYYY-MM-DD");
/// - [dia] for um dia de folga da [escala] rotativa informada.
bool deveTocar({
  required Alarme alarme,
  required DateTime dia,
  required List<String> diasFeriados,
  EscalaUsuario? escala,
}) {
  if (!alarme.ativo) return false;
  if (alarme.diasDaSemana & (1 << (dia.weekday - 1)) == 0) return false;
  if (diasFeriados.contains(isoDate(dia))) return false;
  if (escala != null && escala.diasFolga > 0 && _isDiaFolga(escala, dia)) {
    return false;
  }
  return true;
}

bool _isDiaFolga(EscalaUsuario escala, DateTime dia) {
  final ref = DateTime.parse(escala.dataInicioReferencia);
  final diff = DateTime(dia.year, dia.month, dia.day)
      .difference(DateTime(ref.year, ref.month, ref.day))
      .inDays;
  final ciclo = escala.diasTrabalho + escala.diasFolga;
  if (ciclo == 0) return false;
  // Dart's % retorna negativo quando diff < 0
  final pos = diff % ciclo;
  return (pos < 0 ? pos + ciclo : pos) >= escala.diasTrabalho;
}
