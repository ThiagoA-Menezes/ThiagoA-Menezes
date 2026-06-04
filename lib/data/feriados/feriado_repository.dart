import 'package:http/http.dart' as http;

import 'package:alarme_feriados/data/db/app_database.dart';
import 'package:alarme_feriados/data/db/feriado_cache_dao.dart';
import 'package:alarme_feriados/data/feriados/brasil_api_fonte.dart';
import 'package:alarme_feriados/data/feriados/feriado_fonte.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';

/// Gerencia o cache anual de feriados e agrega múltiplas [FeriadoFonte].
///
/// Para adicionar uma API paga: instancie a implementação de [FeriadoFonte]
/// e passe-a em [fontes]. Ela será consultada junto com a BrasilAPI em toda
/// chamada a [sincronizarAno].
class FeriadoRepository {
  FeriadoRepository(
    AppDatabase db, {
    http.Client? client,
    List<FeriadoFonte>? fontes,
  })  : _dao = db.feriadoCacheDao,
        _fontes = fontes ?? [BrasilApiFonte(client: client ?? http.Client())];

  final FeriadoCacheDao _dao;
  final List<FeriadoFonte> _fontes;

  /// Todos os feriados do [ano] presentes no cache local.
  Future<List<FeriadoCache>> feriadosDoAno(int ano) => _dao.buscarPorAno(ano);

  /// Sincroniza feriados das fontes para [ano].
  ///
  /// Apaga e re-insere apenas os tipos gerenciados pelas fontes ('nacional',
  /// 'estadual'); feriados 'municipal' cadastrados manualmente são preservados.
  /// Com [forcar] = true ignora o cache existente.
  Future<void> sincronizarAno(int ano, {bool forcar = false}) async {
    if (!forcar) {
      final cached = await _dao.buscarPorAno(ano);
      if (cached.any((f) => f.tipo == 'nacional')) return;
    }
    await _dao.deletarPorAnoETipo(ano, 'nacional');
    await _dao.deletarPorAnoETipo(ano, 'estadual');

    for (final fonte in _fontes) {
      final feriados = await fonte.buscarAno(ano);
      for (final f in feriados) {
        await _dao.inserir(f);
      }
    }
  }

  /// Insere um feriado manual (tipo 'municipal') no cache.
  Future<int> inserirManual(FeriadoCache feriado) => _dao.inserir(feriado);

  /// Remove um feriado pelo id.
  Future<void> deletar(int id) => _dao.deletar(id);
}
