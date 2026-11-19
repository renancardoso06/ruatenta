import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/ocorrencia.dart';
import '../state/ocorrencias_controller.dart';
import 'detalhe_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  static const _centroPadrao = LatLng(-23.5643, -46.6527); // Av. Paulista, SP
  static const _maxMarcadores = 200;

  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OcorrenciasController>();
    if (controller.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    // Evita desenhar pinos demais de uma vez.
    final visiveis = controller.filtradas.take(_maxMarcadores).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _centroPadrao,
            initialZoom: 15,
            minZoom: 4,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.fiap.ruatenta',
            ),
            MarkerLayer(
              markers: [
                for (final o in visiveis)
                  Marker(
                    point: LatLng(o.latitude, o.longitude),
                    width: 48,
                    height: 48,
                    child: _Pino(
                      ocorrencia: o,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetalheScreen(ocorrenciaId: o.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: _Filtros(controller: controller),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('${visiveis.length} ocorrência(s) no mapa'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pino extends StatelessWidget {
  const _Pino({required this.ocorrencia, required this.onTap});

  final Ocorrencia ocorrencia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = ocorrencia.categoria;
    final resolvida = ocorrencia.status == StatusOcorrencia.resolvida;
    return Semantics(
      button: true,
      label: '${cat.nome}, ${ocorrencia.status.rotulo}. Ver detalhes.',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: resolvida ? Colors.grey.shade500 : cat.cor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
          ),
          child: Icon(
            resolvida ? Icons.check : cat.icone,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.controller});

  final OcorrenciasController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('Todas'),
              selected: controller.filtroCategoriaId == null,
              onSelected: (_) => controller.definirFiltroCategoria(null),
            ),
          ),
          for (final c in Categoria.todas)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: Icon(c.icone, size: 18, color: c.cor),
                label: Text(c.nome),
                selected: controller.filtroCategoriaId == c.id,
                onSelected: (sel) =>
                    controller.definirFiltroCategoria(sel ? c.id : null),
              ),
            ),
        ],
      ),
    );
  }
}
