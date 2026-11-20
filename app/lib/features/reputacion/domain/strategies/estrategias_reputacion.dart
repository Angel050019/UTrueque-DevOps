import '../entities/resumen_reputacion.dart';

/// HU-09 · **Patrón Strategy**: formas de calcular la reputación que se
/// muestra a partir del [ResumenReputacion].
///
/// Todas cumplen el mismo contrato [promedio]. Quien muestra la reputación
/// no sabe cuál se usó: se la pide a [ElegirEstrategiaReputacion]. Para
/// cambiar la regla (decisión 8 de la planeación) basta con cambiar la
/// estrategia o el umbral aquí, sin tocar pantallas ni la base de datos.
abstract class EstrategiaReputacion {
  const EstrategiaReputacion();

  /// El promedio de 1 a 5, o `null` si no hay calificaciones (Escenario 7).
  double? promedio(ResumenReputacion resumen);

  /// ¿Es un promedio ajustado (no el real)?
  bool get esAjustada;
}

/// Suma de estrellas entre el total. Ejemplo: 5 y 4 → 4.5.
class PromedioSimple extends EstrategiaReputacion {
  const PromedioSimple();

  @override
  double? promedio(ResumenReputacion resumen) {
    if (resumen.sinCalificaciones) return null;
    return resumen.sumaEstrellas / resumen.total;
  }

  @override
  bool get esAjustada => false;
}

/// Promedio ajustado (Escenario 8): antes de promediar se suman
/// [imaginarias] calificaciones de [valorImaginario] estrellas. Así una sola
/// calificación de 5 no pone a nadie arriba de quien tiene muchas.
///
/// Con los valores por omisión: una sola de 5 → (5 + 3 × 4) ÷ 4 = 4.25.
class PromedioAjustado extends EstrategiaReputacion {
  const PromedioAjustado({this.imaginarias = 3, this.valorImaginario = 4});

  final int imaginarias;
  final double valorImaginario;

  @override
  double? promedio(ResumenReputacion resumen) {
    if (resumen.sinCalificaciones) return null;
    return (resumen.sumaEstrellas + imaginarias * valorImaginario) / (resumen.total + imaginarias);
  }

  @override
  bool get esAjustada => true;
}

/// Elige la estrategia según cuántas calificaciones hay: con menos de
/// [minimoParaReal] usa la ajustada; con más, la simple (el promedio real).
class ElegirEstrategiaReputacion {
  const ElegirEstrategiaReputacion({
    this.minimoParaReal = 5,
    this.simple = const PromedioSimple(),
    this.ajustada = const PromedioAjustado(),
  });

  final int minimoParaReal;
  final EstrategiaReputacion simple;
  final EstrategiaReputacion ajustada;

  EstrategiaReputacion para(ResumenReputacion resumen) =>
      resumen.total < minimoParaReal ? ajustada : simple;
}
