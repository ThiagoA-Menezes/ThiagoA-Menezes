import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'package:alarme_feriados/app.dart';
import 'package:alarme_feriados/services/reagendador.dart';

/// Ponto de entrada do WorkManager — executa em isolate separado.
/// @pragma necessário para evitar tree-shaking do entry point nativo.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    await Alarm.init(showDebugLogs: false);
    await Reagendador.executar();
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init(showDebugLogs: false);

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  // keep: não substitui tarefa já registrada (sobrevive a reboots via WorkManager)
  Workmanager()
      .registerPeriodicTask(
        Reagendador.taskId,
        Reagendador.taskId,
        frequency: const Duration(hours: 24),
        initialDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      )
      .ignore();

  runApp(const ProviderScope(child: App()));
}
