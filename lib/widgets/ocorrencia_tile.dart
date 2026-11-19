import 'package:flutter/material.dart';

import '../models/ocorrencia.dart';
import 'chips.dart';

class OcorrenciaTile extends StatelessWidget {
  const OcorrenciaTile({
    super.key,
    required this.ocorrencia,
    required this.atrasada,
    required this.onTap,
  });

  final Ocorrencia ocorrencia;
  final bool atrasada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = ocorrencia.categoria;
    return Semantics(
      button: true,
      label: '${cat.nome}, protocolo ${ocorrencia.protocolo}, '
          'status ${ocorrencia.status.rotulo}. Toque para ver detalhes.',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cat.cor.withValues(alpha: 0.15),
                  child: Icon(cat.icone, color: cat.cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ocorrencia.protocolo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ocorrencia.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(status: ocorrencia.status),
                          if (atrasada)
                            const Text(
                              'Fora do prazo',
                              style: TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thumb_up_alt_outlined, size: 16),
                              const SizedBox(width: 4),
                              Text('${ocorrencia.qtdApoios}'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
