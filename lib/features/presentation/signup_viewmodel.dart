// lib/features/auth/presentation/signup_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../auth/app_user.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  SignupViewModel(this._repo);

  bool _loading = false;
  String? _error;
  AppUser? _user;

  bool get loading => _loading;
  String? get error => _error;
  AppUser? get user => _user;

  Future<bool> signup(String name, String email, String password, String confirm) async {
    _set(true);
    try {
      if (password != confirm) {
        _error = 'As senhas não coincidem';
        return false;
      }
      _user = await _repo.signUp(name: name, email: email, password: password);
      return true;
    } catch (e) {
      _error = _msg(e);
      return false;
    } finally {
      _set(false);
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
  void _set(bool v) { _loading = v; notifyListeners(); }
}
