class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? photoBase64;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.photoBase64,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'phone': phone,
    'photoBase64': photoBase64,
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] ?? '') as String,
      name:  (map['name']  ?? '') as String,
      phone: map['phone'] as String?,
      photoBase64: map['photoBase64'] as String?,
    );
  }
}
