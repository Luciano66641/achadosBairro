class Item {
  final String id;
  final String title;
  final String description;
  final String? photoPath; // caminho local da foto
  final double lat;
  final double lng;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'lat': lat,
    'lng': lng,
    'createdAt': createdAt,
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
      createdAt: ts is DateTime ? ts : (ts?.toDate() ?? DateTime.now()),
    );
  }
}
