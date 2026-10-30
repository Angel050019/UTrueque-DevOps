import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/constants/app_constants.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/publicaciones/domain/entities/borrador_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/categoria.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/foto_articulo.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
import 'package:utrueque/features/publicaciones/domain/entities/pagina_feed.dart';
import 'package:utrueque/features/publicaciones/domain/entities/publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/repositories/publicacion_repository.dart';

/// Datos de prueba compartidos por las pruebas de HU-03.

class MockPublicacionRepository extends Mock implements PublicacionRepository {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

const String idAlumno = '7f1c2a9e-0000-4000-8000-000000000001';

const Categoria categoriaLibros = Categoria(id: 1, nombre: 'Libros y apuntes');
const Categoria categoriaCalculadoras = Categoria(id: 2, nombre: 'Calculadoras');
const List<Categoria> categorias = [categoriaLibros, categoriaCalculadoras];

const String tituloValido = 'Calculadora Casio fx-991';
const String descripcionValida = 'Calculadora científica en buen estado, con funda.';

/// "Foto" JPG falsa del tamaño indicado (solo importa la firma).
FotoArticulo fotoJpg([int tamano = 1024, String nombre = 'foto.jpg']) {
  final Uint8List bytes = Uint8List(tamano);
  bytes.setAll(0, [0xFF, 0xD8, 0xFF]);
  return FotoArticulo(bytes: bytes, nombreArchivo: nombre);
}

FotoArticulo fotoPng([int tamano = 1024]) {
  final Uint8List bytes = Uint8List(tamano);
  bytes.setAll(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  return FotoArticulo(bytes: bytes, nombreArchivo: 'foto.png');
}

/// Un GIF renombrado como .jpg: la app debe rechazarlo por su firma.
FotoArticulo fotoGif() {
  final Uint8List bytes = Uint8List(1024);
  bytes.setAll(0, [0x47, 0x49, 0x46, 0x38]);
  return FotoArticulo(bytes: bytes, nombreArchivo: 'foto.jpg');
}

FotoArticulo fotoMayorA5MB() => fotoJpg(AppConstants.tamanoMaximoImagenBytes + 1);

/// Borrador válido de Intercambio (Escenario 1). Se puede ajustar con los
/// parámetros para armar los demás escenarios.
BorradorPublicacion borrador({
  String titulo = tituloValido,
  String descripcion = descripcionValida,
  Categoria? categoria = categoriaCalculadoras,
  Modalidad? modalidad = Modalidad.intercambio,
  String precioTexto = '',
  List<FotoArticulo>? fotos,
}) {
  return BorradorPublicacion(
    titulo: titulo,
    descripcion: descripcion,
    categoria: categoria,
    modalidad: modalidad,
    precioTexto: precioTexto,
    fotos: fotos ?? [fotoJpg()],
  );
}

const String rutaFoto1 = '$idAlumno/1_0.jpg';
const String rutaFoto2 = '$idAlumno/1_1.jpg';

Publicacion publicacionGuardada({
  Modalidad modalidad = Modalidad.intercambio,
  double? precio,
  List<String> fotos = const [rutaFoto1],
}) {
  return Publicacion(
    id: 'pub-1',
    usuarioId: idAlumno,
    titulo: tituloValido,
    descripcion: descripcionValida,
    categoriaId: categoriaCalculadoras.id,
    modalidad: modalidad,
    precio: precio,
    estado: EstadoPublicacion.inicial,
    fotos: fotos,
  );
}

// ---------------------------------------------------------------------------
// HU-04: Feed de publicaciones
// ---------------------------------------------------------------------------

const String idOtroAlumno = '7f1c2a9e-0000-4000-8000-000000000002';

/// Publicación como llega al Feed y al Detalle (de otro alumno, con dueño,
/// categoría y URLs de las fotos).
Publicacion publicacionDelFeed(
  String id, {
  EstadoPublicacion estado = const Disponible(),
  String usuarioId = idOtroAlumno,
}) {
  return Publicacion(
    id: id,
    usuarioId: usuarioId,
    titulo: tituloValido,
    descripcion: descripcionValida,
    categoriaId: categoriaCalculadoras.id,
    categoriaNombre: categoriaCalculadoras.nombre,
    modalidad: Modalidad.venta,
    precio: 350,
    estado: estado,
    fotos: const ['$idOtroAlumno/1.jpg', '$idOtroAlumno/2.jpg'],
    fotosUrls: const ['https://fotos/1.jpg', 'https://fotos/2.jpg'],
    portadaUrl: 'https://fotos/1.jpg',
    creadaEn: DateTime.utc(2026, 10, 13, 18),
    duenoNombre: 'Luis Pérez',
    duenoDivision: 'Mecatrónica, Desarrollo de Software e Ingeniería Civil',
    duenoCarrera: 'Ingeniería en Desarrollo y Gestión de Software',
  );
}

/// Cursor de la última publicación de una página.
CursorFeed cursorDe(String id) => CursorFeed(fecha: '2026-10-13T18:00:00.123456+00:00', id: id);

/// Página del Feed con las publicaciones de esos [ids]; con [hayMas] trae
/// el cursor de la última.
PaginaFeed paginaFeed(List<String> ids, {bool hayMas = false}) {
  return PaginaFeed(
    publicaciones: ids.map(publicacionDelFeed).toList(),
    siguiente: hayMas ? cursorDe(ids.last) : null,
  );
}

// ---------------------------------------------------------------------------
// HU-06: Gestión de "Mis publicaciones"
// ---------------------------------------------------------------------------

/// Publicación del alumno con sesión ([idAlumno]), como llega a "Mis
/// publicaciones" y al Detalle, con dos fotos guardadas.
Publicacion miPublicacion(
  String id, {
  EstadoPublicacion estado = const Disponible(),
  String titulo = tituloValido,
}) {
  return Publicacion(
    id: id,
    usuarioId: idAlumno,
    titulo: titulo,
    descripcion: descripcionValida,
    categoriaId: categoriaCalculadoras.id,
    categoriaNombre: categoriaCalculadoras.nombre,
    modalidad: Modalidad.venta,
    precio: 350,
    estado: estado,
    fotos: const [rutaFoto1, rutaFoto2],
    fotosUrls: const ['https://fotos/1.jpg', 'https://fotos/2.jpg'],
    portadaUrl: 'https://fotos/1.jpg',
    creadaEn: DateTime.utc(2026, 10, 29, 18),
    duenoNombre: 'Ana López',
  );
}

/// Página de "Mis publicaciones" con esos [ids]; con [hayMas] trae el
/// cursor de la última.
PaginaFeed paginaMias(
  List<String> ids, {
  bool hayMas = false,
  EstadoPublicacion estado = const Disponible(),
}) {
  return PaginaFeed(
    publicaciones: ids.map((id) => miPublicacion(id, estado: estado)).toList(),
    siguiente: hayMas ? cursorDe(ids.last) : null,
  );
}
