import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../perfil/domain/entities/carrera.dart';
import '../../../perfil/domain/entities/division.dart';
import '../../../perfil/domain/entities/perfil.dart';
import '../../../perfil/domain/usecases/obtener_catalogo_academico.dart';
import '../../../perfil/domain/usecases/obtener_perfil.dart';
import '../../../publicaciones/domain/entities/categoria.dart';
import '../../../publicaciones/domain/entities/filtros_feed.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../../../publicaciones/domain/errors/publicacion_failures.dart';
import '../../../publicaciones/domain/usecases/buscar_publicaciones.dart';
import '../../../publicaciones/domain/usecases/obtener_categorias.dart';
import 'feed_state.dart';
import 'opciones_filtro.dart';

/// Maneja el Feed de publicaciones (HU-04) con su búsqueda y filtros
/// (HU-05): primera carga, "jalar para actualizar", cargar más al hacer
/// scroll, buscar al dejar de escribir, elegir categoría, división y
/// carrera, el filtro "Mi carrera" por defecto y limpiar los filtros.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit({
    required BuscarPublicaciones buscarPublicaciones,
    ObtenerCategorias? obtenerCategorias,
    ObtenerCatalogoAcademico? obtenerCatalogo,
    ObtenerPerfil? obtenerPerfil,
    this.espera = const Duration(milliseconds: 400),
  })  : _buscar = buscarPublicaciones,
        _obtenerCategorias = obtenerCategorias,
        _obtenerCatalogo = obtenerCatalogo,
        _obtenerPerfil = obtenerPerfil,
        super(const FeedCargando());

  final BuscarPublicaciones _buscar;
  final ObtenerCategorias? _obtenerCategorias;
  final ObtenerCatalogoAcademico? _obtenerCatalogo;
  final ObtenerPerfil? _obtenerPerfil;

  /// Cuánto se espera después de la última tecla antes de buscar
  /// (HU-05, Escenario 2: no se manda una búsqueda por cada letra).
  final Duration espera;

  Timer? _temporizador;

  /// Número de la carga desde el inicio más reciente. Si llega la respuesta
  /// de una búsqueda o carga anterior, se ignora para no mezclar listas
  /// (HU-04, Escenario 3; HU-05, Escenario 10).
  int _carga = 0;

  /// El filtro "Mi carrera" ya se puso una vez al abrir el Feed.
  bool _filtroInicialPuesto = false;

  /// El estudiante ya cambió algún filtro; entonces "Mi carrera" ya no se
  /// pone solo aunque el perfil llegue tarde.
  bool _filtrosTocados = false;

  // ---------------------------------------------------------------------
  // Cargas del Feed (HU-04)
  // ---------------------------------------------------------------------

  /// Primera carga y botón "Reintentar": muestra el indicador de carga y
  /// conserva los filtros. Si faltan las opciones de los filtros (o el
  /// perfil), las vuelve a pedir; la primera vez que llega el perfil se
  /// pone el filtro "Mi carrera" (HU-05, Escenario 1).
  Future<void> cargar() async {
    _temporizador?.cancel();
    final int carga = ++_carga;
    _emitir(FeedCargando(filtros: state.filtros, opciones: state.opciones));

    if (!state.opciones.completas) {
      final OpcionesFiltro opciones = await _cargarOpciones(state.opciones);
      if (isClosed) return;
      if (carga != _carga) {
        // El estudiante cambió un filtro mientras tanto: esa búsqueda ya
        // está en camino; aquí solo se guardan las opciones.
        _emitir(state.conOpciones(opciones));
        return;
      }
      FiltrosFeed filtros = state.filtros;
      final Carrera? mia = opciones.miCarrera;
      if (mia != null && !_filtroInicialPuesto) {
        _filtroInicialPuesto = true;
        if (!_filtrosTocados) {
          filtros = filtros.conDivisionYCarrera(divisionId: mia.divisionId, carreraId: mia.id);
        }
      }
      _emitir(FeedCargando(filtros: filtros, opciones: opciones));
    }
    await _cargarDesdeElInicio(carga);
  }

  /// "Jalar para actualizar" (HU-04, Escenario 3): vuelve a cargar desde el
  /// inicio con los mismos filtros. Si falla, la lista que ya se veía se
  /// conserva y se muestra el mensaje.
  Future<void> actualizar() => _cargarDesdeElInicio(++_carga);

  Future<void> _cargarDesdeElInicio(int carga) async {
    final FiltrosFeed filtros = state.filtros;
    try {
      final PaginaFeed pagina = await _buscar(filtros: filtros);
      if (carga != _carga) return;
      _emitir(_estadoDe(pagina.publicaciones, pagina.siguiente, filtros));
    } on Failure catch (falla) {
      if (carga != _carga) return;
      _mostrarFalla(falla, filtros);
    } catch (_) {
      if (carga != _carga) return;
      _mostrarFalla(const CargarPublicacionesFailure(), filtros);
    }
  }

  void _mostrarFalla(Failure falla, FiltrosFeed filtros) {
    final FeedState actual = state;
    if (actual is FeedCargado && actual.filtros == filtros) {
      _emitir(actual.copyWith(cargandoMas: false, aviso: () => falla.mensaje));
    } else {
      _emitir(FeedError(falla, filtros: filtros, opciones: actual.opciones));
    }
  }

  /// Siguiente página al llegar al final de la lista (HU-04, Escenario 2),
  /// con los mismos filtros (HU-05, Escenario 5). No hace nada si ya se
  /// está cargando o si ya no hay más.
  Future<void> cargarMas() async {
    final FeedState inicial = state;
    if (inicial is! FeedCargado || inicial.cargandoMas || !inicial.hayMas) return;
    final int carga = _carga;
    _emitir(inicial.copyWith(cargandoMas: true, errorMas: () => null));
    try {
      final PaginaFeed pagina =
          await _buscar(filtros: inicial.filtros, despuesDe: inicial.siguiente);
      final FeedState actual = state;
      if (carga != _carga || actual is! FeedCargado) return;
      // Por si acaso, no se agregan publicaciones que ya están en la lista.
      final Set<String> yaVistas = actual.publicaciones.map((p) => p.id).toSet();
      _emitir(actual.copyWith(
        publicaciones: [
          ...actual.publicaciones,
          ...pagina.publicaciones.where((p) => !yaVistas.contains(p.id)),
        ],
        siguiente: () => pagina.siguiente,
        cargandoMas: false,
      ));
    } catch (error) {
      final FeedState actual = state;
      if (carga != _carga || actual is! FeedCargado) return;
      final Failure falla = error is Failure ? error : const CargarPublicacionesFailure();
      _emitir(actual.copyWith(cargandoMas: false, errorMas: () => falla.mensaje));
    }
  }

  // ---------------------------------------------------------------------
  // Búsqueda y filtros (HU-05)
  // ---------------------------------------------------------------------

  /// Cada vez que cambia el texto del buscador. Busca hasta que el
  /// estudiante deja de escribir durante [espera] (Escenario 2).
  void escribirBusqueda(String texto) {
    _temporizador?.cancel();
    if (state.filtros.conTexto(texto) == state.filtros) return;
    _temporizador = Timer(espera, () => _aplicar(state.filtros.conTexto(texto)));
  }

  /// Botón "buscar" del teclado o la "x" del buscador: busca ya.
  Future<void> buscarAhora(String texto) {
    _temporizador?.cancel();
    return _aplicar(state.filtros.conTexto(texto));
  }

  /// Chip de categoría; `null` es "Todo" (Escenario 4).
  Future<void> elegirCategoria(int? categoriaId) =>
      _aplicar(state.filtros.conCategoria(categoriaId));

  /// Botón "Aplicar" de la hoja de filtros (Escenario 3). `null` en ambos
  /// quita el filtro de división y carrera.
  Future<void> aplicarDivisionYCarrera({int? divisionId, int? carreraId}) => _aplicar(
        state.filtros.conDivisionYCarrera(divisionId: divisionId, carreraId: carreraId),
      );

  /// Chip "Mi carrera": lo pone o lo quita (Escenario 1).
  Future<void> alternarMiCarrera() {
    final Carrera? mia = state.opciones.miCarrera;
    if (mia == null) return Future<void>.value();
    final FiltrosFeed filtros = state.filtros;
    if (miCarreraActiva) {
      return _aplicar(filtros.conDivisionYCarrera());
    }
    return _aplicar(filtros.conDivisionYCarrera(divisionId: mia.divisionId, carreraId: mia.id));
  }

  /// `true` si el filtro de carrera es la carrera del perfil.
  bool get miCarreraActiva {
    final Carrera? mia = state.opciones.miCarrera;
    return mia != null && state.filtros.carreraId == mia.id;
  }

  /// Botón "Limpiar filtros" (Escenario 7): quita el texto, la categoría,
  /// la división y la carrera (incluida "Mi carrera").
  Future<void> limpiarFiltros() {
    _temporizador?.cancel();
    return _aplicar(const FiltrosFeed());
  }

  /// Vuelve a pedir lo que falte de las opciones de los filtros (por
  /// ejemplo, si se abrió la hoja de filtros sin internet).
  Future<void> recargarOpciones() async {
    final OpcionesFiltro opciones = await _cargarOpciones(state.opciones);
    _emitir(state.conOpciones(opciones));
  }

  Future<void> _aplicar(FiltrosFeed nuevos) async {
    if (isClosed) return;
    _filtrosTocados = true;
    if (nuevos == state.filtros) return;
    final int carga = ++_carga;
    _emitir(FeedCargando(filtros: nuevos, opciones: state.opciones));
    await _cargarDesdeElInicio(carga);
  }

  /// Pide lo que falte de las opciones. Si algo falla (por ejemplo, sin
  /// internet) se queda como estaba y el Feed sigue funcionando.
  Future<OpcionesFiltro> _cargarOpciones(OpcionesFiltro actuales) async {
    final ObtenerCategorias? obtenerCategorias = _obtenerCategorias;
    final ObtenerCatalogoAcademico? obtenerCatalogo = _obtenerCatalogo;
    final ObtenerPerfil? obtenerPerfil = _obtenerPerfil;

    final Future<List<Categoria>> categorias =
        actuales.categorias.isNotEmpty || obtenerCategorias == null
            ? Future<List<Categoria>>.value(actuales.categorias)
            : _oSiFalla(() => obtenerCategorias(), actuales.categorias);
    final Future<List<Division>> divisiones =
        actuales.divisiones.isNotEmpty || obtenerCatalogo == null
            ? Future<List<Division>>.value(actuales.divisiones)
            : _oSiFalla(() => obtenerCatalogo(), actuales.divisiones);
    final Future<Perfil?> perfil = actuales.perfilLeido || obtenerPerfil == null
        ? Future<Perfil?>.value()
        : _oSiFalla<Perfil?>(() => obtenerPerfil(), null);

    final List<Categoria> categoriasCargadas = await categorias;
    final List<Division> divisionesCargadas = await divisiones;
    final Perfil? perfilLeido = await perfil;

    return OpcionesFiltro(
      categorias: categoriasCargadas,
      divisiones: divisionesCargadas,
      miCarrera: actuales.miCarrera ?? _carreraDe(perfilLeido, divisionesCargadas),
      perfilLeido: actuales.perfilLeido || perfilLeido != null || obtenerPerfil == null,
    );
  }

  static Future<T> _oSiFalla<T>(Future<T> Function() pedir, T siFalla) async {
    try {
      return await pedir();
    } catch (_) {
      return siFalla;
    }
  }

  /// Carrera del perfil, con su nombre (del perfil o del catálogo).
  static Carrera? _carreraDe(Perfil? perfil, List<Division> divisiones) {
    final int? carreraId = perfil?.carreraId;
    final int? divisionId = perfil?.divisionId;
    if (perfil == null || carreraId == null || divisionId == null) return null;
    String? nombre = perfil.carreraNombre;
    if (nombre == null || nombre.trim().isEmpty) {
      nombre = OpcionesFiltro(divisiones: divisiones).nombreCarrera(carreraId);
    }
    return Carrera(id: carreraId, divisionId: divisionId, nombre: nombre ?? 'Mi carrera');
  }

  // ---------------------------------------------------------------------
  // Sincronizar con el Detalle (HU-04)
  // ---------------------------------------------------------------------

  /// Se llama al ver el detalle de una publicación (HU-04, Escenarios 9 y
  /// 10): si se borró ([actualizada] es `null`) o ya se vendió, se quita de
  /// la lista; si cambió (por ejemplo, a Reservado), se actualiza su
  /// tarjeta.
  void sincronizar(String id, Publicacion? actualizada) {
    final FeedState actual = state;
    if (actual is! FeedCargado) return;
    final List<Publicacion> lista;
    if (actualizada == null || !actualizada.estado.visibleEnFeed) {
      lista = actual.publicaciones.where((p) => p.id != id).toList(growable: false);
    } else {
      final Publicacion nueva = actualizada;
      lista = actual.publicaciones.map((p) => p.id == id ? nueva : p).toList(growable: false);
    }
    if (lista.isEmpty && !actual.hayMas) {
      _emitir(_estadoDe(const [], null, actual.filtros));
    } else {
      _emitir(actual.copyWith(publicaciones: lista));
    }
  }

  /// La pantalla ya mostró el aviso (SnackBar); se limpia para no repetirlo.
  void avisoMostrado() {
    final FeedState actual = state;
    if (actual is FeedCargado && actual.aviso != null) {
      _emitir(actual.copyWith(aviso: () => null));
    }
  }

  /// Lista vacía: "sin resultados" si hay filtros (HU-05, Escenario 6) o
  /// "aún no hay publicaciones" si no (HU-04, Escenario 4).
  FeedState _estadoDe(List<Publicacion> publicaciones, CursorFeed? siguiente, FiltrosFeed filtros) {
    if (publicaciones.isEmpty) {
      return filtros.hayFiltros
          ? FeedSinResultados(filtros: filtros, opciones: state.opciones)
          : FeedVacio(filtros: filtros, opciones: state.opciones);
    }
    return FeedCargado(
      publicaciones: publicaciones,
      siguiente: siguiente,
      filtros: filtros,
      opciones: state.opciones,
    );
  }

  /// Las respuestas pueden llegar cuando la pantalla ya se cerró.
  void _emitir(FeedState nuevo) {
    if (!isClosed) emit(nuevo);
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
