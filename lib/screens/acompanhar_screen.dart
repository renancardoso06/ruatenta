import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ocorrencia.dart';
import '../state/ocorrencias_controller.dart';
import '../widgets/ocorrencia_tile.dart';
import 'detalhe_screen.dart';

class AcompanharScreen extends StatefulWidget {
  const AcompanharScreen({super.key});

  @override
  State<AcompanharScreen> createState() => _AcompanharScreenState();
}

class _AcompanharScreenState extends State<AcompanharScreen> {
  final _buscaCtrl = TextEditingController();

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _buscar(OcorrenciasController controller) {
    final achada = controller.buscarPorProtocolo(_buscaCtrl.text);
    if (achada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Protocolo não encontrado.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalheScreen(ocorrenciaId: achada.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OcorrenciasController>();
    if (controller.carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _buscaCtrl,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(controller),
              decoration: InputDecoration(
                labelText: 'Buscar pelo protocolo',
                hintText: 'RUA-2026-000001',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search),
                  onPressed: () => _buscar(controller),
                ),
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Minhas'),
              Tab(text: 'Da comunidade'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _Lista(
                  ocorrencias: controller.minhas,
                  vazio: 'Nenhuma ocorrência sua.',
                  controller: controller,
                ),
                _Lista(
                  ocorrencias: controller.todas
                      .where((o) => o.autorId != controller.deviceId)
                      .toList(),
                  vazio: 'Nenhuma ocorrência da comunidade.',
                  controller: controller,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.ocorrencias,
    required this.vazio,
    required this.controller,
  });

  final List<Ocorrencia> ocorrencias;
  final String vazio;
  final OcorrenciasController controller;

  @override
  Widget build(BuildContext context) {
    if (ocorrencias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vazio, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: ocorrencias.length,
      itemBuilder: (context, i) {
        final o = ocorrencias[i];
        return OcorrenciaTile(
          ocorrencia: o,
          atrasada: controller.estaAtrasada(o),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetalheScreen(ocorrenciaId: o.id),
            ),
          ),
        );
      },
    );
  }
}
