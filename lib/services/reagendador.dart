import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:alarme_feriados/core/datas.dart';
import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/logica/deve_tocar.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/services/alarm_service.dart';

class Reagendador {
  static const taskId = 'reagendamento_diario';
  static const _horizonte = 7;

  /// Recalcula e reagenda os próximos [_horizonte] dias para todos os alarmes
  /// ativos, pulando feriados. Chamado pelo WorkManager e no boot.
  static Future<void> executar({AppDatabase? db}) async {
    final database = db ?? await _abrirDb();
    final close = db == null;
    try {
      final ativos =
          (await database.alarmeDao.buscarTodos()).where((a) => a.ativo);
      for (final alarme in ativos) {
        try {
          await _reagendarProximo(database, alarme);
        } on MissingPluginException {
          // Engine indisponível (testes host ou isolate sem registro de plugin)
        }
      }
    } finally {
      if (close) await database.close();
    }
  }

  /// Verifica se o alarme [alarmeId] deve tocar hoje.
  ///
  /// Se não deve (feriado ou dia fora do bitmask), cancela o toque atual e
  /// reagenda a próxima ocorrência válida. Retorna false nesse caso.
  static Future<bool> validarDisparo(int alarmeId, {AppDatabase? db}) async {
    final database = db ?? await _abrirDb();
    final close = db == null;
    try {
      final alarme = await database.alarmeDao.buscarPorId(alarmeId);
      if (alarme == null) return false;

      final hoje = DateTime.now();
      final feriados = await _feriadosDoDia(database, hoje);
      final deve = deveTocar(alarme: alarme, dia: hoje, diasFeriados: feriados);

      if (!deve) {
        // MissingPluginException ocorre em testes host (sem FlutterEngine completo)
        try {
          await AlarmService.cancelar(alarmeId);
          await _reagendarProximo(database, alarme, pulando: hoje);
        } on MissingPluginException {
          // Ignorado intencionalmente — lógica de retorno não depende disso
        }
      }
      return deve;
    } finally {
      if (close) await database.close();
    }
  }

  // Encontra a próxima ocorrência válida de [alarme] no horizonte de [_horizonte]
  // dias e agenda. [pulando] exclui um dia específico da busca.
  static Future<void> _reagendarProximo(
    AppDatabase db,
    Alarme alarme, {
    DateTime? pulando,
  }) async {
    for (var i = 0; i < _horizonte; i++) {
      final dia = _trimTime(DateTime.now().add(Duration(days: i)));

      if (pulando != null && isoDate(dia) == isoDate(pulando)) continue;

      final feriados = await _feriadosDoDia(db, dia);
      if (!deveTocar(alarme: alarme, dia: dia, diasFeriados: feriados)) continue;

      final partes = alarme.hora.split(':');
      final alvo = DateTime(
        dia.year, dia.month, dia.day,
        int.parse(partes[0]),
        int.parse(partes[1]),
      );
      if (alvo.isAfter(DateTime.now())) {
        await AlarmService.agendar(
          id: alarme.id!,
          dateTime: alvo,
          titulo: alarme.titulo,
        );
        return;
      }
    }
    // Nenhuma ocorrência válida no horizonte: cancela
    await AlarmService.cancelar(alarme.id!);
  }

  static Future<List<String>> _feriadosDoDia(
    AppDatabase db,
    DateTime dia,
  ) async {
    final todos = await db.feriadoCacheDao.buscarTodos();
    return todos.where((f) => f.ano == dia.year).map((f) => f.data).toList();
  }

  static DateTime _trimTime(DateTime d) => DateTime(d.year, d.month, d.day);

  static Future<AppDatabase> _abrirDb() async {
    final dir = await getApplicationDocumentsDirectory();
    return AppDatabase(
      NativeDatabase(File(p.join(dir.path, 'alarme_feriados.db'))),
    );
  }
}
