import 'dart:async';
import 'dart:io' show Platform;

import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmRingEvent {
  const AlarmRingEvent({required this.id, required this.titulo});

  final int id;
  final String titulo;
}

class AlarmService {
  static const _methodChannel = MethodChannel('alarme_feriados/alarm_kit');
  static const _eventChannel = EventChannel('alarme_feriados/alarm_kit_events');

  /// Stream de eventos de alarme tocando.
  /// iOS: EventChannel nativo do AlarmKit; Android: Alarm.ringStream mapeado.
  static Stream<AlarmRingEvent> get ringStream {
    if (Platform.isIOS) {
      return _eventChannel.receiveBroadcastStream().map((event) {
        final m = Map<String, dynamic>.from(event as Map);
        return AlarmRingEvent(
          id: m['id'] as int,
          titulo: m['titulo'] as String? ?? '',
        );
      });
    }
    return Alarm.ringStream.stream.map(
      (s) => AlarmRingEvent(id: s.id, titulo: s.notificationSettings.title),
    );
  }

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
  }) async {
    if (Platform.isIOS) {
      await _methodChannel.invokeMethod<void>('scheduleAlarm', {
        'id': id,
        'epochMs': dateTime.millisecondsSinceEpoch,
        'titulo': titulo.isEmpty ? 'Alarme Feriados' : titulo,
      });
      return;
    }
    await Alarm.set(
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
  }

  static Future<void> cancelar(int id) async {
    if (Platform.isIOS) {
      await _methodChannel.invokeMethod<void>('cancelAlarm', id);
      return;
    }
    await Alarm.stop(id);
  }

  static Future<void> soneca(int id, {int minutos = 10}) async {
    await cancelar(id);
    await agendar(
      id: id,
      dateTime: DateTime.now().add(Duration(minutes: minutos)),
    );
  }

  static Future<bool> _solicitarAndroid() async {
    final exactAlarm = await Permission.scheduleExactAlarm.request();
    final notifications = await Permission.notification.request();
    return exactAlarm.isGranted && notifications.isGranted;
  }

  static Future<bool> _solicitarIOS() async {
    final result =
        await _methodChannel.invokeMethod<bool>('requestAlarmKitAuthorization');
    return result ?? false;
  }
}
