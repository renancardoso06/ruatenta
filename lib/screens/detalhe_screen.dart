import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ocorrencia.dart';
import '../state/ocorrencias_controller.dart';
import '../widgets/chips.dart';

/// Detalhe de uma ocorrência: dados, foto, linha do tempo, apoio da
/// comunidade e (modo demonstração) simulação da resposta do órgão.
class DetalheScreen extends StatelessWidget {
  const DetalheScreen({super.key, required this.ocorrenciaId});

  final String ocorrenciaId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OcorrenciasController>();
    final o = controller.porId(ocorrenciaId);
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ocorrência')),
        body: const Center(child: Text('Ocorrência não encontrada.')),
      );
    }
    final cat = o.categoria;
    final atrasada = controller.estaAtrasada(o);
    final jaApoiou = controller.jaApoiou(o);
    final ehAutor = o.autorId == controller.deviceId;

    return Scaffold(
      appBar: AppBar(title: Text(o.protocolo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cat.cor.withValues(alpha: 0.15),
                child: Icon(cat.icone, color: cat.cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat.nome,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: o.status),
              PrioridadeChip(prioridade: o.prioridade),
            ],
          ),
          if (atrasada) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFFC62828)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fora do prazo: o atendimento de ${cat.nome.toLowerCase()} '
                      'deveria ocorrer em até ${cat.prazoDias} dias.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(o.descricao),
          const SizedBox(height: 8),
          if (o.endereco != null)
            Text('Local: ${o.endereco}',
                style: Theme.of(context).textTheme.bodySmall),
          Text('Órgão responsável: ${cat.orgao}',
              style: Theme.of(context).textTheme.bodySmall),
          Text('Registrada em ${formatarData(o.criadoEm)}',
              style: Theme.of(context).textTheme.bodySmall),
          if (o.fotoPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(o.fotoPath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 60,
                  child: Center(child: Text('Foto indisponível')),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.groups_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${o.qtdApoios} vizinho(s) apoiam esta ocorrência. '
                      'Com ${OcorrenciasController.apoiosParaMedia} apoios a '
                      'prioridade sobe para média e com '
                      '${OcorrenciasController.apoiosParaAlta} para alta.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: (jaApoiou || ehAutor)
                  ? null
                  : () async {
                      final ok = await controller.apoiar(o.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Obrigado! Seu apoio foi registrado.'
                              : 'Você já apoiou esta ocorrência.'),
                        ),
                      );
                    },
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: Text(ehAutor
                  ? 'Você registrou esta ocorrência'
                  : jaApoiou
                      ? 'Você já apoiou'
                      : 'Apoiar esta ocorrência'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Andamento', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < o.historico.length; i++)
            _EtapaTimeline(
              evento: o.historico[i],
              ultima: i == o.historico.length - 1,
            ),
          if (o.status.proximo != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => controller.avancarStatus(
                o.id,
                observacao: 'Atualização simulada pelo modo demonstração',
              ),
              icon: const Icon(Icons.science_outlined),
              label: Text(
                'Modo demonstração: avançar para "${o.status.proximo!.rotulo}"',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Em produção, quem muda o status é o órgão responsável. '
              'Este botão simula essa resposta para a apresentação.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _EtapaTimeline extends StatelessWidget {
  const _EtapaTimeline({required this.evento, required this.ultima});

  final EventoHistorico evento;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final cor = corDoStatus(evento.statusNovo);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(iconeDoStatus(evento.statusNovo), color: cor, size: 22),
                if (!ultima)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.statusNovo.rotulo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(evento.observacao),
                  Text(
                    formatarData(evento.data),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
