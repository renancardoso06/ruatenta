import 'package:flutter/material.dart';

import '../models/ocorrencia.dart';

Color corDoStatus(StatusOcorrencia s) {
  switch (s) {
    case StatusOcorrencia.aberta:
      return const Color(0xFFC62828);
    case StatusOcorrencia.emAnalise:
      return const Color(0xFFEF6C00);
    case StatusOcorrencia.emAndamento:
      return const Color(0xFF1565C0);
    case StatusOcorrencia.resolvida:
      return const Color(0xFF2E7D32);
  }
}

IconData iconeDoStatus(StatusOcorrencia s) {
  switch (s) {
    case StatusOcorrencia.aberta:
      return Icons.report_problem_outlined;
    case StatusOcorrencia.emAnalise:
      return Icons.manage_search;
    case StatusOcorrencia.emAndamento:
      return Icons.engineering_outlined;
    case StatusOcorrencia.resolvida:
      return Icons.check_circle_outline;
  }
}

/// O ícone ajuda a distinguir os status sem depender só das cores.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final StatusOcorrencia status;

  @override
  Widget build(BuildContext context) {
    final cor = corDoStatus(status);
    return Semantics(
      label: 'Status: ${status.rotulo}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconeDoStatus(status), size: 16, color: cor),
            const SizedBox(width: 4),
            Text(
              status.rotulo,
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrioridadeChip extends StatelessWidget {
  const PrioridadeChip({super.key, required this.prioridade});

  final Prioridade prioridade;

  @override
  Widget build(BuildContext context) {
    final cor = switch (prioridade) {
      Prioridade.alta => const Color(0xFFC62828),
      Prioridade.media => const Color(0xFFEF6C00),
      Prioridade.baixa => const Color(0xFF546E7A),
    };
    return Semantics(
      label: 'Prioridade ${prioridade.rotulo}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 16, color: cor),
          const SizedBox(width: 2),
          Text(
            'Prioridade ${prioridade.rotulo}',
            style: TextStyle(color: cor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
