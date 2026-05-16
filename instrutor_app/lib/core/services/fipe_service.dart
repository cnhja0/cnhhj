import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/enums.dart';

/// Item da API FIPE (marca ou modelo).
class FipeItem {
  const FipeItem({required this.code, required this.name});

  final String code;
  final String name;

  factory FipeItem.fromJson(Map<String, dynamic> json) {
    // A FIPE retorna o código ora como int, ora como String — normalizamos.
    // Em versões antigas da API alguns items vinham sem código; nesse caso
    // retornamos string vazia e quem consome filtra.
    final dynamic raw = json['codigo'] ?? json['valor'] ?? json['id'];
    return FipeItem(
      code: raw?.toString() ?? '',
      name: (json['nome'] ?? '').toString(),
    );
  }

  bool get isValid => code.isNotEmpty && name.isNotEmpty;
}

/// Filtra items inválidos (sem código ou sem nome) — pequenos buracos na
/// resposta da FIPE não devem aparecer na UI.
extension FipeItemListExt on List<FipeItem> {
  List<FipeItem> validOnly() =>
      where((FipeItem e) => e.isValid).toList(growable: false);
}

/// Cliente da API pública da FIPE (parallelum.com.br).
///
/// • Não exige autenticação.
/// • Endpoints:
///     /carros|motos/marcas
///     /carros|motos/marcas/{codigo}/modelos
/// • Listas grandes (até ~500 modelos numa marca). Cabe na memória, mas
///   por isso o caller deve fazer cache (ver fipe_providers).
class FipeService {
  FipeService({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = 'https://parallelum.com.br/fipe/api/v1';

  final http.Client _client;
  final String _baseUrl;
  static const Duration _timeout = Duration(seconds: 8);

  String _segment(VehicleType type) {
    // FIPE só tem dois segmentos. Para 'ambos' assumimos carro como default
    // (motos são listadas separadamente — quem precisar das duas chama duas
    // vezes com tipo diferente).
    return type == VehicleType.moto ? 'motos' : 'carros';
  }

  /// Lista de marcas para o tipo de veículo. Ordenadas alfabeticamente
  /// pela própria API.
  Future<List<FipeItem>> brands(VehicleType type) async {
    final Uri uri = Uri.parse('$_baseUrl/${_segment(type)}/marcas');
    final http.Response res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw FipeException('FIPE marcas: HTTP ${res.statusCode}');
    }
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((dynamic e) => FipeItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false)
        .validOnly();
  }

  /// Modelos de uma marca específica. Retorna lista possivelmente vazia.
  Future<List<FipeItem>> models(VehicleType type, String brandCode) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/${_segment(type)}/marcas/$brandCode/modelos',
    );
    final http.Response res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw FipeException('FIPE modelos: HTTP ${res.statusCode}');
    }
    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> modelos = (data['modelos'] as List<dynamic>?) ?? <dynamic>[];
    return modelos
        .map((dynamic e) => FipeItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false)
        .validOnly();
  }

  void dispose() => _client.close();
}

class FipeException implements Exception {
  FipeException(this.message);
  final String message;
  @override
  String toString() => 'FipeException: $message';
}
