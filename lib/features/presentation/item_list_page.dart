import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_router.dart';
import 'item_detail_page.dart';
import 'item_list_viewmodel.dart';

import 'package:neighborhood_finds/features/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neighborhood_finds/features/data/item_repository.dart';


class ItemListPage extends StatelessWidget {
  const ItemListPage({super.key});

  String _fmtDistance(double? m) {
    if (m == null) return '—';
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achados do Bairro'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 🔐 chama o signOut do AuthRepository
              await context.read<AuthRepository>().signOut();
              // O AuthGate percebe user=null e mostra a LoginPage automaticamente.
              // (Opcional) feedback visual:
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sessão encerrada.')),
                );
              }
            },
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
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: it.item.photoPath != null
                          ? Image.file(
                              File(it.item.photoPath!),
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.photo),
                    ),
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
