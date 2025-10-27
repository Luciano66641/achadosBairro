import 'package:flutter/material.dart';
import 'features/presentation/item_list_page.dart';
import 'features/presentation/new_item_page.dart';
import 'features/presentation/item_detail_page.dart';
import 'features/presentation/login_page.dart';
import 'features/presentation/signup_page.dart';
import 'package:neighborhood_finds/features/domain/item.dart';
import 'package:neighborhood_finds/features/presentation/profile_page.dart';
import 'package:neighborhood_finds/features/presentation/profile_edit_page.dart';

class AppRouter {
  static const itemListRoute = '/';
  static const newItemRoute = '/new';
  static const detailRoute = '/detail';
  static const login = '/login';
  static const signup = '/signup';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static Route onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case itemListRoute:
        return MaterialPageRoute(builder: (_) => const ItemListPage());
      case newItemRoute:
        final arg = s.arguments;
        if (arg is Item) {
          return MaterialPageRoute(builder: (_) => NewItemPage(initial: arg));
        }
        return MaterialPageRoute(builder: (_) => const NewItemPage());
      case detailRoute:
        final args = s.arguments as ItemDetailArgs;
        return MaterialPageRoute(builder: (_) => ItemDetailPage(args: args));
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Rota não encontrada'))),
        );
    }
  }
}
