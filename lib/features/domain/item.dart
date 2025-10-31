import 'package:neighborhood_finds/features/domain/item.dart';

class Item {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String? userId;
  final DateTime createdAt;
  final String? imageBase64;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.imageBase64,
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
    'imageBase64': imageBase64,
  };

  factory Item.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return Item(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      imageBase64: map['imageBase64'] as String?,
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
    String? imageBase64,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageBase64: imageBase64 ?? this.imageBase64,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
