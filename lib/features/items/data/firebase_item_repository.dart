import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/item.dart';
import 'item_repository.dart';

class FirebaseItemRepository implements ItemRepository {
  final _fire = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _fire.collection('items');

  @override
  Future<List<Item>> list() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Item.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<Item> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) throw Exception('Item não encontrado');
    return Item.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<Item> add(Item item) async {
    // gera o doc no Firestore (id automático)
    final data = item.toMap();
    final ref = await _col.add(data);
    final saved = await ref.get();
    return Item.fromMap(saved.id, saved.data()!);
  }
}
