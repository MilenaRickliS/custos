import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/firestore_paths.dart';

import 'providers/auth_provider.dart';
import 'providers/materia_prima_provider.dart';
import 'providers/fornecedor_provider.dart';
import 'providers/produto_provider.dart';

import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/cadastro.dart';
import 'screens/cadastro_produto.dart';
import 'screens/cadastro_mp.dart';
import 'screens/detalhes_produto.dart';
import 'screens/tabela_geral.dart';
import 'screens/perfil.dart';
import 'screens/ajuda.dart';
import 'screens/produto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestorePaths>(
          create: (_) => FirestorePaths(FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MateriaPrimaProvider(),),
        Provider<ProdutoProvider>(
          create: (_) => ProdutoProvider(),
        ),
        Provider(create: (_) => FornecedorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return MaterialApp(
          navigatorObservers: [routeObserver],

          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          debugShowCheckedModeBanner: false,
          title: 'Custos',

          themeMode: theme.themeMode,

          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFDF7ED),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
          ),

          initialRoute: '/',

          routes: {
            '/': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/cadastro': (context) => const CadastroScreen(),
            '/cadastro-produto': (context) => const CadastroProdutoScreen(),
            '/cadastro-mp': (context) => const CadastroMPScreen(),
            '/produtos': (context) => const ProdutosScreen(),
            '/produto-detalhe': (_) => const ProdutoDetalheScreen(),
            '/tabela-geral': (context) => const TabelaGeralScreen(),
            '/perfil': (context) => const PerfilScreen(),
            '/ajuda': (context) => const AjudaScreen(),
          },
        );
      },
    );
  }
}