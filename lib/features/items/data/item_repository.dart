import 'package:uuid/uuid.dart';
import '../domain/item.dart';

abstract class ItemRepository {
  Future<List<Item>> list();
  Future<Item> add(Item item);
  Future<Item> getById(String id);
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
        ? Item(
            id: _uuid.v4(),
            title: item.title,
            description: item.description,
            lat: item.lat,
            lng: item.lng,
            photoPath: item.photoPath,
            createdAt: DateTime.now(),
          )
        : item;
    _items.add(toSave);
    return toSave;
  }

  @override
  Future<Item> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _items.firstWhere((e) => e.id == id);
  }
}
