import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ocorrencia.dart';

/// Tudo o que o app persiste: ocorrências, contador de protocolo e o
/// identificador anônimo do aparelho (o app não exige login).
class DadosApp {
  DadosApp({
    required this.ocorrencias,
    required this.sequencia,
    required this.deviceId,
    this.demoCarregada = false,
  });

  final List<Ocorrencia> ocorrencias;
  final int sequencia;
  final String deviceId;
  final bool demoCarregada;
}

/// Contrato de persistência. O app usa a implementação local; a camada Oracle
/// (pasta sql/) modela o mesmo domínio para um back-end futuro, sem mudar as
/// telas, apenas trocando esta implementação.
abstract class OcorrenciaRepository {
  Future<DadosApp> carregar();
  Future<void> salvar(DadosApp dados);
}

class LocalOcorrenciaRepository implements OcorrenciaRepository {
  static const _chave = 'ruatenta_v1';

  @override
  Future<DadosApp> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) {
      return DadosApp(
        ocorrencias: [],
        sequencia: 0,
        deviceId: 'dev-${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    try {
      final json = jsonDecode(texto) as Map<String, dynamic>;
      return DadosApp(
        ocorrencias: (json['ocorrencias'] as List)
            .map((e) => Ocorrencia.fromJson(e as Map<String, dynamic>))
            .toList(),
        sequencia: json['sequencia'] as int,
        deviceId: json['deviceId'] as String,
        demoCarregada: json['demoCarregada'] as bool? ?? false,
      );
    } catch (_) {
      // dado corrompido: começa limpo em vez de travar o app
      return DadosApp(
        ocorrencias: [],
        sequencia: 0,
        deviceId: 'dev-${DateTime.now().microsecondsSinceEpoch}',
      );
    }
  }

  @override
  Future<void> salvar(DadosApp dados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chave,
      jsonEncode({
        'ocorrencias': dados.ocorrencias.map((o) => o.toJson()).toList(),
        'sequencia': dados.sequencia,
        'deviceId': dados.deviceId,
        'demoCarregada': dados.demoCarregada,
      }),
    );
  }
}

/// Implementação em memória, usada nos testes automatizados.
class MemoriaOcorrenciaRepository implements OcorrenciaRepository {
  DadosApp? _dados;

  @override
  Future<DadosApp> carregar() async =>
      _dados ?? DadosApp(ocorrencias: [], sequencia: 0, deviceId: 'dev-teste');

  @override
  Future<void> salvar(DadosApp dados) async => _dados = dados;
}
