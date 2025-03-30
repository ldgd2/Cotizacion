import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/fileManager_core.dart';
import 'screen/home_screen.dart';
import 'screen/company_screen.dart';
import 'screen/image_screen.dart';
import 'screen/price_screen.dart';
import 'screen/note_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Solicitar permisos para almacenamiento
  await _solicitarPermisos();

  final fileManager = FileManagerCore();
  await fileManager.loadRecentFiles();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => fileManager),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _solicitarPermisos() async {
  // Android >= 33 (Tiramisu) usa READ_MEDIA_* en vez de STORAGE
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }

  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }

  // iOS: opcional pero buena práctica
  if (await Permission.photos.isDenied) {
    await Permission.photos.request();
  }

  // Verifica si alguno fue denegado permanentemente
  if (await Permission.storage.isPermanentlyDenied ||
      await Permission.manageExternalStorage.isPermanentlyDenied ||
      await Permission.photos.isPermanentlyDenied) {
    openAppSettings();
  }
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
            return _invalidRoute("ConfigScreen");

          case '/notes':
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => NoteScreen(cotizacion: args),
              );
            }
            return _invalidRoute("NoteScreen");

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

  MaterialPageRoute _invalidRoute(String target) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text("❌ Argumentos inválidos para $target")),
      ),
    );
  }
}
