import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/item.dart';
import 'item_repository.dart';

class FirebaseItemRepository implements ItemRepository {
  final _fire = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _fire.collection('items');

  String get _uid {
    final u = _auth.currentUser?.uid;
    if (u == null) throw Exception('Usuário não autenticado');
    return u;
  }

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
    final data = item.toMap()..['userId'] = _uid; // garante owner

    final ref = await _col.add(data);
    final saved = await ref.get();
    return Item.fromMap(saved.id, saved.data()!);
  }

  @override
  Future<void> update(Item item) async {
    // só campos editáveis
    await _col.doc(item.id).update({
      'title': item.title,
      'description': item.description,
      'lat': item.lat,
      'lng': item.lng,
      // userId e createdAt NÃO mudam
    });
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
