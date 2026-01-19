// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ AGREGAR
import 'package:intl/intl.dart'; // ✅ AGREGAR
import 'package:provider/provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/personas_repository.dart';
import 'repositories/tarjetas_repository.dart';
import 'repositories/dispositivos_repository.dart';
import 'repositories/historial_repository.dart';
import 'repositories/analytics_repository.dart';
import 'views/menu.dart';
import 'views/login_view.dart';
import 'repositories/crate_repository.dart';

void main() {
  Intl.defaultLocale = 'es_ES'; // ✅ AGREGAR
  runApp(const Ecosistema());
}

class Ecosistema extends StatelessWidget {
  const Ecosistema({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(create: (_) => PersonasRepository()),
        ChangeNotifierProvider(create: (_) => TarjetasRepository()),
        ChangeNotifierProvider(create: (_) => DispositivosRepository()),
        ChangeNotifierProvider(create: (_) => HistorialRepository()),
        ChangeNotifierProvider(create: (_) => AnalyticsRepository()),
        ChangeNotifierProvider(create: (_) => CrateRepository()),
      ],
      child: MaterialApp(
        title: 'SmartLab FIWARE',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,

        // ✅ AGREGAR localizationsDelegates
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
        locale: const Locale('es', 'ES'), // ✅ AGREGAR

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const MenuPrincipal();
        }
        return const LoginView();
      },
    );
  }
}
