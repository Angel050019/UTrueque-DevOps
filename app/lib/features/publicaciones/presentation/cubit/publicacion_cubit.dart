import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/borrador_publicacion.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/errors/publicacion_failures.dart';
import '../../domain/usecases/crear_publicacion.dart';
import '../../domain/usecases/obtener_categorias.dart';
import '../../domain/validators/publicacion_validator.dart';
import 'publicacion_state.dart';

/// Orquesta "Publicar artículo" (HU-03). Toda la lógica vive aquí y en los
/// casos de uso: la página solo lee el estado y llama a estos métodos.
class PublicacionCubit extends Cubit<PublicacionState> {
  PublicacionCubit({
    required ObtenerCategorias obtenerCategorias,
    required CrearPublicacion crearPublicacion,
    PublicacionValidator validador = const PublicacionValidator(),
  })  : _obtenerCategorias = obtenerCategorias,
        _crearPublicacion = crearPublicacion,
        _validador = validador,
        super(const PublicacionInicial());

  final ObtenerCategorias _obtenerCategorias;
  final CrearPublicacion _crearPublicacion;
  final PublicacionValidator _validador;

  /// Carga el catálogo de categorías. También sirve para "Reintentar".
  Future<void> cargarCategorias() async {
    final PublicacionDatos anteriores = state.datos ?? const PublicacionDatos();
    emit(const PublicacionCargando());
    try {
      final List<Categoria> categorias = await _obtenerCategorias();
      emit(PublicacionEditando(anteriores.copyWith(categorias: categorias)));
    } on Failure catch (falla) {
      emit(PublicacionError(falla));
    } catch (_) {
      emit(const PublicacionError(ServidorFailure()));
    }
  }

  void seleccionarCategoria(Categoria? categoria) {
    final PublicacionDatos? actuales = _editables;
    if (actuales == null) return;
    emit(PublicacionEditando(
      actuales.copyWith(categoria: () => categoria).sinErrores([CampoPublicacion.categoria]),
    ));
  }

  /// Cambia la modalidad. Fuera de Venta el precio no aplica, así que su
  /// error (si lo había) desaparece.
  void seleccionarModalidad(Modalidad modalidad) {
    final PublicacionDatos? actuales = _editables;
    if (actuales == null) return;
    emit(PublicacionEditando(actuales.copyWith(modalidad: () => modalidad).sinErrores([
      CampoPublicacion.modalidad,
      if (!modalidad.requierePrecio) CampoPublicacion.precio,
    ])));
  }

  /// Agrega fotos validándolas en cuanto se eligen (JPG/PNG, máx. 5 MB y
  /// máximo 5 en total). Las válidas se agregan; si alguna no lo es, se
  /// avisa con [PublicacionError] y el resto del formulario se conserva
  /// (HU-03, Escenario 4).
  void agregarFotos(List<FotoArticulo> nuevas) {
    final PublicacionDatos? actuales = _editables;
    if (actuales == null || nuevas.isEmpty) return;

    final List<FotoArticulo> fotos = List<FotoArticulo>.of(actuales.fotos);
    Failure? primerError;
    for (final FotoArticulo foto in nuevas) {
      if (fotos.length >= AppConstants.fotosPorPublicacionMaximo) {
        primerError ??= const DemasiadasFotosFailure();
        break;
      }
      final Failure? error = _validador.validarFoto(foto);
      if (error != null) {
        primerError ??= error;
        continue;
      }
      fotos.add(foto);
    }

    PublicacionDatos siguientes = actuales.copyWith(fotos: List.unmodifiable(fotos));
    if (fotos.length > actuales.fotos.length) {
      siguientes = siguientes.sinErrores([CampoPublicacion.fotos]);
    }
    emit(primerError == null
        ? PublicacionEditando(siguientes)
        : PublicacionError(primerError, datos: siguientes));
  }

  void quitarFoto(int indice) {
    final PublicacionDatos? actuales = _editables;
    if (actuales == null || indice < 0 || indice >= actuales.fotos.length) return;
    final List<FotoArticulo> fotos = List<FotoArticulo>.of(actuales.fotos)..removeAt(indice);
    emit(PublicacionEditando(actuales.copyWith(fotos: List.unmodifiable(fotos))));
  }

  /// La página lo llama cuando el estudiante escribe en un campo, para
  /// quitar el rojo de ese campo.
  void campoEditado(CampoPublicacion campo) {
    final PublicacionDatos? actuales = _editables;
    if (actuales == null || !actuales.errores.containsKey(campo)) return;
    emit(PublicacionEditando(actuales.sinErrores([campo])));
  }

  /// Valida y publica. Con datos inválidos NO se envía nada: se marcan en
  /// rojo los campos con problema (Escenarios 2, 3 y 5).
  Future<void> publicar({
    required String titulo,
    required String descripcion,
    String precioTexto = '',
  }) async {
    final PublicacionDatos? actuales = state.datos;
    if (actuales == null || state is PublicacionEnviando || state is PublicacionPublicada) return;

    final PublicacionDatos limpios = actuales.copyWith(errores: const {});
    emit(PublicacionEnviando(limpios));
    try {
      final Publicacion publicacion = await _crearPublicacion(BorradorPublicacion(
        titulo: titulo,
        descripcion: descripcion,
        categoria: actuales.categoria,
        modalidad: actuales.modalidad,
        precioTexto: precioTexto,
        fotos: actuales.fotos,
      ));
      emit(PublicacionPublicada(limpios, publicacion));
    } on PublicacionInvalidaFailure catch (falla) {
      emit(PublicacionError(falla, datos: limpios.copyWith(errores: falla.errores)));
    } on Failure catch (falla) {
      emit(PublicacionError(falla, datos: limpios));
    } catch (_) {
      emit(PublicacionError(const ServidorFailure(), datos: limpios));
    }
  }

  /// Vuelve al formulario normal después de mostrar un error, conservando
  /// los campos marcados en rojo.
  void descartarError() {
    final PublicacionDatos? actuales = state.datos;
    if (state is PublicacionError && actuales != null) {
      emit(PublicacionEditando(actuales));
    }
  }

  /// Datos solo si el formulario se puede modificar (no mientras se envía).
  PublicacionDatos? get _editables {
    if (state is PublicacionEnviando || state is PublicacionPublicada) return null;
    return state.datos;
  }
}
