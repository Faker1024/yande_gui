import 'package:flutter/material.dart';

const _lightBackground = Color(0xFFFFF7FB);
const _lightSurface = Color(0xFFFFFFFF);
const _lightSurfaceAlt = Color(0xFFFFEDF5);
const _lightText = Color(0xFF352433);
const _lightMuted = Color(0xFF7A6677);
const _lightOutline = Color(0xFFF0D8E5);
const _lightAqua = Color(0xFF4DBDC2);
const _lightHoney = Color(0xFFF3B95D);

const _darkBackground = Color(0xFF251C27);
const _darkSurface = Color(0xFF312637);
const _darkSurfaceAlt = Color(0xFF3D3044);
const _darkText = Color(0xFFFFF7FB);
const _darkMuted = Color(0xFFD8C5D2);
const _darkOutline = Color(0xFF5B495D);
const _darkAqua = Color(0xFF8DE1E4);
const _darkHoney = Color(0xFFFFCF7A);

TextTheme _textTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final text = isDark ? _darkText : _lightText;
  final muted = isDark ? _darkMuted : _lightMuted;

  return TextTheme(
    headlineSmall: TextStyle(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontSize: 16,
    ),
    titleSmall: TextStyle(
      color: text,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontSize: 14,
    ),
    bodyLarge: TextStyle(color: text, letterSpacing: 0, fontSize: 16),
    bodyMedium: TextStyle(color: text, letterSpacing: 0, fontSize: 14),
    bodySmall: TextStyle(color: muted, letterSpacing: 0, fontSize: 12),
    labelLarge: TextStyle(
      color: muted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontSize: 14,
    ),
    labelMedium: TextStyle(
      color: muted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontSize: 12,
    ),
    labelSmall: TextStyle(
      color: muted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontSize: 11,
    ),
  );
}

ThemeData lightTheme(Color primaryColor) {
  final scheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: primaryColor,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFD8E9),
    onPrimaryContainer: _lightText,
    secondary: _lightAqua,
    onSecondary: _lightText,
    secondaryContainer: const Color(0xFFE5FAFA),
    onSecondaryContainer: _lightText,
    tertiary: _lightHoney,
    surface: _lightSurface,
    onSurface: _lightText,
    surfaceContainerHighest: _lightSurfaceAlt,
    outline: _lightOutline,
    outlineVariant: _lightOutline,
  );

  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: scheme,
    primaryColor: scheme.primary,
    textTheme: _textTheme(Brightness.light),
    scaffoldBackgroundColor: _lightBackground,
    cardColor: _lightSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: _lightText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightSurface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: _lightMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _lightSurface,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: const IconThemeData(color: _lightMuted),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: _lightMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      indicatorColor: _lightSurfaceAlt,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    iconTheme: const IconThemeData(color: _lightMuted),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      hintStyle: const TextStyle(color: _lightMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    ),
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _lightOutline),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _lightOutline, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: _lightMuted,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _lightSurfaceAlt,
      selectedColor: _lightText,
      side: const BorderSide(color: _lightOutline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(
        color: _lightText,
        fontWeight: FontWeight.w600,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: _lightSurfaceAlt,
    ),
  );
}

ThemeData darkTheme(Color primaryColor) {
  final scheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: primaryColor,
    primary: const Color(0xFFFFA9CB),
    onPrimary: _darkBackground,
    primaryContainer: const Color(0xFF5B344A),
    onPrimaryContainer: _darkText,
    secondary: _darkAqua,
    onSecondary: _darkBackground,
    secondaryContainer: const Color(0xFF254A4E),
    onSecondaryContainer: _darkText,
    tertiary: _darkHoney,
    surface: _darkSurface,
    onSurface: _darkText,
    surfaceContainerHighest: _darkSurfaceAlt,
    outline: _darkOutline,
    outlineVariant: _darkOutline,
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    primaryColor: scheme.primary,
    textTheme: _textTheme(Brightness.dark),
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: _darkMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: _darkBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _darkSurface,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: const IconThemeData(color: _darkMuted),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: _darkMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      indicatorColor: _darkSurfaceAlt,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    iconTheme: const IconThemeData(color: _darkMuted),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      hintStyle: const TextStyle(color: _darkMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _darkOutline),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _darkOutline, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: _darkMuted,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkSurfaceAlt,
      selectedColor: _darkText,
      side: const BorderSide(color: _darkOutline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(
        color: _darkText,
        fontWeight: FontWeight.w600,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: _darkSurfaceAlt,
    ),
  );
}
