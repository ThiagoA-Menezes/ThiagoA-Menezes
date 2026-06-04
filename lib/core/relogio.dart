/// Converte [hhmm] (formato interno "HH:mm") para exibição conforme [use24h].
///
/// Em 12h: '07:00' → '7:00 AM', '13:30' → '1:30 PM', '00:00' → '12:00 AM'.
/// Em 24h: o valor é retornado sem alteração.
String formatarHora(String hhmm, {required bool use24h}) {
  if (use24h) return hhmm;
  final partes = hhmm.split(':');
  final h = int.parse(partes[0]);
  final m = partes[1];
  final period = h < 12 ? 'AM' : 'PM';
  final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$h12:$m $period';
}
