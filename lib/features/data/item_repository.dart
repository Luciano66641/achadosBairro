import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/item.dart';

abstract class ItemRepository {
  Future<List<Item>> list();
  Future<Item> add(Item item);
  Future<Item> getById(String id);

  Future<void> update(Item item);
  Future<void> delete(String id);

  Future<void> addComment({
    required String itemId,
    required ItemComment comment,
  });

  Stream<List<ItemComment>> watchComments(String itemId);
}