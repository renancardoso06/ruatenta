import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/ocorrencia.dart';
import '../services/localizacao_service.dart';
import '../state/ocorrencias_controller.dart';

class RegistrarScreen extends StatefulWidget {
  const RegistrarScreen({super.key, required this.onRegistrado});

  final VoidCallback onRegistrado;

  @override
  State<RegistrarScreen> createState() => _RegistrarScreenState();
}

class _RegistrarScreenState extends State<RegistrarScreen> {
  static const _centroPadrao = LatLng(-23.5643, -46.6527);

  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _mapController = MapController();
  final _localizacao = LocalizacaoService();
  final _picker = ImagePicker();

  int _categoriaId = Categoria.todas.first.id;
  LatLng _local = _centroPadrao;
  String? _fotoPath;
  bool _buscandoGps = false;
  bool _enviando = false;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _enderecoCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _usarMinhaLocalizacao() async {
    setState(() => _buscandoGps = true);
    final pos = await _localizacao.posicaoAtual();
    if (!mounted) return;
    setState(() => _buscandoGps = false);
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Localização indisponível. Marque no mapa.',
          ),
        ),
      );
      return;
    }
    setState(() => _local = pos);
    _mapController.move(pos, 17);
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    try {
      final arquivo = await _picker.pickImage(
        source: origem,
        maxWidth: 1024,
        imageQuality: 70,
      );
      if (arquivo != null && mounted) {
        setState(() => _fotoPath = arquivo.path);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a foto.')),
      );
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<OcorrenciasController>();
    setState(() => _enviando = true);
    try {
      final nova = await controller.registrar(
        categoriaId: _categoriaId,
        descricao: _descricaoCtrl.text,
        latitude: _local.latitude,
        longitude: _local.longitude,
        endereco: _enderecoCtrl.text,
        fotoPath: _fotoPath,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ocorrência registrada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Protocolo para acompanhar:'),
              const SizedBox(height: 8),
              SelectableText(
                nova.protocolo,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Órgão responsável: ${nova.categoria.orgao}'),
              Text('Prazo de atendimento: ${nova.categoria.prazoDias} dias'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      _descricaoCtrl.clear();
      _enderecoCtrl.clear();
      setState(() => _fotoPath = null);
      widget.onRegistrado();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.toString())),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Registrar um problema',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _categoriaId,
            decoration: const InputDecoration(
              labelText: 'Tipo de problema',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in Categoria.todas)
                DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(c.icone, color: c.cor, size: 20),
                      const SizedBox(width: 8),
                      Text(c.nome),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _categoriaId = v ?? _categoriaId),
          ),
          const SizedBox(height: 4),
          Text(
            'Órgão responsável: ${Categoria.porId(_categoriaId).orgao} · '
            'prazo de ${Categoria.porId(_categoriaId).prazoDias} dias',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descricaoCtrl,
            maxLength: 500,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Descreva o problema',
              hintText: 'Ex.: buraco grande em frente ao número 200',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().length < 5)
                ? 'Informe ao menos 5 caracteres.'
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _enderecoCtrl,
            decoration: const InputDecoration(
              labelText: 'Endereço ou referência (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Local', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _local,
                  initialZoom: 16,
                  onTap: (_, ponto) => setState(() => _local = ponto),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.fiap.ruatenta',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _local,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFC62828),
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque no mapa para marcar o local '
            '(${_local.latitude.toStringAsFixed(5)}, '
            '${_local.longitude.toStringAsFixed(5)})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _buscandoGps ? null : _usarMinhaLocalizacao,
            icon: _buscandoGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Usar minha localização'),
          ),
          const SizedBox(height: 16),
          Text('Foto (opcional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_fotoPath != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_fotoPath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Carrega uma versão menor da foto para poupar memória.
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 180,
                      child: Center(child: Text('Foto indisponível')),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Remover foto',
                  onPressed: () => setState(() => _fotoPath = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Câmera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.send),
              label: Text(_enviando ? 'Enviando...' : 'Registrar ocorrência'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
