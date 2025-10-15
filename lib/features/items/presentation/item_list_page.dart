import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_router.dart';
import 'item_detail_page.dart';
import 'item_list_viewmodel.dart';

class ItemListPage extends StatelessWidget {
  const ItemListPage({super.key});

  String _fmtDistance(double? m) {
    if (m == null) return '—';
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m/1000).toStringAsFixed(1)} km';
    }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Achados do Bairro')),
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
            if (vm.loading) return const Center(child: CircularProgressIndicator());
            if (vm.error != null) return Center(child: Text(vm.error!));
            if (vm.items.isEmpty) return const Center(child: Text('Sem itens por perto.'));

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final it = vm.items[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.detailRoute,
                      arguments: ItemDetailArgs(id: it.item.id),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100, height: 100,
                          child: it.item.photoPath != null
                              ? Image.file(File(it.item.photoPath!), fit: BoxFit.cover)
                              : const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.photo, size: 40)),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(it.item.title),
                            subtitle: Text(it.item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: Text(_fmtDistance(it.distanceMeters),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
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
