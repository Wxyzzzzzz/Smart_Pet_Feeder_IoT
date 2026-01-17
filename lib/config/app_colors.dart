import 'package:flutter/material.dart';

class AppColors {
  // Orimary
  static const Color primaryLight = Color(0xFFB8A69A); 
  static const Color primaryDark = Color(0xFF8C7A6B); 

  // Accent 
  static const Color accentSage = Color(0xFFA8B5A0);
  static const Color accentTerracotta = Color(0xFFD4A59A); 
  static const Color accentClay = Color(0xFFC9B5A0); 

  // Background 
  static const Color backgroundLight = Color(0xFFF5F3F0); 
  static const Color cardBackground = Colors.white;

  // Text 
  static const Color textDark = Color(0xFF4A3F35);
  static const Color textLight = Color(0xFF8C8277);
  static const Color textWhite = Colors.white;

  // Status 
  static const Color success = Color(0xFF9FB89A); 
  static const Color warning = Color(0xFFD4B896); 
  static const Color error = Color(0xFFC99A92); 
  static const Color info = Color(0xFFA5B5C9); 

  // Gradient Colors
  static const List<Color> earthGradient = [
    Color(0xFFBDADA3),
    Color(0xFF9D8B7E), 
  ];

  // MaterialColor
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  static final MaterialColor primarySwatch = createMaterialColor(primaryDark);
}
