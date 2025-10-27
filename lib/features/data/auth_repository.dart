import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../auth/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });
  Stream<AppUser?> authState();
  Future<AppUser> updateProfile({
    String? name,
    String? phone,
    String? localPhotoPath,
  });
  Future<void> updateEmailWithPassword({
    required String newEmail,
    required String currentPassword,
  });
  Stream<AppUser?> profileStream();
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<AppUser?> currentUser();
}

class FirebaseAuthRepository implements AuthRepository {
  //  final _auth = FirebaseAuth.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

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
  Stream<AppUser?> profileStream() async* {
    await for (final fb.User? u in _auth.authStateChanges()) {
      if (u == null) {
        yield null;
      } else {
        yield* _users
            .doc(u.uid)
            .snapshots()
            .map((d) => d.exists ? AppUser.fromMap(u.uid, d.data()!) : null);
      }
    }
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

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<AppUser> updateProfile({
    String? name,
    String? phone,
    String? localPhotoPath, // ignorado
  }) async {
    final fb.User? u = _auth.currentUser;
    if (u == null) throw Exception('Não autenticado');

    // Atualiza apenas nome no Auth (sem photo)
    if (name != null && name != u.displayName) {
      await u.updateDisplayName(name);
    }

    // Atualiza apenas name/phone/email no Firestore (sem photoUrl)
    await _users.doc(u.uid).set({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      'email': u.email ?? '',
    }, SetOptions(merge: true));

    final saved = await _users.doc(u.uid).get();
    return AppUser.fromMap(u.uid, saved.data()!);
  }

  @override
  Future<void> updateEmailWithPassword({
    required String newEmail,
    required String currentPassword,
  }) async {
    final fb.User? u = _auth.currentUser;
    if (u == null) throw Exception('Não autenticado');

    // 1) Reautentica com a senha atual
    final cred = fb.EmailAuthProvider.credential(
      email: u.email!,
      password: currentPassword,
    );
    await u.reauthenticateWithCredential(cred);

    // 2) Dispara e-mail de verificação para o NOVO endereço
    await u.verifyBeforeUpdateEmail(newEmail);

    // 3) (Opcional) Atualize o Firestore de forma otimista OU aguarde o usuário confirmar
    await _users.doc(u.uid).set({'email': newEmail}, SetOptions(merge: true));
    // Observação: a conta só troca para o novo e-mail depois do clique no link.
    // Você pode pedir para o usuário reabrir o app ou chamar u.reload() após o clique.
  }
}
