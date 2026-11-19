import 'package:ruatenta/data/ocorrencia_repository.dart';
import 'package:ruatenta/models/ocorrencia.dart';
import 'package:ruatenta/state/ocorrencias_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testa as regras de negócio do app, que espelham o pacote PKG_RUATENTA.
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

  test('registra com protocolo, status inicial e historico', () async {
    final o = await nova();
    expect(o.protocolo, 'RUA-2026-000001');
    expect(o.status, StatusOcorrencia.aberta);
    expect(o.prioridade, Prioridade.baixa);
    expect(o.historico.length, 1);
    final o2 = await nova(categoria: 5);
    expect(o2.protocolo, 'RUA-2026-000002');
    expect(o2.prioridade, Prioridade.alta); // prioridade padrão da categoria
  });

  test('recusa descricao curta', () async {
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

  test('status so avanca e preenche resolvidoEm', () async {
    final o = await nova();
    expect(await c.avancarStatus(o.id), isTrue);
    expect(await c.avancarStatus(o.id), isTrue);
    agora = agora.add(const Duration(days: 2));
    expect(await c.avancarStatus(o.id), isTrue);
    final fim = c.porId(o.id)!;
    expect(fim.status, StatusOcorrencia.resolvida);
    expect(fim.resolvidoEm, isNotNull);
    expect(fim.historico.length, 4);
    expect(await c.avancarStatus(o.id), isFalse); // já resolvida
  });

  test('prioridade sobe com apoios e apoio duplicado e recusado', () async {
    final o = await nova(); // categoria 1: prioridade inicial BAIXA
    for (var i = 1; i <= 4; i++) {
      expect(await c.apoiar(o.id, apoiadorId: 'v$i'), isTrue);
    }
    expect(c.porId(o.id)!.prioridade, Prioridade.baixa); // 4 apoios
    expect(await c.apoiar(o.id, apoiadorId: 'v5'), isTrue);
    expect(c.porId(o.id)!.prioridade, Prioridade.media); // 5 apoios
    expect(await c.apoiar(o.id, apoiadorId: 'v5'), isFalse); // duplicado
    for (var i = 6; i <= 10; i++) {
      await c.apoiar(o.id, apoiadorId: 'v$i');
    }
    expect(c.porId(o.id)!.qtdApoios, 10);
    expect(c.porId(o.id)!.prioridade, Prioridade.alta); // 10 apoios
  });

  test('prazo vencido marca atrasada', () async {
    final o = await nova(categoria: 5); // prazo de 3 dias
    expect(c.estaAtrasada(o), isFalse);
    agora = agora.add(const Duration(days: 4));
    expect(c.estaAtrasada(o), isTrue);
  });

  test('indicadores e tempo medio de resolucao', () async {
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

  test('busca por protocolo ignora caixa e espacos', () async {
    final o = await nova();
    expect(c.buscarPorProtocolo(' rua-2026-000001 ')?.id, o.id);
    expect(c.buscarPorProtocolo('RUA-2026-999999'), isNull);
  });
}
