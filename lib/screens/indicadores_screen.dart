import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ocorrencias_controller.dart';

/// Funcionalidade 4: painel de indicadores (transparência para o cidadão).
class IndicadoresScreen extends StatelessWidget {
  const IndicadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OcorrenciasController>();
    if (controller.carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final indicadores = controller.indicadores();
    final tempoMedio = controller.tempoMedioResolucaoDias();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Indicadores do bairro',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _Cartao(
              titulo: 'Ocorrências',
              valor: '${controller.todas.length}',
              icone: Icons.list_alt,
            ),
            _Cartao(
              titulo: 'Resolvidas',
              valor: '${controller.percentualResolvidas.toStringAsFixed(0)}%',
              icone: Icons.check_circle_outline,
            ),
            _Cartao(
              titulo: 'Tempo médio de resolução',
              valor: '${tempoMedio.toStringAsFixed(1)} dias',
              icone: Icons.timer_outlined,
            ),
            _Cartao(
              titulo: 'Fora do prazo',
              valor: '${controller.totalAtrasadas}',
              icone: Icons.schedule,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Por categoria', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final ind in indicadores)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(ind.categoria.icone, color: ind.categoria.cor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ind.categoria.nome,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text('${ind.total} no total'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: '${ind.percentualResolvidas.toStringAsFixed(0)} '
                        'por cento resolvidas',
                    child: LinearProgressIndicator(
                      value: ind.percentualResolvidas / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${ind.resolvidas} resolvida(s) · '
                    '${ind.percentualResolvidas.toStringAsFixed(0)}% · '
                    '${ind.totalApoios} apoio(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () async {
            await controller.reiniciarDemonstracao();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dados de demonstração recarregados.')),
            );
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Recarregar dados de demonstração'),
        ),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  final String titulo;
  final String valor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$titulo: $valor',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icone, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(valor, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
