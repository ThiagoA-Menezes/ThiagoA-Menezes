import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/data/db/database_provider.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';

class EscalaNotifier extends AsyncNotifier<EscalaUsuario?> {
  @override
  Future<EscalaUsuario?> build() async {
    final db = await ref.watch(appDatabaseProvider.future);
    final list = await db.escalaUsuarioDao.buscarTodos();
    return list.firstOrNull;
  }

  Future<void> salvar(EscalaUsuario escala) async {
    final db = await ref.read(appDatabaseProvider.future);
    final current = await db.escalaUsuarioDao.buscarTodos();
    if (current.isEmpty) {
      await db.escalaUsuarioDao.inserir(escala);
    } else {
      await db.escalaUsuarioDao.atualizar(escala.copyWith(id: current.first.id));
    }
    ref.invalidateSelf();
  }

  Future<void> remover() async {
    final db = await ref.read(appDatabaseProvider.future);
    final current = await db.escalaUsuarioDao.buscarTodos();
    for (final e in current) {
      await db.escalaUsuarioDao.deletar(e.id!);
    }
    ref.invalidateSelf();
  }
}

final escalaProvider =
    AsyncNotifierProvider<EscalaNotifier, EscalaUsuario?>(EscalaNotifier.new);
