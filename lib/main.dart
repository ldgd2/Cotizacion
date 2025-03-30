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

  final context = navigatorKey.currentState?.overlay?.context;
  if (context != null) {
    await _solicitarPermisosConDialogo(context);
  }

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

/// Global navigator key para mostrar diálogos desde main
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _solicitarPermisosConDialogo(BuildContext context) async {
  Future<bool> pedir(Permission permiso, String motivo) async {
    var status = await permiso.status;
    if (status.isDenied || status.isRestricted) {
     final result = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text("Permiso requerido"),
    content: Text(motivo),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false), // 👈 corregido
        child: const Text("Cancelar"),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true), // 👈 corregido
        child: const Text("Permitir"),
      ),
    ],
  ),
);

      if (result == true) {
        final nuevoEstado = await permiso.request();
        return nuevoEstado.isGranted;
      }
    }
    return status.isGranted;
  }

  // Android ≥ 13
  await pedir(Permission.storage, "Necesitamos acceder a tu almacenamiento para guardar archivos de cotización.");
  await pedir(Permission.manageExternalStorage, "Para acceder a carpetas y archivos fuera de la aplicación.");
  await pedir(Permission.photos, "Para seleccionar o mostrar imágenes en la cotización.");

  // Mostrar si se negó permanentemente
  final negados = [
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.photos
  ].where((p) => p.status == PermissionStatus.permanentlyDenied);

  if (await Future.any(negados.map((p) => p.isPermanentlyDenied))) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Algunos permisos están permanentemente denegados. Ve a configuración."),
        action: SnackBarAction(
          label: "Abrir Ajustes",
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cotizaciones',
      navigatorKey: navigatorKey, // necesario para mostrar diálogos desde main
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
