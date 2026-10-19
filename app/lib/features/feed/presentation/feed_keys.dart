import 'package:flutter/widgets.dart';

/// Keys de los widgets importantes del Feed (HU-04) y de su búsqueda y
/// filtros (HU-05). Las pruebas buscan los widgets por estas Keys, así el
/// diseño puede cambiar sin romper pruebas. Si rediseñas, CONSERVA las Keys.
///
/// Las Keys de cada tarjeta siguen en `PublicacionKeys.tarjeta(id)`.
class FeedKeys {
  FeedKeys._();

  static const Key publicarBoton = Key('feed_publicar_boton');
  static const Key miPerfilBoton = Key('feed_mi_perfil_boton');

  // HU-05: búsqueda y filtros
  /// Campo de texto del buscador.
  static const Key buscador = Key('feed_buscador');

  /// La "x" que borra el texto del buscador.
  static const Key borrarBusquedaBoton = Key('feed_borrar_busqueda_boton');

  /// Chip de cada categoría por su nombre (`filtro('Todo')`,
  /// `filtro('Calculadoras')`…).
  static Key filtro(String texto) => Key('feed_filtro_$texto');

  /// Chip "Mi carrera" (filtro por defecto con la carrera del perfil).
  static const Key miCarreraChip = Key('feed_mi_carrera_chip');

  /// Botón que abre la hoja de filtros de división y carrera.
  static const Key filtrosBoton = Key('feed_filtros_boton');

  /// Chip con la división o carrera elegida en la hoja (con su "x").
  static const Key filtroAcademicoChip = Key('feed_filtro_academico_chip');

  /// "Limpiar filtros" junto al título de la lista.
  static const Key limpiarFiltrosBoton = Key('feed_limpiar_filtros_boton');

  /// Hoja de filtros: selectores, "Aplicar" y "Quitar".
  static const Key hojaFiltros = Key('feed_hoja_filtros');
  static const Key divisionFiltro = Key('feed_division_filtro');
  static const Key carreraFiltro = Key('feed_carrera_filtro');
  static const Key aplicarFiltrosBoton = Key('feed_aplicar_filtros_boton');
  static const Key quitarFiltrosAcademicosBoton = Key('feed_quitar_filtros_academicos_boton');
  static const Key reintentarOpcionesBoton = Key('feed_reintentar_opciones_boton');

  /// Pantalla "sin resultados" y su botón "Limpiar filtros".
  static const Key sinResultados = Key('feed_sin_resultados');
  static const Key limpiarFiltrosSinResultadosBoton = Key('feed_limpiar_filtros_sin_resultados');

  // HU-04: lista y sus estados
  static const Key lista = Key('feed_publicaciones_lista');
  static const Key vacio = Key('feed_publicaciones_vacio');
  static const Key cargando = Key('feed_publicaciones_cargando');
  static const Key error = Key('feed_publicaciones_error');
  static const Key reintentarBoton = Key('feed_publicaciones_reintentar');

  /// Final de la lista: spinner de "cargando más", mensaje de "ya viste
  /// todas" o error al cargar más con su botón para reintentar.
  static const Key cargandoMas = Key('feed_cargando_mas');
  static const Key finDeLista = Key('feed_fin_de_lista');
  static const Key errorMas = Key('feed_error_mas');
  static const Key reintentarMasBoton = Key('feed_reintentar_mas_boton');
}
