import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AppUser?> authState();
  Future<AppUser?> currentUser();
}

class FirebaseAuthRepository implements AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Stream<AppUser?> authState() {
    return _auth.authStateChanges().asyncMap((u) async {
      if (u == null) return null;
      final doc = await _users.doc(u.uid).get();
      if (doc.exists) return AppUser.fromMap(u.uid, doc.data()!);
      // fallback mínimo
      return AppUser(
        uid: u.uid,
        email: u.email ?? '',
        name: u.displayName ?? '',
      );
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _users.doc(u.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(u.uid, doc.data()!);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(name);

    // cria/atualiza perfil no Firestore
    final appUser = AppUser(uid: uid, email: email, name: name);
    await _users.doc(uid).set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _users.doc(uid).get();
    if (doc.exists) return AppUser.fromMap(uid, doc.data()!);

    // se não existir perfil, cria mínimo
    final appUser = AppUser(
      uid: uid,
      email: cred.user!.email ?? email,
      name: cred.user!.displayName ?? '',
    );
    await _users.doc(uid).set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
