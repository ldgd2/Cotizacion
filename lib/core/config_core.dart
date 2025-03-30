import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigCore extends ChangeNotifier {
  static const String _fileName = "config.json";
  static Map<String, dynamic> _config = {
    "idioma": "es",
    "tema": "Oscuro",
    "auto_guardado": false,
    "notificaciones": true,
    "mostrar_totales": "detallado",
    "fecha_expiracion": true
  };

  /// Obtiene el directorio de almacenamiento seguro de la aplicación
  static Future<String> _getConfigFilePath() async {
    final Directory dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_fileName';
  }

  /// Inicializa el archivo JSON de configuración si no existe
  Future<void> initializeConfigFile() async {
    final String filePath = await _getConfigFilePath();
    final File file = File(filePath);

    if (!await file.exists()) {
      await saveConfig();
    } else {
      await loadConfig();
    }
  }

  /// Carga la configuración desde el archivo JSON
  Future<void> loadConfig() async {
    try {
      final String filePath = await _getConfigFilePath();
      final File file = File(filePath);

      if (await file.exists()) {
        final String content = await file.readAsString();
        _config = jsonDecode(content);
        notifyListeners();
      }
    } catch (e) {
      print("Error al cargar configuracion: $e");
    }
  }

  /// Guarda la configuración en el archivo JSON
  Future<void> saveConfig() async {
    try {
      final String filePath = await _getConfigFilePath();
      final File file = File(filePath);
      await file.writeAsString(jsonEncode(_config), encoding: utf8);
      notifyListeners();
    } catch (e) {
      print("Error al guardar configuracion: $e");
    }
  }

  /// Cambia el idioma
  void setIdioma(String idioma) {
    _config["idioma"] = idioma;
    saveConfig();
  }

  /// Cambia el tema (claro/oscuro)
  void setTema(String tema) {
    _config["tema"] = tema;
    _applyTheme();
    saveConfig();
  }

  /// Activa o desactiva el auto-guardado
  void setAutoGuardado(bool estado) {
    _config["auto_guardado"] = estado;
    saveConfig();
  }

  /// Activa o desactiva las notificaciones
  void setNotificaciones(bool estado) {
    _config["notificaciones"] = estado;
    saveConfig();
  }

  /// Cambia la forma en que se muestran los totales en las cotizaciones
  void setMostrarTotales(String tipo) {
    _config["mostrar_totales"] = tipo;
    saveConfig();
  }

  /// Activa o desactiva la fecha de expiración en las cotizaciones
  void setFechaExpiracion(bool estado) {
    _config["fecha_expiracion"] = estado;
    saveConfig();
  }

  /// Aplica el tema globalmente
  void _applyTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDarkTheme", _config["tema"] == "Oscuro");
  }

  /// Obtiene la configuración actual
  Map<String, dynamic> getConfig() {
    return _config;
  }

  /// Obtiene el idioma actual
  String getIdioma() {
    return _config["idioma"];
  }

  /// Obtiene el tema actual
  String getTema() {
    return _config["tema"];
  }

  /// Obtiene el estado del auto-guardado
  bool getAutoGuardado() {
    return _config["auto_guardado"];
  }

  /// Obtiene el estado de las notificaciones
  bool getNotificaciones() {
    return _config["notificaciones"];
  }

  /// Obtiene la forma en que se muestran los totales en las cotizaciones
  String getMostrarTotales() {
    return _config["mostrar_totales"];
  }

  /// Obtiene si las cotizaciones tienen fecha de expiración
  bool getFechaExpiracion() {
    return _config["fecha_expiracion"];
  }
}
