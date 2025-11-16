 import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  late ThemeMode _themeMode;
  late AppThemeData _currentTheme;

  ThemeProvider() {
    _themeMode = ThemeMode.system;
    _currentTheme = AppThemeData.light();
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  AppThemeData get currentTheme => _currentTheme;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'light';

    switch (themeString) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        _currentTheme = AppThemeData.dark();
        break;
      case 'midnight_grey':
        _themeMode = ThemeMode.dark;
        _currentTheme = AppThemeData.midnightGrey();
        break;
      case 'light':
      default:
        _themeMode = ThemeMode.light;
        _currentTheme = AppThemeData.light();
        break;
    }
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);

    switch (theme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        _currentTheme = AppThemeData.dark();
        break;
      case 'midnight_grey':
        _themeMode = ThemeMode.dark;
        _currentTheme = AppThemeData.midnightGrey();
        break;
      case 'light':
      default:
        _themeMode = ThemeMode.light;
        _currentTheme = AppThemeData.light();
        break;
    }
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Colors.blueGrey,
      secondary: Colors.lightBlue,
      surface: Colors.white,
      background: Color(0xFFE3F2FD),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: Colors.lightBlue,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
      onBackground: Colors.white70,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
      ),
    ),
  );

  ThemeData getThemeData() {
    switch (_currentTheme.name) {
      case 'dark':
        return darkTheme;
      case 'midnight_grey':
        return _buildMidnightGreyTheme();
      case 'light':
      default:
        return lightTheme;
    }
  }

  ThemeData _buildMidnightGreyTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2C3E50), // Dark blue-grey
        secondary: Color(0xFF34495E), // Lighter blue-grey
        surface: Color(0xFF1A1A1A), // Very dark grey
        background: Color(0xFF1A1A2E), // Blue-black
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white70,
        onBackground: Colors.white70,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Blue-black background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
        ),
      ),
    );
  }
}

class AppThemeData {
  final String name;
  final String displayName;
  final Color primaryColor;

  const AppThemeData({
    required this.name,
    required this.displayName,
    required this.primaryColor,
  });

  static AppThemeData light() => const AppThemeData(
    name: 'light',
    displayName: 'Light',
    primaryColor: Colors.blueGrey,
  );

  static AppThemeData dark() => const AppThemeData(
    name: 'dark',
    displayName: 'Dark',
    primaryColor: Colors.blueGrey,
  );

  static AppThemeData midnightGrey() => const AppThemeData(
    name: 'midnight_grey',
    displayName: 'Midnight Grey',
    primaryColor: Color(0xFF2C3E50),
  );
}
