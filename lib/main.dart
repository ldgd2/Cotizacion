import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screen/home_screen.dart';
import 'screen/config_screen.dart';
import 'screen/company_screen.dart';
import 'screen/note_screen.dart';
import 'screen/image_screen.dart';
import 'screen/price_screen.dart';
import 'core/fileManager_core.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FileManagerCore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cotizaciones',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => HomeScreen());

          case '/company':
            return MaterialPageRoute(builder: (_) => const CompanyScreen());

          case '/config':
           // return MaterialPageRoute(builder: (_) => const ConfigScreen());

          case '/note':
          // return MaterialPageRoute(builder: (_) => const NoteScreen());

          case '/price':
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => PriceScreen(arguments: args),
              );
            }
            return _invalidRoute("PriceScreen");

          case '/image':
            if (args is Map<String, dynamic> &&
                args["imagenes"] is List<String> &&
                args["firma"] is String? &&
                args["onUpdate"] is Function) {
              return MaterialPageRoute(
                builder: (_) => ImageManagerScreen(
                  imagenes: List<String>.from(args["imagenes"]),
                  firma: args["firma"],
                  onUpdate: args["onUpdate"],
                ),
              );
            }
            return _invalidRoute("ImageManagerScreen");

          default:
            return _invalidRoute("Ruta no encontrada");
        }
      },
    );
  }

  /// Ruta fallback para errores
  MaterialPageRoute _invalidRoute(String target) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text("❌ Argumentos inválidos para $target")),
      ),
    );
  }
}
