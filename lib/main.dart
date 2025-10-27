import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:neighborhood_finds/app_router.dart';

import 'package:neighborhood_finds/features/data/item_repository.dart';
import 'package:neighborhood_finds/features/data/firebase_item_repository.dart';
import 'package:neighborhood_finds/features/presentation/item_list_viewmodel.dart';
import 'package:neighborhood_finds/features/presentation/new_item_viewmodel.dart';

import 'package:neighborhood_finds/features/data/auth_repository.dart';
import 'package:neighborhood_finds/features/presentation/auth_gate.dart';
import 'package:neighborhood_finds/features/presentation/login_viewmodel.dart';
import 'package:neighborhood_finds/features/presentation/signup_viewmodel.dart';
import 'package:neighborhood_finds/features/presentation/profile_viewmodel.dart';
import 'package:neighborhood_finds/features/presentation/profile_edit_viewmodel.dart';

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
        // Auth
        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),

        ChangeNotifierProvider(
          create: (ctx) => ProfileViewModel(ctx.read<AuthRepository>()),
        ),
        
        ChangeNotifierProvider(create: (ctx) => ProfileEditViewModel(ctx.read<AuthRepository>())),
        
        ChangeNotifierProvider<LoginViewModel>(
          create: (ctx) => LoginViewModel(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<SignupViewModel>(
          create: (ctx) => SignupViewModel(ctx.read<AuthRepository>()),
        ),
        // Itens
        Provider<ItemRepository>(create: (_) => FirebaseItemRepository()),
        ChangeNotifierProvider(
          create: (ctx) =>
              ItemListViewModel(ctx.read<ItemRepository>())..load(),
        ),
        ChangeNotifierProvider(
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
        home: const AuthGate(),
      ),
    );
  }
}
