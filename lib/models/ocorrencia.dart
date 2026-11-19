import 'package:flutter/material.dart';

/// Etapas do atendimento. Espelha o CHECK de OCORRENCIAS.STATUS no Oracle.
enum StatusOcorrencia {
  aberta('ABERTA', 'Aberta'),
  emAnalise('EM_ANALISE', 'Em análise'),
  emAndamento('EM_ANDAMENTO', 'Em andamento'),
  resolvida('RESOLVIDA', 'Resolvida');

  const StatusOcorrencia(this.codigo, this.rotulo);

  /// Valor gravado no banco (igual ao usado no Oracle).
  final String codigo;
  final String rotulo;

  /// Próxima etapa do fluxo, ou null se já está resolvida.
  StatusOcorrencia? get proximo =>
      index + 1 < StatusOcorrencia.values.length
          ? StatusOcorrencia.values[index + 1]
          : null;

  static StatusOcorrencia deCodigo(String codigo) =>
      StatusOcorrencia.values.firstWhere((s) => s.codigo == codigo);
}

/// Espelha OCORRENCIAS.PRIORIDADE.
enum Prioridade {
  baixa('BAIXA', 'Baixa'),
  media('MEDIA', 'Média'),
  alta('ALTA', 'Alta');

  const Prioridade(this.codigo, this.rotulo);
  final String codigo;
  final String rotulo;

  static Prioridade deCodigo(String codigo) =>
      Prioridade.values.firstWhere((p) => p.codigo == codigo);
}

/// Tipo de problema. Espelha as tabelas CATEGORIAS e ORGAOS.
class Categoria {
  const Categoria({
    required this.id,
    required this.nome,
    required this.orgao,
    required this.prazoDias,
    required this.prioridadePadrao,
    required this.icone,
    required this.cor,
  });

  final int id;
  final String nome;
  final String orgao;
  final int prazoDias;
  final Prioridade prioridadePadrao;
  final IconData icone;
  final Color cor;

  static const List<Categoria> todas = [
    Categoria(
      id: 1,
      nome: 'Buraco na via',
      orgao: 'Zeladoria Urbana',
      prazoDias: 15,
      prioridadePadrao: Prioridade.baixa,
      icone: Icons.add_road,
      cor: Color(0xFF8D6E63),
    ),
    Categoria(
      id: 2,
      nome: 'Iluminação com defeito',
      orgao: 'Iluminação Pública',
      prazoDias: 7,
      prioridadePadrao: Prioridade.media,
      icone: Icons.lightbulb_outline,
      cor: Color(0xFFF9A825),
    ),
    Categoria(
      id: 3,
      nome: 'Lixo ou entulho',
      orgao: 'Limpeza Urbana',
      prazoDias: 10,
      prioridadePadrao: Prioridade.baixa,
      icone: Icons.delete_outline,
      cor: Color(0xFF2E7D32),
    ),
    Categoria(
      id: 4,
      nome: 'Calçada danificada',
      orgao: 'Zeladoria Urbana',
      prazoDias: 30,
      prioridadePadrao: Prioridade.baixa,
      icone: Icons.accessible,
      cor: Color(0xFF1565C0),
    ),
    Categoria(
      id: 5,
      nome: 'Alagamento ou bueiro',
      orgao: 'Defesa Civil',
      prazoDias: 3,
      prioridadePadrao: Prioridade.alta,
      icone: Icons.water_drop_outlined,
      cor: Color(0xFF00838F),
    ),
  ];

  static Categoria porId(int id) =>
      todas.firstWhere((c) => c.id == id, orElse: () => todas.first);
}

/// Linha da linha do tempo. Espelha HISTORICO_OCORRENCIA.
class EventoHistorico {
  const EventoHistorico({
    required this.statusAntigo,
    required this.statusNovo,
    required this.observacao,
    required this.data,
  });

  final StatusOcorrencia? statusAntigo;
  final StatusOcorrencia statusNovo;
  final String observacao;
  final DateTime data;

  Map<String, dynamic> toJson() => {
        'statusAntigo': statusAntigo?.codigo,
        'statusNovo': statusNovo.codigo,
        'observacao': observacao,
        'data': data.toIso8601String(),
      };

  factory EventoHistorico.fromJson(Map<String, dynamic> json) =>
      EventoHistorico(
        statusAntigo: json['statusAntigo'] == null
            ? null
            : StatusOcorrencia.deCodigo(json['statusAntigo'] as String),
        statusNovo: StatusOcorrencia.deCodigo(json['statusNovo'] as String),
        observacao: json['observacao'] as String,
        data: DateTime.parse(json['data'] as String),
      );
}

/// Problema urbano registrado. Espelha a tabela OCORRENCIAS.
class Ocorrencia {
  const Ocorrencia({
    required this.id,
    required this.protocolo,
    required this.autorId,
    required this.categoriaId,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.prioridade,
    required this.criadoEm,
    required this.historico,
    this.endereco,
    this.fotoPath,
    this.apoiadores = const [],
    this.resolvidoEm,
  });

  final String id;
  final String protocolo;
  final String autorId;
  final int categoriaId;
  final String descricao;
  final double latitude;
  final double longitude;
  final String? endereco;
  final String? fotoPath;
  final StatusOcorrencia status;
  final Prioridade prioridade;
  final List<String> apoiadores;
  final DateTime criadoEm;
  final DateTime? resolvidoEm;
  final List<EventoHistorico> historico;

  Categoria get categoria => Categoria.porId(categoriaId);
  int get qtdApoios => apoiadores.length;

  Ocorrencia copyWith({
    StatusOcorrencia? status,
    Prioridade? prioridade,
    List<String>? apoiadores,
    DateTime? resolvidoEm,
    List<EventoHistorico>? historico,
  }) =>
      Ocorrencia(
        id: id,
        protocolo: protocolo,
        autorId: autorId,
        categoriaId: categoriaId,
        descricao: descricao,
        latitude: latitude,
        longitude: longitude,
        endereco: endereco,
        fotoPath: fotoPath,
        status: status ?? this.status,
        prioridade: prioridade ?? this.prioridade,
        apoiadores: apoiadores ?? this.apoiadores,
        criadoEm: criadoEm,
        resolvidoEm: resolvidoEm ?? this.resolvidoEm,
        historico: historico ?? this.historico,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'protocolo': protocolo,
        'autorId': autorId,
        'categoriaId': categoriaId,
        'descricao': descricao,
        'latitude': latitude,
        'longitude': longitude,
        'endereco': endereco,
        'fotoPath': fotoPath,
        'status': status.codigo,
        'prioridade': prioridade.codigo,
        'apoiadores': apoiadores,
        'criadoEm': criadoEm.toIso8601String(),
        'resolvidoEm': resolvidoEm?.toIso8601String(),
        'historico': historico.map((e) => e.toJson()).toList(),
      };

  factory Ocorrencia.fromJson(Map<String, dynamic> json) => Ocorrencia(
        id: json['id'] as String,
        protocolo: json['protocolo'] as String,
        autorId: json['autorId'] as String,
        categoriaId: json['categoriaId'] as int,
        descricao: json['descricao'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        endereco: json['endereco'] as String?,
        fotoPath: json['fotoPath'] as String?,
        status: StatusOcorrencia.deCodigo(json['status'] as String),
        prioridade: Prioridade.deCodigo(json['prioridade'] as String),
        apoiadores: List<String>.from(json['apoiadores'] as List),
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        resolvidoEm: json['resolvidoEm'] == null
            ? null
            : DateTime.parse(json['resolvidoEm'] as String),
        historico: (json['historico'] as List)
            .map((e) => EventoHistorico.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Linha do painel de indicadores (equivale a PR_INDICADORES_POR_CATEGORIA).
class IndicadorCategoria {
  const IndicadorCategoria({
    required this.categoria,
    required this.total,
    required this.resolvidas,
    required this.totalApoios,
  });

  final Categoria categoria;
  final int total;
  final int resolvidas;
  final int totalApoios;

  double get percentualResolvidas =>
      total == 0 ? 0 : (resolvidas * 100 / total);
}

String formatarData(DateTime d) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
}
