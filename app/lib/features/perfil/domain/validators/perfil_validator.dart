import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/carrera.dart';
import '../entities/division.dart';
import '../entities/foto_perfil.dart';

/// Reglas de negocio del perfil académico (HU-02).
/// Cada método devuelve `null` si el dato es válido, o el [Failure] que
/// describe el problema. No lanza excepciones ni toca la red.
class PerfilValidator {
  const PerfilValidator();

  /// Nombre obligatorio, de 3 a 50 caracteres (sin contar espacios de
  /// sobra al inicio o al final).
  Failure? validarNombre(String nombre) {
    final String limpio = nombre.trim();
    if (limpio.isEmpty) {
      return const NombreInvalidoFailure('Ingresa tu nombre.');
    }
    if (limpio.length < AppConstants.nombreLongitudMinima) {
      return const NombreInvalidoFailure(
        'El nombre debe tener al menos ${AppConstants.nombreLongitudMinima} caracteres.',
      );
    }
    if (limpio.length > AppConstants.nombreLongitudMaxima) {
      return const NombreInvalidoFailure(
        'El nombre no puede tener más de ${AppConstants.nombreLongitudMaxima} caracteres.',
      );
    }
    return null;
  }

  /// División y carrera obligatorias; la carrera debe pertenecer a la
  /// división elegida (HU-02, Escenario 2).
  Failure? validarDivisionYCarrera(Division? division, Carrera? carrera) {
    if (division == null) return const DivisionRequeridaFailure();
    if (carrera == null) return const CarreraRequeridaFailure();
    if (!division.contieneCarrera(carrera)) return const CarreraNoPerteneceFailure();
    return null;
  }

  /// Foto opcional: si viene, solo JPG o PNG y máximo 5 MB
  /// (HU-02, Escenario 3).
  Failure? validarFoto(FotoPerfil? foto) {
    if (foto == null) return null;
    if (foto.formato == null) return const FotoFormatoInvalidoFailure();
    if (foto.tamanoBytes > AppConstants.tamanoMaximoImagenBytes) {
      return const FotoDemasiadoGrandeFailure();
    }
    return null;
  }
}
