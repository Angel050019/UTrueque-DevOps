import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../publicaciones/domain/entities/estado_publicacion.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../entities/reputacion.dart';
import '../entities/trato.dart';
import '../errors/reputacion_failures.dart';
import '../repositories/reputacion_repository.dart';
import '../strategies/estrategias_reputacion.dart';
import '../validators/calificacion_validator.dart';

/// Caso de uso: quienes le escribieron al vendedor por su publicación, para
/// la hoja "¿A quién se lo vendiste?" (HU-09, Escenario 1).
class ObtenerCompradoresPosibles {
  ObtenerCompradoresPosibles(this._repository, this._networkInfo);

  final ReputacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<CompradorPosible>> call(String publicacionId) async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.compradoresPosibles(publicacionId);
  }
}

/// Cómo quedó la venta.
class ResultadoVenta {
  const ResultadoVenta({required this.publicacion, this.ventaId});

  /// La publicación, ya Vendida.
  final Publicacion publicacion;

  /// El trato registrado, o `null` si se vendió fuera de UTrueque.
  final String? ventaId;

  bool get hayTrato => ventaId != null;

  String get mensaje =>
      hayTrato ? 'Listo. Ya pueden calificarse.' : 'Tu publicación se marcó como Vendida.';
}

/// Caso de uso: marcar como Vendido eligiendo al comprador (HU-09,
/// Escenarios 1 y 2).
///
/// 1. El patrón State de HU-06 decide si se puede vender (Disponible o
///    Reservada). Si no, lanza `TransicionNoPermitidaFailure` sin tocar la red.
/// 2. Revisa la conexión (Escenario 13).
/// 3. El servidor vuelve a revisar todo: que sea el dueño, el estado y que
///    el comprador le haya escrito por esa publicación.
class MarcarVendida {
  MarcarVendida(this._repository, this._networkInfo);

  final ReputacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<ResultadoVenta> call(Publicacion publicacion, EleccionVenta eleccion) async {
    final EstadoPublicacion vendida = publicacion.estado.aplicar(AccionEstado.marcarVendido);
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    final String? ventaId = await _repository.marcarVendida(
      publicacion.id,
      conversacionId: eleccion.conversacionId,
    );
    return ResultadoVenta(publicacion: _conEstado(publicacion, vendida), ventaId: ventaId);
  }

  static Publicacion _conEstado(Publicacion p, EstadoPublicacion estado) => Publicacion(
        id: p.id,
        usuarioId: p.usuarioId,
        titulo: p.titulo,
        descripcion: p.descripcion,
        categoriaId: p.categoriaId,
        modalidad: p.modalidad,
        estado: estado,
        fotos: p.fotos,
        precio: p.precio,
        creadaEn: p.creadaEn,
        portadaUrl: p.portadaUrl,
        duenoNombre: p.duenoNombre,
        categoriaNombre: p.categoriaNombre,
        fotosUrls: p.fotosUrls,
        duenoFotoUrl: p.duenoFotoUrl,
        duenoDivision: p.duenoDivision,
        duenoCarrera: p.duenoCarrera,
      );
}

/// Caso de uso: los tratos que me faltan por calificar (Escenario 3).
class ObtenerTratosPorCalificar {
  ObtenerTratosPorCalificar(this._repository, this._networkInfo);

  final ReputacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<TratoPorCalificar>> call() async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.tratosPorCalificar();
  }
}

/// Caso de uso: calificar al otro participante de un trato (Escenarios 3,
/// 4, 9, 10, 12 y 13).
///
/// 1. Revisa las estrellas, el comentario y el plazo sin tocar la red.
/// 2. Revisa la conexión.
/// 3. Envía. SEGURIDAD: no se manda a quién se califica; el servidor lo
///    saca de la venta.
class Calificar {
  Calificar(
    this._repository,
    this._networkInfo, {
    DateTime Function()? reloj,
    CalificacionValidator validador = const CalificacionValidator(),
  })  : _reloj = reloj ?? DateTime.now,
        _validador = validador;

  final ReputacionRepository _repository;
  final NetworkInfo _networkInfo;
  final DateTime Function() _reloj;
  final CalificacionValidator _validador;

  Future<void> call(TratoPorCalificar trato, {required int? estrellas, String? comentario}) async {
    final String? errorEstrellas = _validador.validarEstrellas(estrellas);
    if (errorEstrellas != null) throw CalificacionInvalidaFailure(errorEstrellas);
    final String? errorComentario = _validador.validarComentario(comentario ?? '');
    if (errorComentario != null) throw CalificacionInvalidaFailure(errorComentario);
    if (trato.vencidoAl(_reloj())) throw const PlazoVencidoFailure();
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    await _repository.calificar(
      ventaId: trato.ventaId,
      estrellas: estrellas!,
      comentario: _validador.limpiar(comentario),
    );
  }
}

/// Caso de uso: la reputación de un estudiante, ya calculada con el patrón
/// Strategy (Escenarios 5 a 8).
class ObtenerReputacion {
  ObtenerReputacion(
    this._repository,
    this._networkInfo, {
    ElegirEstrategiaReputacion selector = const ElegirEstrategiaReputacion(),
  }) : _selector = selector;

  final ReputacionRepository _repository;
  final NetworkInfo _networkInfo;
  final ElegirEstrategiaReputacion _selector;

  Future<Reputacion> call(String usuarioId) async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return Reputacion.calcular(await _repository.resumen(usuarioId), selector: _selector);
  }
}

/// Caso de uso: las calificaciones que recibí, por páginas (Escenario 5).
class ObtenerCalificacionesRecibidas {
  ObtenerCalificacionesRecibidas(this._repository, this._networkInfo);

  static const int tamanoPagina = 20;

  final ReputacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<PaginaCalificaciones> call({CalificacionRecibida? despuesDe}) async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.recibidas(despuesDe: despuesDe, limite: tamanoPagina);
  }
}
