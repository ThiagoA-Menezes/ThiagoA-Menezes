import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/data/db/database_provider.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/services/alarm_service.dart';
import 'package:alarme_feriados/services/reagendador.dart';

class AlarmesNotifier extends AsyncNotifier<List<Alarme>> {
  @override
  Future<List<Alarme>> build() async {
    final db = await ref.watch(appDatabaseProvider.future);
    return db.alarmeDao.buscarTodos();
  }

  Future<void> criar(Alarme alarme) async {
    final db = await ref.read(appDatabaseProvider.future);
    await db.alarmeDao.inserir(alarme);
    await Reagendador.executar(db: db);
    ref.invalidateSelf();
  }

  Future<void> atualizar(Alarme alarme) async {
    final db = await ref.read(appDatabaseProvider.future);
    await db.alarmeDao.atualizar(alarme);
    if (!alarme.ativo) await _cancelarSemCrash(alarme.id!);
    await Reagendador.executar(db: db);
    ref.invalidateSelf();
  }

  Future<void> deletar(int id) async {
    final db = await ref.read(appDatabaseProvider.future);
    await db.alarmeDao.deletar(id);
    await _cancelarSemCrash(id);
    ref.invalidateSelf();
  }

  Future<void> toggleAtivo(Alarme alarme) =>
      atualizar(alarme.copyWith(ativo: !alarme.ativo));

  static Future<void> _cancelarSemCrash(int id) async {
    try {
      await AlarmService.cancelar(id);
    } on MissingPluginException {
      // Engine indisponível em testes host
    }
  }
}

final alarmesProvider =
    AsyncNotifierProvider<AlarmesNotifier, List<Alarme>>(AlarmesNotifier.new);
