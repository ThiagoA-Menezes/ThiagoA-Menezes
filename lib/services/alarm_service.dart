import 'dart:io' show Platform;

import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static const _alarmKitChannel = MethodChannel('alarme_feriados/alarm_kit');

  /// Solicita as permissões necessárias para a plataforma atual.
  /// Retorna true se todas as permissões foram concedidas.
  static Future<bool> solicitarPermissoes() async {
    if (Platform.isAndroid) return _solicitarAndroid();
    if (Platform.isIOS) return _solicitarIOS();
    return true;
  }

  static Future<void> agendar({
    required int id,
    required DateTime dateTime,
    String titulo = '',
  }) =>
      Alarm.set(
        alarmSettings: AlarmSettings(
          id: id,
          dateTime: dateTime,
          assetAudioPath: 'assets/audio/alarme.mp3',
          loopAudio: true,
          vibrate: true,
          fadeDuration: 3.0,
          androidFullScreenIntent: true,
          notificationSettings: NotificationSettings(
            title: titulo.isEmpty ? 'Alarme Feriados' : titulo,
            body: 'Toque para parar o alarme',
            stopButton: 'Parar',
          ),
        ),
      );

  static Future<void> cancelar(int id) => Alarm.stop(id);

  static Future<void> soneca(int id, {int minutos = 10}) async {
    await Alarm.stop(id);
    await agendar(
      id: id,
      dateTime: DateTime.now().add(Duration(minutes: minutos)),
    );
  }

  // --- Permissões Android ---

  static Future<bool> _solicitarAndroid() async {
    final exactAlarm = await Permission.scheduleExactAlarm.request();
    final notifications = await Permission.notification.request();
    return exactAlarm.isGranted && notifications.isGranted;
  }

  // --- Permissões iOS (AlarmKit) ---

  // Chama o canal nativo que invoca AKAlarmManager.requestAuthorization()
  static Future<bool> _solicitarIOS() async {
    final result =
        await _alarmKitChannel.invokeMethod<bool>('requestAlarmKitAuthorization');
    return result ?? false;
  }
}
