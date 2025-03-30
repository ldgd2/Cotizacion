import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileManagerCore extends ChangeNotifier {
  String? currentFile;
  List<String> recentFiles = [];

  void _notify() => notifyListeners();

  Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> openFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        String? filePath = result.files.single.path;

        if (filePath != null && filePath.endsWith('.cotz')) {
          File file = File(filePath);
          String content = await file.readAsString();

          try {
            Map<String, dynamic> cotizacion = jsonDecode(content);
            cotizacion = _sanitizeCotizacion(cotizacion);

            currentFile = file.path;
            await addToRecentFiles(file.path);
            _notify();

            // ✅ Navegar de forma segura
           WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/price', arguments: cotizacion);
            });

           
          } catch (e) {
            _showError(context, 'Error al leer el archivo: $e');
          }
        } else {
          _showError(context, 'Archivo no compatible. Selecciona un archivo .cotz');
        }
      }
    } catch (e) {
      _showError(context, 'Error al abrir el explorador: $e');
    }
  }

  Future<void> newFile(BuildContext context) async {
  // 🧠 1. Seleccionar ubicación + nombre
  String? filePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Guardar nueva cotización como...',
    allowedExtensions: ['cotz'],
    fileName: 'nueva_cotizacion.cotz',
  );

  if (filePath == null) return; // El usuario canceló

  // 🧱 2. Estructura vacía por defecto
  final Map<String, dynamic> cotizacion = {
    "nombre_proyecto": "",
    "nombre_cliente": "",
    "empresa": "Seleccionar Empresa",
    "direccion": "",
    "telefono": "",
    "correo": "",
    "eslogan": "",
    "fecha": DateTime.now().toString().split(" ")[0],
    "moneda": "BOB (Bs)",
    "productos": [],
    "imagenes": <String>[],
    "firma": "",
    "logo": null,
  };

  // 💾 3. Guardar en archivo y actualizar estado
  await saveToFile(filePath, cotizacion);
  currentFile = filePath;
  await addToRecentFiles(filePath);
  _notify();

  // 🚀 4. Abrir pantalla con la nueva cotización
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pushNamed(context, '/price', arguments: cotizacion);
  });
}


 Future<void> saveFile(Map<String, dynamic> cotizacion) async {
  final sanitized = _sanitizeCotizacion(cotizacion); // Limpia datos incompletos
  if (currentFile != null) {
    await saveToFile(currentFile!, sanitized);
  } else {
    await saveAsFile(sanitized);
  }
  _notify();
}


  Future<void> saveAsFile(Map<String, dynamic> cotizacion) async {
  final sanitized = _sanitizeCotizacion(cotizacion);
  String? filePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Guardar Como',
    allowedExtensions: ['cotz'],
    fileName: 'cotizacion.cotz',
  );

  if (filePath != null) {
    await saveToFile(filePath, sanitized);
    currentFile = filePath;
    await addToRecentFiles(filePath);
    _notify();
  }
}


  Future<void> saveToFile(String filePath, Map<String, dynamic> cotizacion) async {
    try {
      File file = File(filePath);
      await file.writeAsString(jsonEncode(cotizacion), encoding: utf8);
      print('✅ Archivo guardado en: $filePath');
      await addToRecentFiles(filePath);
    } catch (e) {
      print('⚠ Error al guardar: $e');
    }
  }

  Future<void> addToRecentFiles(String filePath) async {
    String fileName = filePath.split('/').last;

    recentFiles.removeWhere((file) => file.split('|')[1] == filePath);
    recentFiles.insert(0, "$fileName|$filePath");

    if (recentFiles.length > 10) {
      recentFiles = recentFiles.sublist(0, 10);
    }

    await saveRecentFiles();
    _notify();
  }

  Future<void> saveRecentFiles() async {
    final dir = await getDocumentsDirectory();
    final path = '${dir.path}/recent_files.json';
    await File(path).writeAsString(jsonEncode(recentFiles));
  }

  Future<void> loadRecentFiles() async {
    final dir = await getDocumentsDirectory();
    final path = '${dir.path}/recent_files.json';

    final file = File(path);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        recentFiles = List<String>.from(jsonDecode(content));
      } catch (_) {
        recentFiles = [];
      }
    } else {
      recentFiles = [];
    }
    _notify();
  }

  Future<void> openRecentFile(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        Map<String, dynamic> cotizacion = jsonDecode(content);
        cotizacion = _sanitizeCotizacion(cotizacion);

        currentFile = filePath;
        _notify();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(
            context,
            '/price',
            arguments: cotizacion, 
          );
        });
      } else {
        _showError(context, "El archivo no existe: $filePath");
      }
    } catch (e) {
      _showError(context, "Error al abrir el archivo: $e");
    }
  }

  /// ✅ Limpia y asegura que los campos críticos no sean null
 Map<String, dynamic> _sanitizeCotizacion(Map<String, dynamic> c) {
  List<Map<String, dynamic>> productos = [];

  if (c["productos"] is List) {
    try {
      productos = List<Map<String, dynamic>>.from(c["productos"]);
    } catch (e) {
      print("⚠️ Error al convertir productos: $e");
    }
  }

  return {
    "nombre_proyecto": c["nombre_proyecto"] ?? "",
    "nombre_cliente": c["nombre_cliente"] ?? "",
    "empresa": c["empresa"] ?? "Seleccionar Empresa",
    "direccion": c["direccion"] ?? "",
    "telefono": c["telefono"] ?? "",
    "correo": c["correo"] ?? "",
    "eslogan": c["eslogan"] ?? "",
    "fecha": c["fecha"] ?? DateTime.now().toString().split(" ")[0],
    "moneda": c["moneda"] ?? "BOB (Bs)",
    "productos": productos,
    "imagenes": c["imagenes"] is List
        ? List<String>.from(c["imagenes"])
        : <String>[],
    "firma": c["firma"] ?? "",
    "logo": c["logo"] ?? null,
  };
}



  void _showError(BuildContext context, String message) {
    print('❌ $message');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
