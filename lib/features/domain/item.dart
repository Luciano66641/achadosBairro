import 'package:neighborhood_finds/features/domain/item.dart';

class ItemComment {
  final String userId;
  final DateTime createdAt;
  final String value;

  ItemComment({
    required this.userId,
    required this.createdAt,
    required this.value,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'value': value,
  };

  factory ItemComment.fromMap(Map<String, dynamic> map) {
    return ItemComment(
      userId: map['userId'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] ?? 0) as int,
        isUtc: true,
      ).toLocal(),
      value: map['value'] as String? ?? '',
    );
  }
}

class Item {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String? userId;
  final DateTime createdAt;
  final String? imageBase64;
  final List<ItemComment> comments;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.imageBase64,
    this.userId,
    required this.createdAt,
    this.comments = const [],
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'lat': lat,
    'lng': lng,
    'createdAt': createdAt,
    'userId': userId,
    'imageBase64': imageBase64,
    'comments': comments.map((c) => c.toMap()).toList(),
  };

  factory Item.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final rawComments = (map['comments'] as List?) ?? const [];
    return Item(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      imageBase64: map['imageBase64'] as String?,
      userId: map['userId'] as String?,
      createdAt: ts is DateTime ? ts : (ts?.toDate() ?? DateTime.now()),
      comments: rawComments
          .whereType<Map>()
          .map((m) => ItemComment.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
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
    List<ItemComment>? comments,
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
      comments: comments ?? this.comments,
    );
  }
}
