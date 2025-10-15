import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'new_item_viewmodel.dart';

class NewItemPage extends StatefulWidget {
  const NewItemPage({super.key});
  @override
  State<NewItemPage> createState() => _NewItemPageState();
}

class _NewItemPageState extends State<NewItemPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc  = TextEditingController();
  XFile? _photo;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final pos = await NewItemViewModel.getCurrentPosition();
    if (!mounted) return;
    setState(() { _lat = pos?.latitude; _lng = pos?.longitude; });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera).catchError((_) => null);
    if (file != null && mounted) setState(() => _photo = file);
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewItemViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Item')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
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
                          width: 220, height: 160,
                          color: const Color(0xFFE0F2F1),
                          child: const Icon(Icons.camera_alt, size: 48))
                      : Image.file(File(_photo!.path), width: 220, height: 160, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.isEmpty) ? 'Informe o título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Lat: ${_lat?.toStringAsFixed(5) ?? "—"}')),
                  Expanded(child: Text('Lng: ${_lng?.toStringAsFixed(5) ?? "—"}')),
                  IconButton(
                    onPressed: _getLocation,
                    tooltip: 'Atualizar localização',
                    icon: const Icon(Icons.my_location),
                  )
                ],
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: vm.saving ? null : () async {
                    if (_form.currentState!.validate() && _lat != null && _lng != null) {
                      final ok = await vm.create(
                        title: _title.text.trim(),
                        description: _desc.text.trim(),
                        lat: _lat!, lng: _lng!,
                        photoPath: _photo?.path,
                      );
                      if (ok && mounted) Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha tudo e capture a localização.')),
                      );
                    }
                  },
                  child: vm.saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
