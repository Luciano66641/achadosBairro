import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neighborhood_finds/features/data/auth_repository.dart';
import 'package:neighborhood_finds/features/auth/app_user.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ProfileEditViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  ProfileEditViewModel(this._repo);

  AppUser? user;
  String? error;
  bool saving = false;

  Uint8List? previewBytes;
  String? _photoBase64; 

  Future<void> load() async {
    user = await _repo.currentUser();
    notifyListeners();
  }

  Future<void> pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      previewBytes = bytes;

      final isPng = file.name.toLowerCase().endsWith('.png');
      final mime = isPng ? 'image/png' : 'image/jpeg';
      _photoBase64 = 'data:$mime;base64,${base64Encode(bytes)}';

      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> saveProfile({String? name, String? phone}) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final updated = await _repo.updateProfile(
        name: name,
        phone: phone,
        photoBase64: _photoBase64,
      );
      user = updated;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<String?> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      await _repo.updateEmailWithPassword(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString(); // devolve msg de erro para UI
    }
  }
}
