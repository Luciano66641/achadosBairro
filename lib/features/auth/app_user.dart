class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'phone': phone,
    'photoUrl': photoUrl,
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] ?? '') as String,
      name:  (map['name']  ?? '') as String,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
