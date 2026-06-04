import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/data/db/database_provider.dart';
import 'package:alarme_feriados/data/feriados/feriado_repository.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';

final feriadoRepositoryProvider = FutureProvider<FeriadoRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return FeriadoRepository(db);
});

class FeriadosNotifier extends AsyncNotifier<List<FeriadoCache>> {
  @override
  Future<List<FeriadoCache>> build() async {
    final repo = await ref.watch(feriadoRepositoryProvider.future);
    final ano = DateTime.now().year;
    // Sincroniza silenciosamente; erros de rede não quebram a UI
    await repo.sincronizarAno(ano).catchError((_) {});
    return repo.feriadosDoAno(ano);
  }

  Future<void> sincronizar() async {
    state = const AsyncLoading();
    final repo = await ref.read(feriadoRepositoryProvider.future);
    await repo.sincronizarAno(DateTime.now().year, forcar: true);
    ref.invalidateSelf();
  }

  Future<void> inserirManual(FeriadoCache feriado) async {
    final repo = await ref.read(feriadoRepositoryProvider.future);
    await repo.inserirManual(feriado);
    ref.invalidateSelf();
  }

  Future<void> deletar(int id) async {
    final repo = await ref.read(feriadoRepositoryProvider.future);
    await repo.deletar(id);
    ref.invalidateSelf();
  }
}

final feriadosProvider =
    AsyncNotifierProvider<FeriadosNotifier, List<FeriadoCache>>(
  FeriadosNotifier.new,
);
