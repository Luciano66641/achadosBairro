import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';

class ItemWithDistance {
  final Item item;
  final double? distanceMeters;
  ItemWithDistance(this.item, this.distanceMeters);
}

class ItemListViewModel extends ChangeNotifier {
  final ItemRepository _repo;
  ItemListViewModel(this._repo);

  bool _loading = false;
  String? _error;
  Position? _pos;
  List<ItemWithDistance> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<ItemWithDistance> get items => _items;

  Future<void> load() async {
    _setLoading(true);
    _error = null;
    try {
      _pos = await _ensureLocation();
      final data = await _repo.list();
      _items = data.map((it) {
        double? d;
        if (_pos != null) {
          d = Geolocator.distanceBetween(_pos!.latitude, _pos!.longitude, it.lat, it.lng);
        }
        return ItemWithDistance(it, d);
      }).toList()
        ..sort((a, b) => (a.distanceMeters ?? 1e12).compareTo(b.distanceMeters ?? 1e12));
    } catch (e) {
      _error = 'Falha ao carregar itens';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  Future<Position?> _ensureLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
}
