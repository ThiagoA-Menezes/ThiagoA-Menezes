import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarme_feriados/features/alarme_tocando/alarme_tocando_page.dart';

void main() {
  testWidgets('exibe título e os dois botões de ação', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AlarmeTocandoPage(alarmId: 1, titulo: 'Ano Novo')),
    );
    expect(find.text('Ano Novo'), findsOneWidget);
    expect(find.text('Parar'), findsOneWidget);
    expect(find.text('Soneca\n10 min'), findsOneWidget);
  });

  testWidgets('usa título padrão quando titulo está vazio', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AlarmeTocandoPage(alarmId: 2, titulo: '')),
    );
    expect(find.text('Alarme Feriados'), findsOneWidget);
  });

  testWidgets('exibe ícone de alarme e ícones dos botões', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AlarmeTocandoPage(alarmId: 3, titulo: 'Tiradentes')),
    );
    expect(find.byIcon(Icons.alarm), findsOneWidget);
    expect(find.byIcon(Icons.snooze), findsOneWidget);
    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
  });
}
