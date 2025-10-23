class AppUser {
  final String uid;
  final String email;
  final String name;

  const AppUser({required this.uid, required this.email, required this.name});

  Map<String, dynamic> toMap() => {'email': email, 'name': name};

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
    );
  }
}
