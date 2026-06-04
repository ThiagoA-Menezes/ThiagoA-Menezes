import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/data/db/database_provider.dart';
import 'package:alarme_feriados/domain/models/localizacao.dart';

class LocalizacaoNotifier extends AsyncNotifier<Localizacao?> {
  @override
  Future<Localizacao?> build() async {
    final db = await ref.watch(appDatabaseProvider.future);
    final list = await db.localizacaoDao.buscarTodos();
    return list.firstOrNull;
  }

  Future<void> salvar(Localizacao loc) async {
    final db = await ref.read(appDatabaseProvider.future);
    final current = await db.localizacaoDao.buscarTodos();
    if (current.isEmpty) {
      await db.localizacaoDao.inserir(loc);
    } else {
      await db.localizacaoDao.atualizar(loc.copyWith(id: current.first.id));
    }
    ref.invalidateSelf();
  }
}

final localizacaoProvider =
    AsyncNotifierProvider<LocalizacaoNotifier, Localizacao?>(
  LocalizacaoNotifier.new,
);
