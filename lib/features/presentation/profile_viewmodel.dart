import 'package:flutter/foundation.dart';
import 'package:neighborhood_finds/features/data/auth_repository.dart';
import 'package:neighborhood_finds/features/auth/app_user.dart';
import 'dart:async';

class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  ProfileViewModel(this._repo) {
    _sub = _repo.profileStream().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  AppUser? user;
  String? error;
  bool sending = false;
  late final StreamSubscription _sub;

  Future<bool> sendResetEmail() async {
    final email = user?.email;
    if (email == null || email.isEmpty) return false;
    sending = true;
    error = null;
    notifyListeners();
    try {
      await _repo.sendPasswordReset(email);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
