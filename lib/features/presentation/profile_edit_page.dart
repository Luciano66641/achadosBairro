import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_edit_viewmodel.dart';
import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeB64(String? value) {
  if (value == null || value.isEmpty) return null;
  final raw = value.contains(',') ? value.split(',').last : value;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileEditViewModel>();
    vm.load().then((_) {
      final u = vm.user;
      if (!mounted || u == null) return;
      _name.text = u.name;
      _phone.text = u.phone ?? '';
      _email.text = u.email;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileEditViewModel>();
    final u = vm.user;
    final bytes = vm.previewBytes ?? decodeB64(u?.photoBase64);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: (u == null)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundImage: (bytes != null)
                            ? MemoryImage(bytes)
                            : null,
                        child: (bytes == null)
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: vm.saving
                            ? null
                            : vm.pickPhoto, // <<<<<< abre câmera/galeria
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      if (vm.error != null)
                        Text(
                          vm.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: vm.saving
                              ? null
                              : () async {
                                  if (!_form.currentState!.validate()) return;
                                  // 1) salva nome/telefone/foto
                                  final ok = await vm.saveProfile(
                                    name: _name.text.trim(),
                                    phone: _phone.text.trim().isEmpty
                                        ? null
                                        : _phone.text.trim(),
                                  );
                                  if (!mounted) return;
                                  // 2) se o email mudou, pede senha atual e troca
                                  if (ok && _email.text.trim() != u.email) {
                                    final pwd = await _askPassword(context);
                                    if (pwd != null && pwd.isNotEmpty) {
                                      final err = await vm.changeEmail(
                                        newEmail: _email.text.trim(),
                                        currentPassword: pwd,
                                      );
                                      if (err != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Não foi possível alterar o e-mail: $err',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }
                                  if (mounted) Navigator.pop(context);
                                },
                          child: vm.saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<String?> _askPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar senha'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha atual'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
