import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'package:alarme_feriados/features/alarme_tocando/alarme_tocando_page.dart';
import 'package:alarme_feriados/features/home/home_page.dart';
import 'package:alarme_feriados/services/reagendador.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AlarmSettings> _ringSubscription;

  @override
  void initState() {
    super.initState();
    _ringSubscription = Alarm.ringStream.stream.listen(_onAlarmRing);
  }

  @override
  void dispose() {
    _ringSubscription.cancel();
    super.dispose();
  }

  // Revalida no momento do disparo antes de exibir a UI.
  // Se hoje for feriado, Reagendador cancela e reagenda silenciosamente.
  void _onAlarmRing(AlarmSettings settings) {
    Reagendador.validarDisparo(settings.id).then((deve) {
      if (!deve) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => AlarmeTocandoPage(
            alarmId: settings.id,
            titulo: settings.notificationSettings.title,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Alarme Feriados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
