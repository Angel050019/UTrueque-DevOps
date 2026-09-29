import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/carrera.dart';
import '../../domain/entities/division.dart';
import '../../domain/entities/foto_perfil.dart';
import '../../domain/entities/perfil.dart';

/// Datos que las pantallas de perfil necesitan dibujar: el perfil guardado,
/// el catálogo y lo que el usuario va eligiendo en el formulario.
class PerfilDatos extends Equatable {
  const PerfilDatos({
    required this.perfil,
    this.catalogo = const [],
    this.divisionSeleccionada,
    this.carreraSeleccionada,
    this.fotoNueva,
  });

  /// Perfil tal como está guardado en Supabase.
  final Perfil perfil;

  /// Divisiones con sus carreras (vacío en "Mi perfil", que solo muestra).
  final List<Division> catalogo;

  final Division? divisionSeleccionada;
  final Carrera? carreraSeleccionada;

  /// Foto elegida pero todavía no subida (se sube al presionar Guardar).
  final FotoPerfil? fotoNueva;

  /// Carreras que se pueden elegir según la división seleccionada.
  List<Carrera> get carrerasDisponibles => divisionSeleccionada?.carreras ?? const [];

  PerfilDatos copyWith({
    Perfil? perfil,
    List<Division>? catalogo,
    Division? Function()? divisionSeleccionada,
    Carrera? Function()? carreraSeleccionada,
    FotoPerfil? Function()? fotoNueva,
  }) {
    return PerfilDatos(
      perfil: perfil ?? this.perfil,
      catalogo: catalogo ?? this.catalogo,
      divisionSeleccionada:
          divisionSeleccionada != null ? divisionSeleccionada() : this.divisionSeleccionada,
      carreraSeleccionada:
          carreraSeleccionada != null ? carreraSeleccionada() : this.carreraSeleccionada,
      fotoNueva: fotoNueva != null ? fotoNueva() : this.fotoNueva,
    );
  }

  @override
  List<Object?> get props =>
      [perfil, catalogo, divisionSeleccionada, carreraSeleccionada, fotoNueva];
}

/// Estados del perfil (patrón State). Las pantallas solo leen estos estados.
///
/// Flujo típico:
///   PerfilInicial → PerfilCargando → PerfilCargado
///   → (Guardar) PerfilGuardando → PerfilGuardado | PerfilError
abstract class PerfilState extends Equatable {
  const PerfilState();

  /// Datos disponibles en este estado (null en Inicial/Cargando y en un
  /// error de carga). Útil para seguir dibujando el formulario.
  PerfilDatos? get datos => null;

  @override
  List<Object?> get props => [datos];
}

class PerfilInicial extends PerfilState {
  const PerfilInicial();
}

/// Se está leyendo el perfil y/o el catálogo.
class PerfilCargando extends PerfilState {
  const PerfilCargando();
}

/// Perfil (y catálogo) listos para mostrarse o editarse.
class PerfilCargado extends PerfilState {
  const PerfilCargado(this.datos);

  @override
  final PerfilDatos datos;
}

/// Se está subiendo la foto y/o guardando el perfil.
class PerfilGuardando extends PerfilState {
  const PerfilGuardando(this.datos);

  @override
  final PerfilDatos datos;
}

/// El perfil se guardó. `datos.perfil` ya trae lo guardado en Supabase.
class PerfilGuardado extends PerfilState {
  const PerfilGuardado(this.datos);

  @override
  final PerfilDatos datos;
}

/// Algo falló. [failure.mensaje] trae el texto en español para mostrar.
/// Si [datos] no es null, el formulario puede seguir en pantalla.
class PerfilError extends PerfilState {
  const PerfilError(this.failure, {this.datos});

  final Failure failure;

  @override
  final PerfilDatos? datos;

  String get mensaje => failure.mensaje;

  @override
  List<Object?> get props => [failure, datos];
}
