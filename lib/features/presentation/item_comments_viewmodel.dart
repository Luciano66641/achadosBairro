import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';
import '../data/auth_repository.dart';

class ItemCommentsViewModel extends ChangeNotifier {
  final ItemRepository _items;
  final AuthRepository _auth;
  final String itemId;

  ItemCommentsViewModel(this._items, this._auth, this.itemId);

  List<ItemComment> _comments = [];
  List<ItemComment> get comments => _comments;

  bool _sending = false;
  bool get sending => _sending;

  String? _error;
  String? get error => _error;

  StreamSubscription<List<ItemComment>>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _items.watchComments(itemId).listen((list) {
      _comments = list;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    final uid = _auth.userId; // ajuste para sua API
    
    if (uid == null || uid.isEmpty) {
      _error = 'Usuário não autenticado.';
      notifyListeners();
      return;
    }
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      await _items.addComment(
        itemId: itemId,
        comment: ItemComment(
          userId: uid,
          createdAt: DateTime.now(),
          value: text.trim(),
        ),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
