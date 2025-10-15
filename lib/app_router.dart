import 'package:flutter/material.dart';
import 'features/items/presentation/item_list_page.dart';
import 'features/items/presentation/new_item_page.dart';
import 'features/items/presentation/item_detail_page.dart';

class AppRouter {
  static const itemListRoute = '/';
  static const newItemRoute  = '/new';
  static const detailRoute   = '/detail';

  static Route onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case itemListRoute:
        return MaterialPageRoute(builder: (_) => const ItemListPage());
      case newItemRoute:
        return MaterialPageRoute(builder: (_) => const NewItemPage());
      case detailRoute:
        final args = s.arguments as ItemDetailArgs;
        return MaterialPageRoute(builder: (_) => ItemDetailPage(args: args));
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Rota não encontrada'))));
    }
  }
}
