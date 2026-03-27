import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light; // Default to Light Mode for "easier on the eyes"

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
  }

  // Light Color Palette for a bright, airy feel
  static const Color brandLightBlue = Color(0xFF42A5F5); // Light blue primary
  static const Color brandLightYellow = Color(0xFFFFF9C4); // Pale yellow secondary
  static const Color brandLightGray = Color(0xFF90CAF9);   // Light gray-blue tertiary
  
  static const Color lightBg = Colors.white;    // Pure white background for maximum lightness
  static const Color lightSurface = Colors.white;
  static const Color darkBg = Color(0xFF1E293B);     // Softer dark navy (not black)
  static const Color darkSurface = Color(0xFF334155);

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: brandLightBlue,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: brandLightBlue,
      onPrimary: Colors.white,
      secondary: brandLightYellow,
      onSecondary: Color(0xFF475569),
      tertiary: brandLightGray,
      surface: lightSurface,
      error: Color(0xFFEF4444),
    ),
    dividerColor: Color(0xFFE2E8F0),
    cardColor: lightSurface,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1E293B), letterSpacing: 0.2),
      bodyMedium: TextStyle(color: Color(0xFF64748B), letterSpacing: 0.1),
      titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: brandLightBlue,
    scaffoldBackgroundColor: Color(0xFF0F172A), // Deep navy
    colorScheme: const ColorScheme.dark(
      primary: brandLightBlue,
      onPrimary: Colors.white,
      secondary: brandLightYellow,
      onSecondary: Colors.black87,
      tertiary: brandLightGray,
      surface: darkBg,
      error: Color(0xFFEF4444),
    ),
    dividerColor: Colors.white10,
    cardColor: darkBg,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF1F5F9), letterSpacing: 0.2),
      bodyMedium: TextStyle(color: Color(0xFF94A3B8), letterSpacing: 0.1),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
