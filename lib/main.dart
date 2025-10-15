import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'app_router.dart';

import 'features/items/data/firebase_item_repository.dart';
import 'features/items/data/item_repository.dart';
import 'features/items/presentation/item_list_viewmodel.dart';
import 'features/items/presentation/new_item_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const NeighborhoodFindsApp());
}

class NeighborhoodFindsApp extends StatelessWidget {
  const NeighborhoodFindsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
     providers: [
        Provider<ItemRepository>(create: (_) => FirebaseItemRepository()),
        ChangeNotifierProvider<ItemListViewModel>(
          create: (ctx) => ItemListViewModel(ctx.read<ItemRepository>())..load(),
        ),
        ChangeNotifierProvider<NewItemViewModel>(
          create: (ctx) => NewItemViewModel(ctx.read<ItemRepository>()),
        ),
    ],
      child: MaterialApp(
        title: 'Achados do Bairro',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.itemListRoute,
      ),
    );
  }
}
