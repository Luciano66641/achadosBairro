import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'new_item_viewmodel.dart';
import 'package:neighborhood_finds/features/domain/item.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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

class NewItemPage extends StatefulWidget {
  final Item? initial;
  const NewItemPage({super.key, this.initial});

  @override
  State<NewItemPage> createState() => _NewItemPageState();
}

class _NewItemPageState extends State<NewItemPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  XFile? _photo;
  double? _lat, _lng;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    final it = widget.initial;
    if (it != null) {
      _title.text = it.title;
      _desc.text = it.description;
      _lat = it.lat;
      _lng = it.lng;
    } else {
      _getLocation(); // método que pega localização atual
    }
  }

  Widget _buildNewItemPreview() {
    // 1) se usuário acabou de tirar foto, mostra os bytes
    if (_previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _previewBytes!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // 2) se está editando um item existente, mostra a imagemBase64 dele
    if (widget.initial?.imageBase64 != null &&
        widget.initial!.imageBase64!.isNotEmpty) {
      final bytes = decodeB64(widget.initial!.imageBase64);
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // 3) fallback
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, size: 48),
    );
  }

  Future<void> _getLocation() async {
    final pos = await NewItemViewModel.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _lat = pos?.latitude;
      _lng = pos?.longitude;
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera, // ou gallery se quiser
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (file == null) return;

    // Lê os bytes para mostrar preview imediatamente (funciona em emulador e web)
    final bytes = await file.readAsBytes();

    setState(() {
      _photo = file;
      _previewBytes = bytes; // agora temos a imagem na tela antes de salvar
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewItemViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Item')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickPhoto,
                  child: _photo == null
                      ? Container(
                          width: 220,
                          height: 160,
                          color: const Color(0xFFE0F2F1),
                          child: const Icon(Icons.camera_alt, size: 48),
                        )
                      : Image.file(
                          File(_photo!.path),
                          width: 220,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe o título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Lat: ${_lat?.toStringAsFixed(5) ?? "—"}'),
                  ),
                  Expanded(
                    child: Text('Lng: ${_lng?.toStringAsFixed(5) ?? "—"}'),
                  ),
                  IconButton(
                    onPressed: _getLocation,
                    tooltip: 'Atualizar localização',
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: vm.saving
                      ? null
                      : () async {
                          if (_form.currentState!.validate() &&
                              _lat != null &&
                              _lng != null) {
                            String? imageBase64;
                            if (_previewBytes != null) {
                              final b64 = base64Encode(_previewBytes!);
                              final isPng =
                                  (_photo?.name.toLowerCase().endsWith(
                                    '.png',
                                  ) ??
                                  false);
                              final mime = isPng ? 'image/png' : 'image/jpeg';
                              imageBase64 = 'data:$mime;base64,$b64';
                            }

                            if (widget.initial == null) {
                              // criar
                              final ok = await vm.create(
                                title: _title.text.trim(),
                                description: _desc.text.trim(),
                                lat: _lat!,
                                lng: _lng!,
                                imageBase64: imageBase64,
                              );
                              if (ok && mounted) Navigator.pop(context);
                            } else {
                              // editar
                              final ok = await vm.update(
                                item: widget.initial!,
                                title: _title.text.trim(),
                                description: _desc.text.trim(),
                                lat: _lat!,
                                lng: _lng!,
                                imageBase64: imageBase64,
                              );
                              if (ok && mounted) Navigator.pop(context);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Preencha tudo e capture a localização.',
                                ),
                              ),
                            );
                          }
                        },
                  child: vm.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
