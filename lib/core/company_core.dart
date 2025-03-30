import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class CompanyCore {
  static const String _fileName = "companies.json";
  static List<Map<String, dynamic>> _companies = [];

  /// Ruta del archivo JSON
  static Future<String> _getFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_fileName';
  }

  /// Ruta del directorio de logos
  static Future<String> _getLogoDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final logoDir = Directory('${dir.path}/logos');
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }
    return logoDir.path;
  }

  /// Inicializa archivo de empresas
  static Future<void> initializeCompanyFile() async {
    final path = await _getFilePath();
    final file = File(path);

    if (await file.exists()) {
      await loadCompanies();
    } else {
      _companies = [];
      await saveCompanies();
    }
  }

  /// Carga empresas desde archivo
  static Future<void> loadCompanies() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is List) {
          _companies = List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (e) {
      print("Error cargando empresas: $e");
    }
  }

  /// Guarda empresas en archivo
  static Future<void> saveCompanies() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      await file.writeAsString(jsonEncode(_companies), encoding: utf8);
    } catch (e) {
      print("Error guardando empresas: $e");
    }
  }

  /// Agrega o actualiza empresa
  static Future<void> addOrUpdateCompany({
    required String name,
    required String direccion,
    required String telefono,
    required String correo,
    String? eslogan,
    String? logoPath,
  }) async {
    if (name.trim().isEmpty) return;

    final index = _companies.indexWhere((c) => c["nombre"] == name);

    String? savedLogoPath;

    if (logoPath != null && logoPath.isNotEmpty) {
      savedLogoPath = await _saveLogoFile(name, logoPath);
    }

    final newEmpresa = {
      "nombre": name.trim(),
      "direccion": direccion.trim(),
      "telefono": telefono.trim(),
      "correo": correo.trim(),
      "eslogan": eslogan?.trim() ?? "",
      "logo": savedLogoPath ??
          (index != -1 ? _companies[index]["logo"] : "") // mantener logo anterior si no se cambia
    };

    if (index != -1) {
      _companies[index] = newEmpresa;
    } else {
      _companies.add(newEmpresa);
    }

    await saveCompanies();
  }

  /// Elimina una empresa
  static Future<void> deleteCompany(String name) async {
    _companies.removeWhere((e) => e["nombre"] == name);
    await saveCompanies();
  }

  /// Retorna todas las empresas
  static List<Map<String, dynamic>> getCompanies() => _companies;

  /// Busca una empresa por nombre
  static Map<String, dynamic>? getCompany(String name) {
    return _companies.firstWhere(
      (e) => e["nombre"] == name,
      orElse: () => {},
    );
  }

  /// Verifica si existe una empresa
  static bool companyExists(String name) {
    return _companies.any((e) => e["nombre"] == name);
  }

  /// Selecciona un logo desde archivos
  static Future<String?> pickAndSaveLogo(String companyName) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      return await _saveLogoFile(companyName, result.files.single.path!);
    }
    return null;
  }

  /// Guarda el logo en la carpeta local (sobrescribe si ya existe)
  static Future<String> _saveLogoFile(String companyName, String originalPath) async {
    final logoDir = await _getLogoDirectory();
    final sanitizedName = companyName.replaceAll(RegExp(r'\s+'), '_');
    final extension = originalPath.split('.').last;
    final logoPath = '$logoDir/${sanitizedName}_logo.$extension';

    final originalFile = File(originalPath);
    final savedFile = File(logoPath);

    await originalFile.copy(savedFile.path);
    return savedFile.path;
  }
}
