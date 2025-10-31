import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';
import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeB64(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  // aceita "data:*;base64,XXXXX" ou só "XXXXX"
  final raw = trimmed.contains(',') ? trimmed.split(',').last : trimmed;

  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

class ItemDetailArgs {
  final String id;
  ItemDetailArgs({required this.id});
}

class ItemDetailPage extends StatefulWidget {
  final ItemDetailArgs args;
  const ItemDetailPage({super.key, required this.args});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  Item? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<ItemRepository>();
    final it = await repo.getById(widget.args.id);
    if (!mounted) return;
    setState(() => _item = it);
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Maps')),
      );
    }
  }

  Widget _buildPhoto(Item it) {
    final bytes = decodeB64(it.imageBase64);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = _item;
    final mem = decodeB64(it?.imageBase64);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Item')),
      body: it == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhoto(it),
                  const SizedBox(height: 12),
                  Text(
                    it.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(it.description),
                  const SizedBox(height: 12),
                  Text(
                    'Coordenadas: ${it.lat.toStringAsFixed(5)}, ${it.lng.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openMaps(it.lat, it.lng),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("Abrir no Maps"),
                  ),
                ],
              ),
            ),
    );
  }
}
