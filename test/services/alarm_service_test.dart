import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/services/alarm_service.dart';

void main() {
  group('AlarmRingEvent', () {
    test('armazena id e titulo fornecidos', () {
      const e = AlarmRingEvent(id: 42, titulo: 'Ano Novo');
      expect(e.id, equals(42));
      expect(e.titulo, equals('Ano Novo'));
    });

    test('aceita titulo vazio', () {
      const e = AlarmRingEvent(id: 0, titulo: '');
      expect(e.titulo, isEmpty);
    });

    test('id zero é válido', () {
      const e = AlarmRingEvent(id: 0, titulo: 'Carnaval');
      expect(e.id, equals(0));
    });
  });
}
