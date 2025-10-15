import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';

class ItemDetailArgs { final String id; ItemDetailArgs({required this.id}); }

class ItemDetailPage extends StatefulWidget {
  final ItemDetailArgs args;
  const ItemDetailPage({super.key, required this.args});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  Item? _item;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final repo = context.read<ItemRepository>();
    final it = await repo.getById(widget.args.id);
    if (!mounted) return;
    setState(() => _item = it);
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = _item;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Item')),
      body: it == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (it.photoPath != null)
                    Image.file(File(it.photoPath!), height: 220, width: double.infinity, fit: BoxFit.cover)
                  else
                    Container(height: 220, color: const Color(0xFFE0E0E0), child: const Icon(Icons.photo, size: 48)),
                  const SizedBox(height: 12),
                  Text(it.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(it.description),
                  const SizedBox(height: 12),
                  Text('Coordenadas: ${it.lat.toStringAsFixed(5)}, ${it.lng.toStringAsFixed(5)}'),
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
