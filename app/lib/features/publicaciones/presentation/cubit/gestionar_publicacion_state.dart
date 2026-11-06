import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/estado_publicacion.dart';
import '../../domain/entities/publicacion.dart';

/// Operaciones de la hoja "Gestionar publicación" (HU-06).
/// Las tres primeras son cambios de estado del patrón State; "borrar"
/// quita la publicación y sus fotos.
enum OperacionGestion {
  reservar(AccionEstado.reservar, 'Tu publicación ahora está Reservada.'),
  liberar(AccionEstado.liberar, 'Tu publicación está Disponible otra vez.'),
  marcarVendido(AccionEstado.marcarVendido, 'Tu publicación se marcó como Vendida.'),
  borrar(null, 'Publicación borrada.');

  const OperacionGestion(this.accionEstado, this.mensajeExito);

  /// Cambio de estado que pide (`null` en "borrar").
  final AccionEstado? accionEstado;

  /// Mensaje que se muestra cuando sale bien.
  final String mensajeExito;

  /// Texto del botón.
  String get etiqueta => accionEstado?.etiqueta ?? 'Borrar publicación';

  /// Vender es final y borrar no se puede deshacer: se pide confirmar
  /// (Escenarios 5 y 8).
  bool get requiereConfirmacion => this == marcarVendido || this == borrar;

  String get tituloConfirmacion =>
      this == borrar ? '¿Borrar publicación?' : '¿Marcar como Vendido?';

  String get textoConfirmacion => this == borrar
      ? 'Se borrará la publicación y sus fotos. No se puede deshacer.'
      : 'Ya no podrás cambiar su estado ni editarla.';

  String get botonConfirmacion => this == borrar ? 'Sí, borrar' : 'Sí, marcar como Vendido';

  /// Operaciones que permite el [estado] (patrón State): sus acciones y,
  /// si es Disponible, borrar.
  static List<OperacionGestion> de(EstadoPublicacion estado) => <OperacionGestion>[
        for (final AccionEstado accion in estado.acciones)
          OperacionGestion.values.firstWhere((o) => o.accionEstado == accion),
        if (estado.sePuedeBorrar) OperacionGestion.borrar,
      ];
}

/// Estados de la hoja "Gestionar publicación" (HU-06).
///
/// Flujo típico:
///   Lista → (Vender o Borrar) Confirmando → Enviando → Terminada | Error
///   Lista → (Reservar o Liberar) Enviando → Terminada | Error
abstract class GestionState extends Equatable {
  const GestionState(this.publicacion);

  /// Publicación que se está gestionando, con su estado actual.
  final Publicacion publicacion;

  /// Lo que se puede hacer ahora (Escenario 9: solo lo que permite su estado).
  List<OperacionGestion> get operaciones => OperacionGestion.de(publicacion.estado);

  bool get sePuedeEditar => publicacion.estado.sePuedeEditar;

  @override
  List<Object?> get props => [publicacion];
}

/// Lista de acciones lista para elegir.
class GestionLista extends GestionState {
  const GestionLista(super.publicacion);
}

/// Esperando que el estudiante confirme Vender o Borrar.
class GestionConfirmando extends GestionState {
  const GestionConfirmando(super.publicacion, this.operacion);

  final OperacionGestion operacion;

  @override
  List<Object?> get props => [publicacion, operacion];
}

/// Se está enviando la operación al servidor.
class GestionEnviando extends GestionState {
  const GestionEnviando(super.publicacion, this.operacion);

  final OperacionGestion operacion;

  @override
  List<Object?> get props => [publicacion, operacion];
}

/// La operación salió bien. [actualizada] es cómo quedó la publicación,
/// o `null` si se borró.
class GestionTerminada extends GestionState {
  const GestionTerminada(super.publicacion, this.operacion, {this.actualizada});

  final OperacionGestion operacion;
  final Publicacion? actualizada;

  String get mensaje => operacion.mensajeExito;

  @override
  List<Object?> get props => [publicacion, operacion, actualizada];
}

/// La operación falló. [publicacion] puede venir recargada si el servidor
/// avisó que su estado cambió (Escenario 9).
class GestionError extends GestionState {
  const GestionError(super.publicacion, this.failure);

  final Failure failure;

  String get mensaje => failure.mensaje;

  @override
  List<Object?> get props => [publicacion, failure];
}
