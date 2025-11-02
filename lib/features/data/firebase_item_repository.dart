import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/item.dart';
import 'item_repository.dart';

class FirebaseItemRepository implements ItemRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseItemRepository(this._db);

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('items');

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
    final data = item.toMap()
      ..putIfAbsent('createdAt', () => DateTime.now().toUtc().millisecondsSinceEpoch)
      ..['userId'] = _uid;

    final ref = await _col.add(data);
    final saved = await ref.get();
    return Item.fromMap(saved.id, saved.data()!);
  }

  @override
  Future<void> update(Item item) async {
    final data = <String, dynamic>{
      'title': item.title,
      'description': item.description,
      'lat': item.lat,
      'lng': item.lng,
      if (item.imageBase64 != null) 'imageBase64': item.imageBase64,
    };
    await _col.doc(item.id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<void> addComment({
    required String itemId,
    required ItemComment comment,
  }) async {
    final ref = _col.doc(itemId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Item não encontrado');

      final data = snap.data() as Map<String, dynamic>;
      final comments = (data['comments'] as List?)?.toList() ?? <dynamic>[];
      comments.add(comment.toMap());
      tx.update(ref, {'comments': comments});
    });
  }

  @override
  Stream<List<ItemComment>> watchComments(String itemId) {
    final ref = _col.doc(itemId);
    return ref.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <ItemComment>[];
      final raw = (data['comments'] as List?) ?? const [];
      final list = raw
          .whereType<Map>()
          .map((m) => ItemComment.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
