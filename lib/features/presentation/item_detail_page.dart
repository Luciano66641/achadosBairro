import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';

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

class UserCommentTile extends StatelessWidget {
  final ItemComment c;
  const UserCommentTile({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(c.userId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snap) {
        final data = snap.data?.data() ?? const {};

        final name = (data['name'] ?? data['displayName'] ?? 'Usuário') as String;
        final photoBase64 = data['photoBase64'] as String?;

        ImageProvider? avatar;
        if (photoBase64 != null && photoBase64.isNotEmpty) {
          try {
            final b64 = photoBase64.contains(',')
                ? photoBase64.split(',').last
                : photoBase64;
            avatar = MemoryImage(base64Decode(b64));
          } catch (_) {
            avatar = null;
          }
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar,
            child: avatar == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          // seu modelo usa "value" como texto do comentário
          subtitle: Text(c.value),
        );
      },
    );
  }
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  Item? _item;

  // --- Comentários ---
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
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
      if (!mounted) return;
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

  String _fmtDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para comentar.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final repo = context.read<ItemRepository>();
      await repo.addComment(
        itemId: widget.args.id,
        comment: ItemComment(
          userId: uid,
          createdAt: DateTime.now(),
          value: text,
        ),
      );
      _commentCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar comentário: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  Widget _buildComments() {
    final repo = context.read<ItemRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Comentários', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        // Lista reativa
        StreamBuilder<List<ItemComment>>(
          stream: repo.watchComments(widget.args.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            final comments = snap.data ?? const <ItemComment>[];
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Seja o primeiro a comentar.'),
              );
            }
            return ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: comments.length,
  itemBuilder: (context, index) {
    final c = comments[index]; // já é ItemComment
    return UserCommentTile(c: c);
  },
);

          },
        ),

        const SizedBox(height: 12),

        // Caixa de envio
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Escreva um comentário...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 5,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _sendComment,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              tooltip: 'Enviar',
            ),
          ],
        ),
      ],
    );
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

                  _buildComments(),
                ],
              ),
            ),
    );
  }
}
