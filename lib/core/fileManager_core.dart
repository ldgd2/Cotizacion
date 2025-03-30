import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Directory, File, Platform;
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

  await saveAsFile(cotizacion); // Esta función ya actualiza currentFile
  if (currentFile != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/price', arguments: cotizacion);
    });
  }
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
  String defaultFileName = "cotizacion_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '_')}.cotz";

  String? filePath;

  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar como...',
      allowedExtensions: ['cotz'],
      fileName: defaultFileName,
    );
  } else {
    final dir = await getApplicationDocumentsDirectory();
    filePath = "${dir.path}/$defaultFileName";
  }

  if (filePath == null) return;

  await saveToFile(filePath, sanitized);
  currentFile = filePath;
  await addToRecentFiles(filePath);
  _notify();
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
  final fileName = filePath.split('/').last;
  final timestamp = DateTime.now().toIso8601String();

  recentFiles.removeWhere((line) => line.split('|')[1] == filePath);
  recentFiles.insert(0, "$fileName|$filePath|$timestamp");

  if (recentFiles.length > 5) {
    recentFiles = recentFiles.sublist(0, 5);
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

  List<Map<String, String>> getRecentFilesParsed() {
  return recentFiles.map((e) {
    final parts = e.split('|');
    return {
      "name": parts[0],
      "path": parts[1],
      "date": parts.length > 2 ? parts[2] : "",
    };
  }).toList();
}

}
