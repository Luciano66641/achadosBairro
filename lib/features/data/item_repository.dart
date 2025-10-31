import 'package:uuid/uuid.dart';
import '../domain/item.dart';

abstract class ItemRepository {
  Future<List<Item>> list();
  Future<Item> add(Item item);
  Future<Item> getById(String id);

  Future<void> update(Item item);
  Future<void> delete(String id);
}

class InMemoryItemRepository implements ItemRepository {
  final _uuid = const Uuid();
  final List<Item> _items = [];

  @override
  Future<List<Item>> list() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_items);
  }

  @override
  Future<Item> add(Item item) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final toSave = item.id.isEmpty
        ? item.copyWith(id: _uuid.v4(), createdAt: DateTime.now())
        : item;
    _items.add(toSave);
    return toSave;
  }

  @override
  Future<Item> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _items.firstWhere((e) => e.id == id);
  }

  @override
  Future<void> update(Item item) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      _items[i] = item;
    } else {
      throw Exception('Item não encontrado para atualizar');
    }
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.removeWhere((e) => e.id == id);
  }
}
