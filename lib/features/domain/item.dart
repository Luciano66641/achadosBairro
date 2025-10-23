import 'package:neighborhood_finds/features/domain/item.dart';

class Item {
  final String id;
  final String title;
  final String description;
  final String? photoPath; // caminho local da foto
  final double lat;
  final double lng;
  final String? userId;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.photoPath,
    this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'lat': lat,
    'lng': lng,
    'createdAt': createdAt,
    'userId': userId,
    // photoPath fora por enquanto
  };

  factory Item.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return Item(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      photoPath:
          null, // ignorado a foto por hora, até criar a lógica para base64
      userId: map['userId'] as String?,
      createdAt: ts is DateTime ? ts : (ts?.toDate() ?? DateTime.now()),
    );
  }

  Item copyWith({
    String? id,
    String? title,
    String? description,
    double? lat,
    double? lng,
    String? photoPath,
    String? userId,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photoPath: photoPath ?? this.photoPath,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
