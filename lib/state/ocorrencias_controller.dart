import 'package:flutter/foundation.dart';

import '../data/ocorrencia_repository.dart';
import '../models/ocorrencia.dart';

/// Regras de negócio do app. São as mesmas do pacote PKG_RUATENTA (Oracle):
/// protocolo, fluxo de status, prioridade por apoios, prazo e indicadores.
class OcorrenciasController extends ChangeNotifier {
  OcorrenciasController(
    this._repo, {
    DateTime Function()? agora,
    this.carregarDemo = true,
  }) : _agora = agora ?? DateTime.now;

  /// Apoios necessários para subir a prioridade (iguais às constantes do Oracle).
  static const int apoiosParaMedia = 5;
  static const int apoiosParaAlta = 10;

  final OcorrenciaRepository _repo;
  final DateTime Function() _agora;
  final bool carregarDemo;

  List<Ocorrencia> _ocorrencias = [];
  int _sequencia = 0;
  String _deviceId = '';
  bool _demoCarregada = false;
  bool _carregando = true;

  int? filtroCategoriaId;
  StatusOcorrencia? filtroStatus;

  bool get carregando => _carregando;
  String get deviceId => _deviceId;
  List<Ocorrencia> get todas => List.unmodifiable(_ocorrencias);
  List<Ocorrencia> get minhas =>
      _ocorrencias.where((o) => o.autorId == _deviceId).toList();

  /// Ocorrências visíveis no mapa conforme os filtros.
  List<Ocorrencia> get filtradas => _ocorrencias.where((o) {
        if (filtroCategoriaId != null && o.categoriaId != filtroCategoriaId) {
          return false;
        }
        if (filtroStatus != null && o.status != filtroStatus) return false;
        return true;
      }).toList();

  Future<void> iniciar() async {
    final dados = await _repo.carregar();
    _ocorrencias = List.of(dados.ocorrencias);
    _sequencia = dados.sequencia;
    _deviceId = dados.deviceId;
    _demoCarregada = dados.demoCarregada;
    if (carregarDemo && !_demoCarregada && _ocorrencias.isEmpty) {
      _semearDemonstracao();
      await _persistir();
    }
    _carregando = false;
    notifyListeners();
  }

  void definirFiltroCategoria(int? id) {
    filtroCategoriaId = id;
    notifyListeners();
  }

  void definirFiltroStatus(StatusOcorrencia? status) {
    filtroStatus = status;
    notifyListeners();
  }

  /// Gera o protocolo no formato RUA-AAAA-NNNNNN (igual a FN_GERAR_PROTOCOLO).
  String _gerarProtocolo() {
    _sequencia += 1;
    return 'RUA-${_agora().year}-${_sequencia.toString().padLeft(6, '0')}';
  }

  /// Registra uma ocorrência (equivale a PR_REGISTRAR_OCORRENCIA).
  /// Lança [ArgumentError] se a descrição for curta demais.
  Future<Ocorrencia> registrar({
    required int categoriaId,
    required String descricao,
    required double latitude,
    required double longitude,
    String? endereco,
    String? fotoPath,
  }) async {
    final texto = descricao.trim();
    if (texto.length < 5) {
      throw ArgumentError('Descreva o problema com pelo menos 5 caracteres.');
    }
    final categoria = Categoria.porId(categoriaId);
    final agora = _agora();
    final protocolo = _gerarProtocolo();
    final nova = Ocorrencia(
      id: 'oc-${agora.microsecondsSinceEpoch}-$protocolo',
      protocolo: protocolo,
      autorId: _deviceId,
      categoriaId: categoria.id,
      descricao: texto,
      latitude: latitude,
      longitude: longitude,
      endereco: (endereco == null || endereco.trim().isEmpty)
          ? null
          : endereco.trim(),
      fotoPath: fotoPath,
      status: StatusOcorrencia.aberta,
      prioridade: categoria.prioridadePadrao,
      criadoEm: agora,
      historico: [
        EventoHistorico(
          statusAntigo: null,
          statusNovo: StatusOcorrencia.aberta,
          observacao: 'Ocorrência registrada',
          data: agora,
        ),
      ],
    );
    _ocorrencias = [nova, ..._ocorrencias];
    await _persistir();
    notifyListeners();
    return nova;
  }

  Ocorrencia? porId(String id) {
    for (final o in _ocorrencias) {
      if (o.id == id) return o;
    }
    return null;
  }

  Ocorrencia? buscarPorProtocolo(String protocolo) {
    final alvo = protocolo.trim().toUpperCase();
    if (alvo.isEmpty) return null;
    for (final o in _ocorrencias) {
      if (o.protocolo == alvo) return o;
    }
    return null;
  }

  bool jaApoiou(Ocorrencia o) => o.apoiadores.contains(_deviceId);

  /// Apoia uma ocorrência (equivale a PR_APOIAR_OCORRENCIA + trigger de
  /// prioridade). Retorna false se o aparelho já tinha apoiado.
  /// [apoiadorId] existe para os testes simularem outros aparelhos; no app é
  /// sempre o identificador deste aparelho.
  Future<bool> apoiar(String ocorrenciaId, {String? apoiadorId}) async {
    final o = porId(ocorrenciaId);
    final quem = apoiadorId ?? _deviceId;
    if (o == null || o.apoiadores.contains(quem)) return false;
    final apoiadores = [...o.apoiadores, quem];
    var prioridade = o.prioridade;
    if (apoiadores.length >= apoiosParaAlta) {
      prioridade = Prioridade.alta;
    } else if (apoiadores.length >= apoiosParaMedia &&
        prioridade == Prioridade.baixa) {
      prioridade = Prioridade.media;
    }
    _substituir(o.copyWith(apoiadores: apoiadores, prioridade: prioridade));
    await _persistir();
    notifyListeners();
    return true;
  }

  /// Avança uma etapa no fluxo (equivale a PR_ATUALIZAR_STATUS). Só avança.
  /// No app é usado pelo modo demonstração, que simula a resposta do órgão.
  Future<bool> avancarStatus(String ocorrenciaId, {String? observacao}) async {
    final o = porId(ocorrenciaId);
    if (o == null) return false;
    final proximo = o.status.proximo;
    if (proximo == null) return false;
    final agora = _agora();
    _substituir(o.copyWith(
      status: proximo,
      resolvidoEm: proximo == StatusOcorrencia.resolvida ? agora : null,
      historico: [
        ...o.historico,
        EventoHistorico(
          statusAntigo: o.status,
          statusNovo: proximo,
          observacao: observacao ?? 'Atualização de status',
          data: agora,
        ),
      ],
    ));
    await _persistir();
    notifyListeners();
    return true;
  }

  /// Ocorrência fora do prazo da categoria (equivale a FN_ESTA_ATRASADA).
  bool estaAtrasada(Ocorrencia o) {
    if (o.status == StatusOcorrencia.resolvida) return false;
    final limite = o.criadoEm.add(Duration(days: o.categoria.prazoDias));
    return _agora().isAfter(limite);
  }

  int get totalAtrasadas => _ocorrencias.where(estaAtrasada).length;

  int get totalResolvidas => _ocorrencias
      .where((o) => o.status == StatusOcorrencia.resolvida)
      .length;

  double get percentualResolvidas => _ocorrencias.isEmpty
      ? 0
      : totalResolvidas * 100 / _ocorrencias.length;

  /// Dias médios até a resolução (equivale a FN_TEMPO_MEDIO_RESOLUCAO).
  double tempoMedioResolucaoDias({int? categoriaId}) {
    final resolvidas = _ocorrencias.where((o) =>
        o.status == StatusOcorrencia.resolvida &&
        o.resolvidoEm != null &&
        (categoriaId == null || o.categoriaId == categoriaId));
    if (resolvidas.isEmpty) return 0;
    final totalHoras = resolvidas
        .map((o) => o.resolvidoEm!.difference(o.criadoEm).inMinutes / 60)
        .reduce((a, b) => a + b);
    return totalHoras / resolvidas.length / 24;
  }

  /// Indicadores por categoria (equivale a PR_INDICADORES_POR_CATEGORIA).
  List<IndicadorCategoria> indicadores() {
    final lista = Categoria.todas.map((c) {
      final doGrupo = _ocorrencias.where((o) => o.categoriaId == c.id).toList();
      return IndicadorCategoria(
        categoria: c,
        total: doGrupo.length,
        resolvidas:
            doGrupo.where((o) => o.status == StatusOcorrencia.resolvida).length,
        totalApoios: doGrupo.fold(0, (soma, o) => soma + o.qtdApoios),
      );
    }).toList();
    lista.sort((a, b) {
      final porTotal = b.total.compareTo(a.total);
      return porTotal != 0
          ? porTotal
          : a.categoria.nome.compareTo(b.categoria.nome);
    });
    return lista;
  }

  /// Apaga tudo e recarrega os dados de demonstração.
  Future<void> reiniciarDemonstracao() async {
    _ocorrencias = [];
    _sequencia = 0;
    _demoCarregada = false;
    _semearDemonstracao();
    await _persistir();
    notifyListeners();
  }

  void _substituir(Ocorrencia nova) {
    _ocorrencias = [
      for (final o in _ocorrencias)
        if (o.id == nova.id) nova else o,
    ];
  }

  Future<void> _persistir() => _repo.salvar(DadosApp(
        ocorrencias: _ocorrencias,
        sequencia: _sequencia,
        deviceId: _deviceId,
        demoCarregada: _demoCarregada,
      ));

  /// Dados de demonstração, para o mapa e os indicadores não começarem vazios.
  void _semearDemonstracao() {
    final agora = _agora();
    Ocorrencia criar(int cat, String desc, double lat, double lng, String end,
        int diasAtras, StatusOcorrencia status, int apoios) {
      final categoria = Categoria.porId(cat);
      final criado = agora.subtract(Duration(days: diasAtras));
      final historico = <EventoHistorico>[
        EventoHistorico(
          statusAntigo: null,
          statusNovo: StatusOcorrencia.aberta,
          observacao: 'Ocorrência registrada',
          data: criado,
        ),
      ];
      var atual = StatusOcorrencia.aberta;
      var passo = 1;
      while (atual != status) {
        final prox = atual.proximo!;
        historico.add(EventoHistorico(
          statusAntigo: atual,
          statusNovo: prox,
          observacao: 'Atualização de status',
          data: criado.add(Duration(hours: 12 * passo)),
        ));
        atual = prox;
        passo += 1;
      }
      var prioridade = categoria.prioridadePadrao;
      if (apoios >= apoiosParaAlta) {
        prioridade = Prioridade.alta;
      } else if (apoios >= apoiosParaMedia && prioridade == Prioridade.baixa) {
        prioridade = Prioridade.media;
      }
      return Ocorrencia(
        id: 'demo-${_sequencia + 1}',
        protocolo: _gerarProtocolo(),
        autorId: 'demo',
        categoriaId: cat,
        descricao: desc,
        latitude: lat,
        longitude: lng,
        endereco: end,
        status: status,
        prioridade: prioridade,
        apoiadores: List.generate(apoios, (i) => 'vizinho-$i'),
        criadoEm: criado,
        resolvidoEm: status == StatusOcorrencia.resolvida
            ? historico.last.data
            : null,
        historico: historico,
      );
    }

    _ocorrencias = [
      criar(1, 'Buraco grande na faixa da direita, já causou dano em carros.',
          -23.5649, -46.6522, 'Av. Paulista, 1106', 9, StatusOcorrencia.emAnalise, 7),
      criar(2, 'Poste apagado há uma semana, a rua fica muito escura à noite.',
          -23.5629, -46.6544, 'Rua Teixeira da Silva, 80', 2, StatusOcorrencia.aberta, 3),
      criar(3, 'Entulho de obra acumulado na calçada.',
          -23.5675, -46.6498, 'Rua Pedroso Alvarenga, 15', 12, StatusOcorrencia.emAndamento, 5),
      criar(4, 'Calçada quebrada, impede a passagem de cadeira de rodas.',
          -23.5611, -46.6558, 'Alameda Santos, 450', 20, StatusOcorrencia.resolvida, 11),
      criar(5, 'Bueiro entupido, a rua alaga a cada chuva.',
          -23.5662, -46.6575, 'Rua Frei Caneca, 300', 5, StatusOcorrencia.aberta, 12),
      criar(2, 'Lâmpada piscando em frente à escola.',
          -23.5598, -46.6521, 'Rua Augusta, 900', 3, StatusOcorrencia.resolvida, 4),
    ];
    _demoCarregada = true;
  }
}
