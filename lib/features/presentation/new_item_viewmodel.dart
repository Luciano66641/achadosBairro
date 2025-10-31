import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';

class NewItemViewModel extends ChangeNotifier {
  final ItemRepository _repo;
  NewItemViewModel(this._repo);

  bool _saving = false;
  String? _error;
  bool get saving => _saving;
  String? get error => _error;

  Future<bool> create({
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageBase64,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.add(
        Item(
          id: '',
          title: title,
          description: description,
          lat: lat,
          lng: lng,
          imageBase64: imageBase64,
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      _error = 'Falha ao salvar item';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required Item item,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageBase64,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      // Se o seu Item tem copyWith, use:
      final updated = (item.copyWith != null)
          ? item.copyWith(
              title: title,
              description: description,
              lat: lat,
              lng: lng,
              imageBase64: imageBase64 ?? item.imageBase64,
            )
          : Item(
              id: item.id,
              title: title,
              description: description,
              lat: lat,
              lng: lng,
              imageBase64: imageBase64 ?? item.imageBase64,
              userId: item.userId, // se o seu modelo tiver esse campo
              createdAt: item.createdAt, // <--- ADICIONA ESTA LINHA
            );

      await _repo.update(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  static Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      return null;
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
