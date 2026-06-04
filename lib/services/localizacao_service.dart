import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:alarme_feriados/domain/models/localizacao.dart';

/// Detecta a localização atual via GPS e geocodificação reversa.
/// Retorna null se permissão negada ou geocoding falhar.
class LocalizacaoService {
  static Future<Localizacao?> detectar() async {
    if (!await _permissaoGranted()) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.low),
    );
    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    return Localizacao(
      cidade: p.subAdministrativeArea?.isNotEmpty == true
          ? p.subAdministrativeArea!
          : (p.locality ?? ''),
      estado: _ufDe(p.administrativeArea ?? ''),
      codigoIBGE: '0',
    );
  }

  static Future<bool> _permissaoGranted() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  static String _ufDe(String nome) {
    const mapa = {
      'Acre': 'AC',
      'Alagoas': 'AL',
      'Amapá': 'AP',
      'Amazonas': 'AM',
      'Bahia': 'BA',
      'Ceará': 'CE',
      'Distrito Federal': 'DF',
      'Espírito Santo': 'ES',
      'Goiás': 'GO',
      'Maranhão': 'MA',
      'Mato Grosso': 'MT',
      'Mato Grosso do Sul': 'MS',
      'Minas Gerais': 'MG',
      'Pará': 'PA',
      'Paraíba': 'PB',
      'Paraná': 'PR',
      'Pernambuco': 'PE',
      'Piauí': 'PI',
      'Rio de Janeiro': 'RJ',
      'Rio Grande do Norte': 'RN',
      'Rio Grande do Sul': 'RS',
      'Rondônia': 'RO',
      'Roraima': 'RR',
      'Santa Catarina': 'SC',
      'São Paulo': 'SP',
      'Sergipe': 'SE',
      'Tocantins': 'TO',
    };
    return mapa[nome] ?? (nome.length >= 2 ? nome.substring(0, 2).toUpperCase() : '');
  }
}
