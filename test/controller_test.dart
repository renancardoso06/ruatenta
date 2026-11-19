import 'package:ruatenta/data/ocorrencia_repository.dart';
import 'package:ruatenta/models/ocorrencia.dart';
import 'package:ruatenta/state/ocorrencias_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime agora;
  late OcorrenciasController c;

  setUp(() async {
    agora = DateTime(2026, 11, 12, 10);
    c = OcorrenciasController(
      MemoriaOcorrenciaRepository(),
      agora: () => agora,
      carregarDemo: false,
    );
    await c.iniciar();
  });

  Future<Ocorrencia> nova({int categoria = 1}) => c.registrar(
        categoriaId: categoria,
        descricao: 'Buraco grande na rua',
        latitude: -23.56,
        longitude: -46.65,
      );

  test('registra ocorrência com protocolo e status inicial', () async {
    final o = await nova();
    expect(o.protocolo, 'RUA-2026-000001');
    expect(o.status, StatusOcorrencia.aberta);
    expect(o.prioridade, Prioridade.baixa);
    expect(o.historico.length, 1);
    final o2 = await nova(categoria: 5);
    expect(o2.protocolo, 'RUA-2026-000002');
    expect(o2.prioridade, Prioridade.alta);
  });

  test('recusa descrição curta', () async {
    expect(
      () => c.registrar(
        categoriaId: 1,
        descricao: 'ab',
        latitude: 0,
        longitude: 0,
      ),
      throwsArgumentError,
    );
  });

  test('avança status e preenche resolvidoEm', () async {
    final o = await nova();
    expect(await c.avancarStatus(o.id), isTrue);
    expect(await c.avancarStatus(o.id), isTrue);
    agora = agora.add(const Duration(days: 2));
    expect(await c.avancarStatus(o.id), isTrue);
    final fim = c.porId(o.id)!;
    expect(fim.status, StatusOcorrencia.resolvida);
    expect(fim.resolvidoEm, isNotNull);
    expect(fim.historico.length, 4);
    expect(await c.avancarStatus(o.id), isFalse);
  });

  test('atualiza prioridade e recusa apoio duplicado', () async {
    final o = await nova();
    for (var i = 1; i <= 4; i++) {
      expect(await c.apoiar(o.id, apoiadorId: 'v$i'), isTrue);
    }
    expect(c.porId(o.id)!.prioridade, Prioridade.baixa);
    expect(await c.apoiar(o.id, apoiadorId: 'v5'), isTrue);
    expect(c.porId(o.id)!.prioridade, Prioridade.media);
    expect(await c.apoiar(o.id, apoiadorId: 'v5'), isFalse);
    for (var i = 6; i <= 10; i++) {
      await c.apoiar(o.id, apoiadorId: 'v$i');
    }
    expect(c.porId(o.id)!.qtdApoios, 10);
    expect(c.porId(o.id)!.prioridade, Prioridade.alta);
  });

  test('marca ocorrência fora do prazo', () async {
    final o = await nova(categoria: 5);
    expect(c.estaAtrasada(o), isFalse);
    agora = agora.add(const Duration(days: 4));
    expect(c.estaAtrasada(o), isTrue);
  });

  test('calcula indicadores e tempo médio de resolução', () async {
    final a = await nova(categoria: 2);
    await nova(categoria: 2);
    await c.avancarStatus(a.id);
    await c.avancarStatus(a.id);
    agora = agora.add(const Duration(days: 2));
    await c.avancarStatus(a.id);

    expect(c.totalResolvidas, 1);
    expect(c.percentualResolvidas, 50);
    expect(c.tempoMedioResolucaoDias(), closeTo(2, 0.01));

    final ind = c.indicadores();
    expect(ind.length, Categoria.todas.length);
    final iluminacao = ind.firstWhere((i) => i.categoria.id == 2);
    expect(iluminacao.total, 2);
    expect(iluminacao.resolvidas, 1);
    expect(iluminacao.percentualResolvidas, 50);
  });

  test('busca protocolo sem diferenciar caixa e espaços', () async {
    final o = await nova();
    expect(c.buscarPorProtocolo(' rua-2026-000001 ')?.id, o.id);
    expect(c.buscarPorProtocolo('RUA-2026-999999'), isNull);
  });
}
