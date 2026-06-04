import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:alarme_feriados/data/feriados/feriado_fonte.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';

/// Busca feriados nacionais brasileiros via BrasilAPI (gratuita, sem chave).
///
/// Endpoint: GET https://brasilapi.com.br/api/feriados/v1/{ano}
/// Retorna apenas feriados nacionais; estaduais/municipais ficam para
/// uma [FeriadoFonte] adicional (ex: API paga) injetada no repositório.
class BrasilApiFonte implements FeriadoFonte {
  BrasilApiFonte({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://brasilapi.com.br/api/feriados/v1';

  @override
  Future<List<FeriadoCache>> buscarAno(int ano, {String? codigoIBGE}) async {
    final uri = Uri.parse('$_base/$ano');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return [];

    final list = json.decode(response.body) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final date = m['date'] as String;
      return FeriadoCache(
        data: date,
        nome: m['name'] as String,
        tipo: 'nacional',
        codigoIBGE: '0',
        ano: int.parse(date.substring(0, 4)),
      );
    }).toList();
  }
}
