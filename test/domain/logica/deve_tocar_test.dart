import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/domain/logica/deve_tocar.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';

void main() {
  // 2025-01-06 = segunda (weekday 1)  /  2025-01-07 = terça (weekday 2)
  const todos = Alarme(hora: '07:00', diasDaSemana: 0x7F); // seg–dom
  const soSegunda = Alarme(hora: '07:00', diasDaSemana: 0x01); // bit 0

  test('retorna true quando ativo, dia no bitmask e sem feriado', () {
    expect(
      deveTocar(alarme: todos, dia: DateTime(2025, 1, 6), diasFeriados: []),
      isTrue,
    );
  });

  test('retorna false quando o dia é feriado', () {
    expect(
      deveTocar(
        alarme: todos,
        dia: DateTime(2025, 1, 1), // Ano Novo
        diasFeriados: ['2025-01-01'],
      ),
      isFalse,
    );
  });

  test('retorna false quando alarme inativo', () {
    const inativo = Alarme(hora: '07:00', diasDaSemana: 0x7F, ativo: false);
    expect(
      deveTocar(alarme: inativo, dia: DateTime(2025, 1, 6), diasFeriados: []),
      isFalse,
    );
  });

  test('retorna false quando o dia não está no bitmask', () {
    // soSegunda (0x01) & terça (1<<1 = 2) == 0 → false
    expect(
      deveTocar(alarme: soSegunda, dia: DateTime(2025, 1, 7), diasFeriados: []),
      isFalse,
    );
  });

  test('retorna true em segunda que não é feriado (lista de feriados ignorados)', () {
    expect(
      deveTocar(
        alarme: soSegunda,
        dia: DateTime(2025, 1, 6),
        diasFeriados: ['2025-01-01', '2025-04-21'],
      ),
      isTrue,
    );
  });

  test('retorna false por bitmask independente de ser feriado', () {
    // A terça fora do bitmask já é false; o feriado é irrelevante
    expect(
      deveTocar(
        alarme: soSegunda,
        dia: DateTime(2025, 1, 7),
        diasFeriados: ['2025-01-07'],
      ),
      isFalse,
    );
  });
}
