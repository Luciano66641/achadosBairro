import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_router.dart';
import 'item_detail_page.dart';
import 'item_list_viewmodel.dart';
import 'package:neighborhood_finds/features/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neighborhood_finds/features/data/item_repository.dart';
import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeB64(String? value) {
  if (value == null) return null;
  final raw = value.contains(',') ? value.split(',').last : value;
  try {
    return base64Decode(raw.trim());
  } catch (_) {
    return null;
  }
}

enum _MenuAction { profile, logout }

class ItemListPage extends StatelessWidget {
  const ItemListPage({super.key});

  String _fmtDistance(double? m) {
    if (m == null) return '—';
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildThumb(BuildContext context, b64) {
    final bytes = decodeB64(b64);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achados do Bairro'),
        actions: [
          PopupMenuButton<_MenuAction>(
            tooltip: 'Mais opções',
            onSelected: (value) async {
              switch (value) {
                case _MenuAction.profile:
                  if (context.mounted) {
                    Navigator.pushNamed(context, AppRouter.profile);
                  }
                  break;
                case _MenuAction.logout:
                  await context.read<AuthRepository>().signOut();
                  // AuthGate manda pra tela de Login automaticamente.
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _MenuAction.profile, child: Text('Perfil')),
              PopupMenuItem(value: _MenuAction.logout, child: Text('Sair')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRouter.newItemRoute);
          if (context.mounted) context.read<ItemListViewModel>().refresh();
        },
        label: const Text('Novo Item'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Builder(
          builder: (_) {
            if (vm.loading)
              return const Center(child: CircularProgressIndicator());
            if (vm.error != null) return Center(child: Text(vm.error!));
            if (vm.items.isEmpty)
              return const Center(child: Text('Sem itens por perto.'));

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final it = vm.items[i];
                final isOwner =
                    FirebaseAuth.instance.currentUser?.uid == it.item.userId;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.detailRoute,
                      arguments: ItemDetailArgs(id: it.item.id),
                    ),
                    leading: _buildThumb(context, it.item.imageBase64),
                    title: Text(it.item.title),
                    subtitle: Text(
                      it.item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtDistance(it.distanceMeters),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                // navega para edição reaproveitando a NewItemPage (ver 4.2)
                                await Navigator.pushNamed(
                                  context,
                                  AppRouter.newItemRoute,
                                  arguments: it.item, // passamos o item inteiro
                                );
                                if (context.mounted) vm.refresh();
                              } else if (v == 'delete') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Excluir item?'),
                                    content: const Text(
                                      'Esta ação não poderá ser desfeita.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await context.read<ItemRepository>().delete(
                                    it.item.id,
                                  );
                                  if (context.mounted) vm.refresh();
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
