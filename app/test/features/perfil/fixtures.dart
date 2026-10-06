import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/constants/app_constants.dart';
import 'package:utrueque/core/network/network_info.dart';
import 'package:utrueque/features/perfil/domain/entities/carrera.dart';
import 'package:utrueque/features/perfil/domain/entities/division.dart';
import 'package:utrueque/features/perfil/domain/entities/foto_perfil.dart';
import 'package:utrueque/features/perfil/domain/entities/perfil.dart';
import 'package:utrueque/features/perfil/domain/repositories/perfil_repository.dart';

/// Datos de prueba compartidos por las pruebas de HU-02.

class MockPerfilRepository extends Mock implements PerfilRepository {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

const Carrera carreraSoftware = Carrera(id: 1, divisionId: 1, nombre: 'Software');
const Carrera carreraRedes = Carrera(id: 2, divisionId: 1, nombre: 'Redes');
const Carrera carreraMecatronica = Carrera(id: 4, divisionId: 2, nombre: 'Mecatrónica');

const Division divisionTI =
    Division(id: 1, nombre: 'TI', carreras: [carreraSoftware, carreraRedes]);
const Division divisionIndustrial =
    Division(id: 2, nombre: 'Industrial', carreras: [carreraMecatronica]);

const List<Division> catalogo = [divisionTI, divisionIndustrial];

const Perfil perfilVacio = Perfil(id: 'u1');

const Perfil perfilCompleto = Perfil(
  id: 'u1',
  nombreMostrar: 'Ana López',
  divisionId: 1,
  divisionNombre: 'TI',
  carreraId: 1,
  carreraNombre: 'Software',
  perfilCompleto: true,
);

/// Crea una "foto" JPG falsa del tamaño indicado (solo importa la firma).
FotoPerfil fotoJpg([int tamano = 1024]) {
  final Uint8List bytes = Uint8List(tamano);
  bytes.setAll(0, [0xFF, 0xD8, 0xFF]);
  return FotoPerfil(bytes: bytes, nombreArchivo: 'foto.jpg');
}

FotoPerfil fotoPng([int tamano = 1024]) {
  final Uint8List bytes = Uint8List(tamano);
  bytes.setAll(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  return FotoPerfil(bytes: bytes, nombreArchivo: 'foto.png');
}

FotoPerfil fotoGif() {
  final Uint8List bytes = Uint8List(1024);
  bytes.setAll(0, [0x47, 0x49, 0x46, 0x38]); // "GIF8"
  return FotoPerfil(bytes: bytes, nombreArchivo: 'foto.jpg');
}

FotoPerfil fotoMayorA5MB() => fotoJpg(AppConstants.tamanoMaximoImagenBytes + 1);
