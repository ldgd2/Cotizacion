import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class ThemeCore extends ChangeNotifier {
  ThemeData _currentTheme = ThemeData.light();
  Map<String, dynamic> _themeConfig = {};

  /// Obtiene el tema actual
  ThemeData get theme => _currentTheme;

  /// Carga el tema desde un archivo JSON
  Future<void> loadTheme(String themeName) async {
    final String themePath = await _getThemeFilePath(themeName);
    final File themeFile = File(themePath);

    if (await themeFile.exists()) {
      final String content = await themeFile.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(content);
      _themeConfig = jsonData;
      _applyTheme(jsonData);
    } else {
      print("⚠️ Archivo de tema no encontrado: $themeName");
    }
  }

  /// Aplica el tema basado en el JSON cargado
  void _applyTheme(Map<String, dynamic> jsonData) {
    final Brightness brightness =
        jsonData["brightness"] == "dark" ? Brightness.dark : Brightness.light;
    final Color primaryColor = _hexToColor(jsonData["primaryColor"]);
    final Color backgroundColor = _hexToColor(jsonData["backgroundColor"]);
    final Color appBarColor = _hexToColor(jsonData["appBarColor"]);
    final Color textColor = _hexToColor(jsonData["textColor"]);
    final Color buttonColor = _hexToColor(jsonData["buttonColor"]);
    final Color buttonTextColor = _hexToColor(jsonData["buttonTextColor"]);
    final Color inputBorderColor = _hexToColor(jsonData["inputBorderColor"]);
    final Color inputFocusedBorderColor = _hexToColor(jsonData["inputFocusedBorderColor"]);
    final Color cardColor = _hexToColor(jsonData["cardColor"]);
    final Color iconColor = _hexToColor(jsonData["iconColor"]);
    final Color glowColor = _hexToColor(jsonData["glowColor"]);
    final Color slideBarColor = _hexToColor(jsonData["slideBarColor"]);
    final Color checkboxActiveColor = _hexToColor(jsonData["checkboxActiveColor"]);
    final Color cellBorderColor = _hexToColor(jsonData["cellBorderColor"]);
    final Color hoverEffectColor = _hexToColor(jsonData["hoverEffectColor"]);
    final Color shadowColor = _hexToColor(jsonData["shadowColor"]);
    final Color textShadowColor = _hexToColor(jsonData["textShadowColor"]);

    final String fontFamily = jsonData["fontFamily"] ?? "Roboto";
    final double fontSize = jsonData["fontSize"]?.toDouble() ?? 14.0;
    final double borderRadius = jsonData["borderRadius"]?.toDouble() ?? 10.0;
    final int buttonAnimationDuration = jsonData["buttonAnimationDuration"] ?? 300;
    final int swipeAnimationSpeed = jsonData["swipeAnimationSpeed"] ?? 400;

    _currentTheme = ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: textColor,
          fontFamily: fontFamily,
          fontSize: fontSize,
          shadows: [Shadow(color: textShadowColor, blurRadius: 3)],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: buttonTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          animationDuration: Duration(milliseconds: buttonAnimationDuration),
          shadowColor: shadowColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: inputFocusedBorderColor),
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        shadowColor: shadowColor,
      ),
      iconTheme: IconThemeData(color: iconColor),
      sliderTheme: SliderThemeData(
        activeTrackColor: slideBarColor,
        thumbColor: slideBarColor,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(checkboxActiveColor),
      ),
    );

    notifyListeners();
  }

  /// Obtiene la ruta segura donde se guardarán los archivos de temas
  Future<String> _getThemeFilePath(String themeName) async {
    final Directory dir = await getApplicationSupportDirectory();
    return "${dir.path}/$themeName";
  }

  /// Convierte un color en formato HEX a `Color`
  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    return Color(int.parse("0xFF$hex"));
  }
}
