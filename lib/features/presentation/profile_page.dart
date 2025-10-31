import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_viewmodel.dart';
import '../../app_router.dart';
import 'dart:typed_data';
import 'dart:convert';

Uint8List? decodeB64(String? v) {
  if (v == null || v.isEmpty) return null;
  final raw = v.contains(',') ? v.split(',').last : v;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    final u = vm.user;

    final mem = decodeB64(u?.photoBase64);
    Widget avatar() {
      if (mem != null) {
        return CircleAvatar(radius: 24, backgroundImage: MemoryImage(mem));
      }
      return const CircleAvatar(radius: 24, child: Icon(Icons.person));
    }

    final bytes = decodeB64(u?.photoBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final changed = await Navigator.pushNamed(
                context,
                AppRouter.profileEdit,
              );
              if (changed == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil atualizado.')),
                );
              }
            },
          ),
        ],
      ),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: (bytes != null)
                        ? MemoryImage(bytes)
                        : null,
                    child: (bytes == null) ? const Icon(Icons.person) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    u.name.isEmpty ? 'Sem nome' : u.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('E-mail'),
                    subtitle: Text(u.email),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Telefone'),
                    subtitle: Text(u.phone ?? '—'),
                  ),
                ),
                const SizedBox(height: 16),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                FilledButton.icon(
                  icon: vm.sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset),
                  label: const Text('Alterar senha (e-mail de redefinição)'),
                  onPressed: vm.sending
                      ? null
                      : () async {
                          final ok = await vm.sendResetEmail();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'E-mail de redefinição enviado para ${u.email}.'
                                    : 'Não foi possível enviar o e-mail.',
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
    );
  }
}
