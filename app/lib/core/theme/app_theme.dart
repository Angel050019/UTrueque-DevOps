import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de UTrueque, tomada del logo (azul marino + menta).
/// ÚNICO lugar donde se definen colores: si el diseño cambia, se cambia
/// aquí y toda la app se actualiza. Los nombres coinciden con las
/// variables de Figma (colección "UTrueque · Colores").
class AppColores {
  AppColores._();

  static const Color primario = Color(0xFF033B56);
  static const Color primarioOscuro = Color(0xFF022A3E);
  static const Color primarioSuave = Color(0xFFE2EDF2);
  static const Color acento = Color(0xFF96FCCA);
  static const Color acentoSuave = Color(0xFFE7FEF3);
  static const Color fondo = Color(0xFFF5F8FA);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color texto = Color(0xFF0B2533);
  static const Color textoSecundario = Color(0xFF5A6B76);
  static const Color sobrePrimario = Color(0xFFFFFFFF);
  static const Color borde = Color(0xFFD6E0E6);
  static const Color error = Color(0xFFC62828);
  static const Color errorSuave = Color(0xFFFDECEC);
}

/// Estilos de texto: Poppins para títulos y botones, Inter para el resto.
class AppTexto {
  AppTexto._();

  static TextStyle titulo({double size = 28, Color color = AppColores.texto}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle subtitulo({double size = 16, Color color = AppColores.texto}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w600, color: color);

  static TextStyle cuerpo({
    double size = 15,
    Color color = AppColores.textoSecundario,
    FontWeight peso = FontWeight.w400,
  }) =>
      GoogleFonts.inter(fontSize: size, fontWeight: peso, color: color, height: 1.4);

  static TextStyle etiqueta({Color color = AppColores.textoSecundario}) =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: color);
}

/// Medidas compartidas para que todas las pantallas se vean iguales.
class AppMedidas {
  AppMedidas._();

  static const double margen = 24;
  static const double radioCampo = 12;
  static const double radioBoton = 14;
  static const double radioTarjeta = 16;
  static const double altoBoton = 52;
}

/// Tema base de la aplicación (Material 3).
class AppTheme {
  AppTheme._();

  static ThemeData get claro {
    final ColorScheme esquema = ColorScheme.fromSeed(
      seedColor: AppColores.primario,
      primary: AppColores.primario,
      onPrimary: AppColores.sobrePrimario,
      secondary: AppColores.acento,
      onSecondary: AppColores.primario,
      error: AppColores.error,
      surface: AppColores.superficie,
      onSurface: AppColores.texto,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColores.fondo,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColores.texto,
        displayColor: AppColores.texto,
      ),
    );
  }
}
