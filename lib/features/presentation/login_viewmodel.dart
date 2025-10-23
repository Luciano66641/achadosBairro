import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../auth/app_user.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  LoginViewModel(this._repo);

  bool _loading = false;
  String? _error;
  AppUser? _user;

  bool get loading => _loading;
  String? get error => _error;
  AppUser? get user => _user;

  Future<bool> login(String email, String password) async {
    _set(true);
    try {
      _user = await _repo.signIn(email: email, password: password);
      return true;
    } catch (e) {
      _error = _msg(e);
      return false;
    } finally {
      _set(false);
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
  void _set(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.signOut();
  }
}
