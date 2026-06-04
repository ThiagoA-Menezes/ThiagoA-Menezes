import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:alarme_feriados/core/datas.dart';
import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/domain/logica/deve_tocar.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';
import 'package:alarme_feriados/domain/models/localizacao.dart';
import 'package:alarme_feriados/services/alarm_service.dart';

class Reagendador {
  static const taskId = 'reagendamento_diario';
  static const _horizonte = 7;

  /// Recalcula e reagenda os próximos [_horizonte] dias para todos os alarmes
  /// ativos, considerando feriados filtrados por localização e escala do usuário.
  static Future<void> executar({AppDatabase? db}) async {
    final database = db ?? await _abrirDb();
    final close = db == null;
    try {
      final ativos =
          (await database.alarmeDao.buscarTodos()).where((a) => a.ativo);
      final loc = await _locAtiva(database);
      final escala = await _escalaAtiva(database);
      for (final alarme in ativos) {
        try {
          await _reagendarProximo(database, alarme, loc: loc, escala: escala);
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
  /// Se não deve (feriado, folga ou dia fora do bitmask), cancela e reagenda
  /// a próxima ocorrência válida. Retorna false nesse caso.
  static Future<bool> validarDisparo(int alarmeId, {AppDatabase? db}) async {
    final database = db ?? await _abrirDb();
    final close = db == null;
    try {
      final alarme = await database.alarmeDao.buscarPorId(alarmeId);
      if (alarme == null) return false;

      final hoje = DateTime.now();
      final loc = await _locAtiva(database);
      final escala = await _escalaAtiva(database);
      final feriados = await _feriadosDoDia(database, hoje, loc: loc);
      final deve = deveTocar(
        alarme: alarme,
        dia: hoje,
        diasFeriados: feriados,
        escala: escala,
      );

      if (!deve) {
        try {
          await AlarmService.cancelar(alarmeId);
          await _reagendarProximo(
            database,
            alarme,
            loc: loc,
            escala: escala,
            pulando: hoje,
          );
        } on MissingPluginException {
          // Ignorado intencionalmente
        }
      }
      return deve;
    } finally {
      if (close) await database.close();
    }
  }

  static Future<void> _reagendarProximo(
    AppDatabase db,
    Alarme alarme, {
    Localizacao? loc,
    EscalaUsuario? escala,
    DateTime? pulando,
  }) async {
    for (var i = 0; i < _horizonte; i++) {
      final dia = _trimTime(DateTime.now().add(Duration(days: i)));

      if (pulando != null && isoDate(dia) == isoDate(pulando)) continue;

      final feriados = await _feriadosDoDia(db, dia, loc: loc);
      if (!deveTocar(
        alarme: alarme,
        dia: dia,
        diasFeriados: feriados,
        escala: escala,
      )) continue;

      final alvo = _buildAlarmDateTime(dia, alarme.hora);
      if (alvo.isAfter(DateTime.now())) {
        await AlarmService.agendar(
          id: alarme.id!,
          dateTime: alvo,
          titulo: alarme.titulo,
        );
        return;
      }
    }
    await AlarmService.cancelar(alarme.id!);
  }

  static Future<List<String>> _feriadosDoDia(
    AppDatabase db,
    DateTime dia, {
    Localizacao? loc,
  }) async {
    final todos = await db.feriadoCacheDao.buscarTodos();
    return todos
        .where((f) => f.ano == dia.year)
        .where((f) => _filtraPorLoc(f, loc))
        .map((f) => f.data)
        .toList();
  }

  static bool _filtraPorLoc(FeriadoCache f, Localizacao? loc) {
    if (f.tipo == 'nacional') return true;
    if (loc == null || loc.codigoIBGE == '0') return false;
    // Código IBGE estadual = 2 primeiros dígitos do código municipal (7 dígitos)
    final estadoIBGE =
        loc.codigoIBGE.length >= 2 ? loc.codigoIBGE.substring(0, 2) : '';
    if (f.tipo == 'estadual') return f.codigoIBGE == estadoIBGE;
    if (f.tipo == 'municipal') return f.codigoIBGE == loc.codigoIBGE;
    return false;
  }

  static Future<Localizacao?> _locAtiva(AppDatabase db) async {
    final list = await db.localizacaoDao.buscarTodos();
    return list.firstOrNull;
  }

  static Future<EscalaUsuario?> _escalaAtiva(AppDatabase db) async {
    final list = await db.escalaUsuarioDao.buscarTodos();
    return list.firstOrNull;
  }

  static DateTime _trimTime(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Constrói o DateTime local do alarme a partir de [dia] + [hora] ("HH:mm").
  /// DateTime() com args posicionais cria hora LOCAL — correto sob mudança de
  /// fuso/DST porque o SO converte para epoch no momento do agendamento.
  static DateTime _buildAlarmDateTime(DateTime dia, String hora) {
    final p = hora.split(':');
    return DateTime(dia.year, dia.month, dia.day, int.parse(p[0]), int.parse(p[1]));
  }

  static Future<AppDatabase> _abrirDb() async {
    final dir = await getApplicationDocumentsDirectory();
    return AppDatabase(
      NativeDatabase(File(p.join(dir.path, 'alarme_feriados.db'))),
    );
  }
}
