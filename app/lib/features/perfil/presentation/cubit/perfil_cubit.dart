import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/carrera.dart';
import '../../domain/entities/division.dart';
import '../../domain/entities/foto_perfil.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/usecases/actualizar_perfil.dart';
import '../../domain/usecases/obtener_catalogo_academico.dart';
import '../../domain/usecases/obtener_perfil.dart';
import '../../domain/validators/perfil_validator.dart';
import 'perfil_state.dart';

/// Orquesta el perfil académico (HU-02) para la capa de presentación.
/// Toda la lógica vive aquí y en los casos de uso: las páginas solo leen
/// el estado y llaman a estos métodos.
class PerfilCubit extends Cubit<PerfilState> {
  PerfilCubit({
    required ObtenerPerfil obtenerPerfil,
    required ObtenerCatalogoAcademico obtenerCatalogo,
    required ActualizarPerfil actualizarPerfil,
    PerfilValidator validador = const PerfilValidator(),
  })  : _obtenerPerfil = obtenerPerfil,
        _obtenerCatalogo = obtenerCatalogo,
        _actualizarPerfil = actualizarPerfil,
        _validador = validador,
        super(const PerfilInicial());

  final ObtenerPerfil _obtenerPerfil;
  final ObtenerCatalogoAcademico _obtenerCatalogo;
  final ActualizarPerfil _actualizarPerfil;
  final PerfilValidator _validador;

  /// Carga el perfil propio. Con [conCatalogo] también trae divisiones y
  /// carreras y preselecciona las que el usuario ya tenía (para Completar
  /// y Editar). "Mi perfil" lo llama con `conCatalogo: false`.
  Future<void> cargarMiPerfil({bool conCatalogo = true}) async {
    emit(const PerfilCargando());
    try {
      final Perfil perfil = await _obtenerPerfil();
      final List<Division> catalogo = conCatalogo ? await _obtenerCatalogo() : const [];
      final Division? division = _buscarDivision(catalogo, perfil.divisionId);
      final Carrera? carrera = _buscarCarrera(division, perfil.carreraId);
      emit(PerfilCargado(PerfilDatos(
        perfil: perfil,
        catalogo: catalogo,
        divisionSeleccionada: division,
        carreraSeleccionada: carrera,
      )));
    } on Failure catch (falla) {
      emit(PerfilError(falla));
    } catch (_) {
      emit(const PerfilError(ServidorFailure()));
    }
  }

  /// Carga el perfil público de otro estudiante (publicaciones, chat).
  Future<void> cargarPerfilDe(String id) async {
    emit(const PerfilCargando());
    try {
      final Perfil perfil = await _obtenerPerfil(id: id);
      emit(PerfilCargado(PerfilDatos(perfil: perfil)));
    } on Failure catch (falla) {
      emit(PerfilError(falla));
    } catch (_) {
      emit(const PerfilError(ServidorFailure()));
    }
  }

  /// Cambia la división. Si la carrera elegida no pertenece a la nueva
  /// división, se limpia para obligar a elegir otra.
  void seleccionarDivision(Division? division) {
    final PerfilDatos? actuales = state.datos;
    if (actuales == null) return;
    final Carrera? carrera = actuales.carreraSeleccionada;
    final bool conservarCarrera =
        division != null && carrera != null && division.contieneCarrera(carrera);
    emit(PerfilCargado(actuales.copyWith(
      divisionSeleccionada: () => division,
      carreraSeleccionada: () => conservarCarrera ? carrera : null,
    )));
  }

  void seleccionarCarrera(Carrera? carrera) {
    final PerfilDatos? actuales = state.datos;
    if (actuales == null) return;
    emit(PerfilCargado(actuales.copyWith(carreraSeleccionada: () => carrera)));
  }

  /// Valida la foto en cuanto se elige (JPG/PNG, máx. 5 MB). Si no es
  /// válida, emite [PerfilError] con el formulario intacto y NO la guarda.
  void seleccionarFoto(FotoPerfil foto) {
    final PerfilDatos? actuales = state.datos;
    if (actuales == null) return;
    final Failure? error = _validador.validarFoto(foto);
    if (error != null) {
      emit(PerfilError(error, datos: actuales.copyWith(fotoNueva: () => null)));
      return;
    }
    emit(PerfilCargado(actuales.copyWith(fotoNueva: () => foto)));
  }

  void quitarFotoNueva() {
    final PerfilDatos? actuales = state.datos;
    if (actuales == null) return;
    emit(PerfilCargado(actuales.copyWith(fotoNueva: () => null)));
  }

  /// Guarda el perfil (Completar o Editar). Usa la división, carrera y foto
  /// elegidas en el estado y el [nombre] escrito en el campo de texto.
  Future<void> guardar({required String nombre}) async {
    final PerfilDatos? actuales = state.datos;
    if (actuales == null || state is PerfilGuardando) return;
    emit(PerfilGuardando(actuales));
    try {
      final Perfil guardado = await _actualizarPerfil(
        nombre: nombre,
        division: actuales.divisionSeleccionada,
        carrera: actuales.carreraSeleccionada,
        fotoNueva: actuales.fotoNueva,
      );
      emit(PerfilGuardado(actuales.copyWith(perfil: guardado, fotoNueva: () => null)));
    } on Failure catch (falla) {
      emit(PerfilError(falla, datos: actuales));
    } catch (_) {
      emit(PerfilError(const ServidorFailure(), datos: actuales));
    }
  }

  /// Vuelve al estado normal del formulario después de mostrar un error.
  /// (Si el error fue al cargar, usa `cargarMiPerfil()` para reintentar.)
  void descartarError() {
    final PerfilDatos? actuales = state.datos;
    if (state is PerfilError && actuales != null) {
      emit(PerfilCargado(actuales));
    }
  }

  static Division? _buscarDivision(List<Division> catalogo, int? id) {
    if (id == null) return null;
    for (final Division division in catalogo) {
      if (division.id == id) return division;
    }
    return null;
  }

  static Carrera? _buscarCarrera(Division? division, int? id) {
    if (division == null || id == null) return null;
    for (final Carrera carrera in division.carreras) {
      if (carrera.id == id) return carrera;
    }
    return null;
  }
}
