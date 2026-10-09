import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/constants/app_constants.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/publicaciones/domain/entities/borrador_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/categoria.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/entities/foto_articulo.dart';
import 'package:utrueque/features/publicaciones/domain/entities/modalidad.dart';
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
