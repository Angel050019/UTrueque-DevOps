import 'package:equatable/equatable.dart';

import '../errors/publicacion_failures.dart';

/// Ciclo de vida de una publicación con el **patrón State**.
///
/// Cada estado es una clase que decide qué cambios acepta:
///
///   Disponible ──reservar──▶ Reservado ──marcarVendido──▶ Vendido
///       ▲                        │
///       └────────liberar─────────┘
///   Disponible ──marcarVendido──▶ Vendido
///
/// Vendido es el estado final. Si se pide un cambio no permitido, el
/// estado lanza [TransicionNoPermitidaFailure] en lugar de usar `if`
/// repartidos por la app. La base de datos aplica las mismas reglas.
abstract class EstadoPublicacion extends Equatable {
  const EstadoPublicacion();

  /// Toda publicación nace en Disponible (regla de HU-03).
  static const EstadoPublicacion inicial = Disponible();

  /// Texto que se guarda en la columna `estado`.
  String get valor;

  /// Texto para mostrar al usuario.
  String get etiqueta;

  /// ¿Otro estudiante puede pedir este artículo?
  /// HU-04: decide si el botón "Contactar al vendedor" está habilitado.
  bool get aceptaSolicitudes => false;

  /// HU-04: aviso que muestra el Detalle en este estado (`null` si no hay).
  String? get aviso => null;

  /// HU-04: ¿se muestra en el Feed? Las Vendidas ya no.
  bool get visibleEnFeed => true;

  EstadoPublicacion reservar() => _noPermitido('Reservado');

  EstadoPublicacion liberar() => _noPermitido('Disponible');

  EstadoPublicacion marcarVendido() => _noPermitido('Vendido');

  EstadoPublicacion _noPermitido(String hacia) =>
      throw TransicionNoPermitidaFailure(etiqueta, hacia);

  /// Convierte el texto de la base de datos en el estado.
  static EstadoPublicacion desdeValor(String valor) {
    switch (valor) {
      case 'disponible':
        return const Disponible();
      case 'reservado':
        return const Reservado();
      case 'vendido':
        return const Vendido();
      default:
        throw ArgumentError.value(valor, 'valor', 'Estado desconocido');
    }
  }

  @override
  List<Object?> get props => [valor];
}

class Disponible extends EstadoPublicacion {
  const Disponible();

  @override
  String get valor => 'disponible';

  @override
  String get etiqueta => 'Disponible';

  @override
  bool get aceptaSolicitudes => true;

  @override
  EstadoPublicacion reservar() => const Reservado();

  @override
  EstadoPublicacion marcarVendido() => const Vendido();
}

class Reservado extends EstadoPublicacion {
  const Reservado();

  @override
  String get valor => 'reservado';

  @override
  String get etiqueta => 'Reservado';

  @override
  String get aviso => 'Este artículo está reservado: el dueño ya está en trato.';

  @override
  EstadoPublicacion liberar() => const Disponible();

  @override
  EstadoPublicacion marcarVendido() => const Vendido();
}

class Vendido extends EstadoPublicacion {
  const Vendido();

  @override
  String get valor => 'vendido';

  @override
  String get etiqueta => 'Vendido';

  @override
  String get aviso => 'Este artículo ya fue vendido.';

  @override
  bool get visibleEnFeed => false;
}
