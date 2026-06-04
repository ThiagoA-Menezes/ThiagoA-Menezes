import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/core/relogio.dart';

void main() {
  group('formatarHora — 24h', () {
    test('retorna hhmm sem alteração', () {
      expect(formatarHora('07:00', use24h: true), equals('07:00'));
      expect(formatarHora('13:30', use24h: true), equals('13:30'));
      expect(formatarHora('00:00', use24h: true), equals('00:00'));
      expect(formatarHora('23:59', use24h: true), equals('23:59'));
    });
  });

  group('formatarHora — 12h (AM/PM)', () {
    test('meia-noite → 12:xx AM', () {
      expect(formatarHora('00:00', use24h: false), equals('12:00 AM'));
      expect(formatarHora('00:30', use24h: false), equals('12:30 AM'));
    });

    test('manhã → h:mm AM (sem zero à esquerda)', () {
      expect(formatarHora('07:00', use24h: false), equals('7:00 AM'));
      expect(formatarHora('11:59', use24h: false), equals('11:59 AM'));
    });

    test('meio-dia → 12:xx PM', () {
      expect(formatarHora('12:00', use24h: false), equals('12:00 PM'));
      expect(formatarHora('12:01', use24h: false), equals('12:01 PM'));
    });

    test('tarde → h:mm PM', () {
      expect(formatarHora('13:00', use24h: false), equals('1:00 PM'));
      expect(formatarHora('13:30', use24h: false), equals('1:30 PM'));
      expect(formatarHora('23:59', use24h: false), equals('11:59 PM'));
    });
  });
}
