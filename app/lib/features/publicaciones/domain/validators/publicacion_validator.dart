import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/borrador_publicacion.dart';
import '../entities/categoria.dart';
import '../entities/foto_articulo.dart';
import '../entities/modalidad.dart';
import '../errors/publicacion_failures.dart';

/// SEGURIDAD: validación de entrada (tipo, longitud, formato y rango).
/// Reglas de negocio de "Publicar artículo" (HU-03).
///
/// Los métodos `validarX` devuelven `null` si el dato es válido o el mensaje
/// del problema. No lanzan excepciones ni tocan la red. La base de datos
/// vuelve a revisar las mismas reglas (la app no es de confianza).
class PublicacionValidator {
  const PublicacionValidator();

  static const String mensajeTitulo = 'Escribe un título de '
      '${AppConstants.tituloLongitudMinima} a ${AppConstants.tituloLongitudMaxima} caracteres.';
  static const String mensajeDescripcion = 'Escribe una descripción de '
      '${AppConstants.descripcionLongitudMinima} a '
      '${AppConstants.descripcionLongitudMaxima} caracteres.';
  static const String mensajeCategoria = 'Elige una categoría.';
  static const String mensajeModalidad = 'Elige una modalidad.';

  /// Texto exacto del issue #4 (HU-03, Escenario 2).
  static const String mensajePrecioVacio = 'Debe especificar un costo para la modalidad Venta';
  static const String mensajePrecioCero = r'El precio debe ser mayor a $0.';
  static const String mensajePrecioFormato =
      'Escribe un precio válido, por ejemplo 150 o 150.50.';
  static const String mensajeSinFotos = 'Agrega al menos una foto.';

  /// Lo más alto que cabe en la columna numeric(10, 2).
  static const double precioMaximo = 99999999.99;

  /// "150", "150.5", "150,50", "1,200" o "1,200.00".
  static final RegExp _precioSimple = RegExp(r'^\d{1,8}([.,]\d{1,2})?$');
  static final RegExp _precioConMiles = RegExp(r'^\d{1,3}(,\d{3}){1,2}(\.\d{1,2})?$');

  String? validarTitulo(String titulo) =>
      _enRango(titulo, AppConstants.tituloLongitudMinima, AppConstants.tituloLongitudMaxima)
          ? null
          : mensajeTitulo;

  String? validarDescripcion(String descripcion) => _enRango(
        descripcion,
        AppConstants.descripcionLongitudMinima,
        AppConstants.descripcionLongitudMaxima,
      )
          ? null
          : mensajeDescripcion;

  String? validarCategoria(Categoria? categoria) => categoria == null ? mensajeCategoria : null;

  String? validarModalidad(Modalidad? modalidad) => modalidad == null ? mensajeModalidad : null;

  /// Solo la Venta lleva precio, y debe ser mayor a $0 (Escenarios 2 y 3).
  /// En Intercambio y Gratis el precio se ignora.
  String? validarPrecio(Modalidad? modalidad, String precioTexto) {
    if (modalidad == null || !modalidad.requierePrecio) return null;
    if (precioTexto.trim().isEmpty) return mensajePrecioVacio;
    final double? precio = leerPrecio(precioTexto);
    if (precio == null) return mensajePrecioFormato;
    if (precio <= 0) return mensajePrecioCero;
    return null;
  }

  /// Convierte el texto del campo en número. Acepta el signo `$`, espacios y
  /// coma decimal. Devuelve `null` si el texto no es un precio.
  double? leerPrecio(String precioTexto) {
    final String limpio = precioTexto.replaceAll(r'$', '').replaceAll(' ', '').trim();
    double? precio;
    if (_precioConMiles.hasMatch(limpio)) {
      precio = double.parse(limpio.replaceAll(',', ''));
    } else if (_precioSimple.hasMatch(limpio)) {
      precio = double.parse(limpio.replaceAll(',', '.'));
    }
    if (precio == null || precio > precioMaximo) return null;
    return precio;
  }

  /// Una foto: solo JPG o PNG y máximo 5 MB (Escenario 4).
  Failure? validarFoto(FotoArticulo foto) {
    if (foto.formato == null) return const FotoFormatoInvalidoFailure();
    if (foto.tamanoBytes > AppConstants.tamanoMaximoImagenBytes) {
      return const FotoArticuloDemasiadoGrandeFailure();
    }
    return null;
  }

  /// La lista completa de fotos: de 1 a 5 y todas válidas.
  String? validarFotos(List<FotoArticulo> fotos) {
    if (fotos.isEmpty) return mensajeSinFotos;
    if (fotos.length > AppConstants.fotosPorPublicacionMaximo) {
      return const DemasiadasFotosFailure().mensaje;
    }
    for (final FotoArticulo foto in fotos) {
      final Failure? error = validarFoto(foto);
      if (error != null) return error.mensaje;
    }
    return null;
  }

  /// Revisa todo el formulario y devuelve los errores por campo. Si el mapa
  /// está vacío, la publicación se puede enviar.
  Map<CampoPublicacion, String> validar(BorradorPublicacion borrador) {
    final Map<CampoPublicacion, String?> resultado = <CampoPublicacion, String?>{
      CampoPublicacion.fotos: validarFotos(borrador.fotos),
      CampoPublicacion.titulo: validarTitulo(borrador.titulo),
      CampoPublicacion.descripcion: validarDescripcion(borrador.descripcion),
      CampoPublicacion.categoria: validarCategoria(borrador.categoria),
      CampoPublicacion.modalidad: validarModalidad(borrador.modalidad),
      CampoPublicacion.precio: validarPrecio(borrador.modalidad, borrador.precioTexto),
    };
    return <CampoPublicacion, String>{
      for (final MapEntry<CampoPublicacion, String?> e in resultado.entries)
        if (e.value != null) e.key: e.value!,
    };
  }

  static bool _enRango(String texto, int minimo, int maximo) {
    final int largo = texto.trim().length;
    return largo >= minimo && largo <= maximo;
  }
}
