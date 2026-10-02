import 'package:flutter/material.dart';

/// Paleta de UTrueque. ÚNICO lugar donde se definen colores: si el diseño
/// cambia, se cambia aquí y toda la app se actualiza.
///
/// TODO(diseño): Oziel define aquí la paleta final (por ahora se conserva
/// el índigo que ya usaba la app en el Sprint 1).
class AppColores {
  AppColores._();

  static const Color primario = Color(0xFF3F51B5);
  static const Color error = Color(0xFFB3261E);
}

/// Tema base de la aplicación (Material 3).
class AppTheme {
  AppTheme._();

  static ThemeData get claro => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColores.primario,
        // TODO(diseño): tipografía, forma de botones, campos, tarjetas, etc.
      );
}
