import 'package:equatable/equatable.dart';

import '../strategies/estrategias_reputacion.dart';
import 'resumen_reputacion.dart';

/// La reputación lista para mostrarse (HU-09, Escenarios 5 a 8).
class Reputacion extends Equatable {
  const Reputacion({required this.resumen, required this.promedio, this.ajustada = false});

  /// Calcula la reputación con la estrategia que elija [selector] (patrón
  /// Strategy).
  factory Reputacion.calcular(
    ResumenReputacion resumen, {
    ElegirEstrategiaReputacion selector = const ElegirEstrategiaReputacion(),
  }) {
    final EstrategiaReputacion estrategia = selector.para(resumen);
    final double? promedio = estrategia.promedio(resumen);
    return Reputacion(resumen: resumen, promedio: promedio, ajustada: promedio != null && estrategia.esAjustada);
  }

  static const String textoSinCalificaciones = 'Nuevo en UTrueque · Sin calificaciones aún';

  final ResumenReputacion resumen;

  /// De 1 a 5, o `null` si no tiene calificaciones.
  final double? promedio;

  /// ¿El [promedio] es el ajustado (pocas calificaciones)?
  final bool ajustada;

  int get total => resumen.total;

  bool get sinCalificaciones => promedio == null;

  /// El promedio con una decimal ("4.3"), o `null` sin calificaciones.
  String? get promedioTexto {
    final double? p = promedio;
    if (p == null) return null;
    return ((p * 10).round() / 10).toStringAsFixed(1);
  }

  /// "1 calificación" o "12 calificaciones".
  String get totalTexto => total == 1 ? '1 calificación' : '$total calificaciones';

  /// "4.3 · 2 calificaciones" o el texto de sin calificaciones (Escenario 7).
  String get texto => sinCalificaciones ? textoSinCalificaciones : '$promedioTexto · $totalTexto';

  /// Estrellas llenas para dibujar (el promedio redondeado, de 0 a 5).
  int get estrellasLlenas {
    final double? p = promedio;
    if (p == null) return 0;
    final int redondeado = p.round();
    if (redondeado < 0) return 0;
    return redondeado > 5 ? 5 : redondeado;
  }

  @override
  List<Object?> get props => [resumen, promedio, ajustada];
}
