import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neighborhood_finds/features/data/auth_repository.dart';
import 'package:neighborhood_finds/features/auth/app_user.dart';

class ProfileEditViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  ProfileEditViewModel(this._repo);

  AppUser? user;
  String? error;
  bool saving = false;

  String? localPhotoPath; // foto tirada com a câmera

  Future<void> load() async {
    user = await _repo.currentUser();
    notifyListeners();
  }

  Future<void> takePhoto() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1080);
      if (img != null) {
        localPhotoPath = img.path;
        notifyListeners();
      }
    } catch (e) {
      error = 'Falha ao abrir câmera';
      notifyListeners();
    }
  }

  Future<bool> saveProfile({String? name, String? phone}) async {
    saving = true; error = null; notifyListeners();
    try {
      final updated = await _repo.updateProfile(
        name: name,
        phone: phone,
        //localPhotoPath: localPhotoPath, // comentado pra tratamento futuro
      );
      user = updated;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      saving = false; notifyListeners();
    }
  }

  Future<String?> changeEmail({required String newEmail, required String currentPassword}) async {
    try {
      await _repo.updateEmailWithPassword(newEmail: newEmail, currentPassword: currentPassword);
      await load();
      return null; // ok
    } catch (e) {
      return e.toString(); // devolve msg de erro para UI
    }
  }
}
